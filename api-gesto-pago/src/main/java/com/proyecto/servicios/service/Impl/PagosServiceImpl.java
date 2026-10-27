package com.proyecto.servicios.service.Impl;

import com.proyecto.servicios.client.GestoPagoTxClient;
import com.proyecto.servicios.entity.gestopago.GestoPagoToken;
import com.proyecto.servicios.entity.pago.EstadoTransaccion;
import com.proyecto.servicios.entity.pago.EventoTransaccion;
import com.proyecto.servicios.entity.pago.Transaccion;
import com.proyecto.servicios.exception.ApiException;
import com.proyecto.servicios.model.CatalogoProductoCache;
import com.proyecto.servicios.model.gestopago.Firma;
import com.proyecto.servicios.model.gestopago.GestoPagoMensajeOperacion;
import com.proyecto.servicios.model.gestopago.GestoPagoOperacionResponse;
import com.proyecto.servicios.model.idempotencia.ClaveIdempotencia;
import com.proyecto.servicios.model.pago.PagarServicioRequestDto;
import com.proyecto.servicios.model.pago.PagarServicioResponseDto;
import com.proyecto.servicios.model.pago.PagoPendienteDto;
import com.proyecto.servicios.model.pago.PagoRequestDto;
import com.proyecto.servicios.model.pago.TransaccionDto;
import com.proyecto.servicios.model.pago.VerificarReferenciaRequest;
import com.proyecto.servicios.model.pago.VerificarReferenciaResponse;
import com.proyecto.servicios.repositorys.pago.EventoTransaccionRepository;
import com.proyecto.servicios.repositorys.pago.TransaccionRepository;
import com.proyecto.servicios.service.BloqueoIdempotencia;
import com.proyecto.servicios.service.CatalogoConsulta;
import com.proyecto.servicios.service.FirmaService;
import com.proyecto.servicios.service.GestoPagoTokenService;
import com.proyecto.servicios.service.HistorialPagosCache;
import com.proyecto.servicios.service.PagosService;
import javax.xml.parsers.DocumentBuilderFactory;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.io.StringReader;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

@Service
@Slf4j
public class PagosServiceImpl implements PagosService {

    private static final String CODIGO_EXITO = "01";
    private static final String CODIGO_DUPLICADO = "06";
    private static final String CODIGO_TIMEOUT = "82";
    private static final String NO_AUTORIZACION = "-1";
    private static final String ORIGEN_PROVEEDOR = "PROVEEDOR";
    private static final DateTimeFormatter HORA_LOCAL =
            DateTimeFormatter.ofPattern("yyyyMMddHHmmss").withZone(ZoneId.systemDefault());
    private static final DateTimeFormatter ZONA_HORARIA =
            DateTimeFormatter.ofPattern("dd/MMM/yyyy HH:mm:ss", Locale.ENGLISH);

    private final GestoPagoTokenService gestoPagoTokenService;
    private final GestoPagoTxClient gestoPagoTxClient;
    private final TransaccionRepository transaccionRepository;
    private final EventoTransaccionRepository eventoTransaccionRepository;
    private final CatalogoConsulta catalogoConsulta;
    private final BloqueoIdempotencia bloqueoIdempotencia;
    private final HistorialPagosCache historialPagosCache;
    private final FirmaService firmaService;
    private final Integer idDistribuidor;
    private final String codigoDispositivo;
    private final String unidad;
    private final Duration esperaConfirmacion;

    public PagosServiceImpl(GestoPagoTokenService gestoPagoTokenService,
                            GestoPagoTxClient gestoPagoTxClient,
                            TransaccionRepository transaccionRepository,
                            EventoTransaccionRepository eventoTransaccionRepository,
                            CatalogoConsulta catalogoConsulta,
                            BloqueoIdempotencia bloqueoIdempotencia,
                            HistorialPagosCache historialPagosCache,
                            Integer idDistribuidor,
                            String codigoDispositivo,
                            String unidad,
                            long esperaConfirmacionSegundos) {
        this(gestoPagoTokenService, gestoPagoTxClient, transaccionRepository,
                eventoTransaccionRepository, catalogoConsulta, bloqueoIdempotencia,
                historialPagosCache, new FirmaServiceImpl("gestopago-secret"),
                idDistribuidor, codigoDispositivo, unidad, esperaConfirmacionSegundos);
    }

    @Autowired
    public PagosServiceImpl(GestoPagoTokenService gestoPagoTokenService,
                            GestoPagoTxClient gestoPagoTxClient,
                            TransaccionRepository transaccionRepository,
                            EventoTransaccionRepository eventoTransaccionRepository,
                            CatalogoConsulta catalogoConsulta,
                            BloqueoIdempotencia bloqueoIdempotencia,
                            HistorialPagosCache historialPagosCache,
                            FirmaService firmaService,
                            @Value("${gestopago.auth.id-distribuidor}") Integer idDistribuidor,
                            @Value("${gestopago.auth.codigo-dispositivo}") String codigoDispositivo,
                            @Value("${gestopago.unidad:083}") String unidad,
                            @Value("${gestopago.confirm-wait-seconds:62}") long esperaConfirmacionSegundos) {
        this.gestoPagoTokenService = gestoPagoTokenService;
        this.gestoPagoTxClient = gestoPagoTxClient;
        this.transaccionRepository = transaccionRepository;
        this.eventoTransaccionRepository = eventoTransaccionRepository;
        this.catalogoConsulta = catalogoConsulta;
        this.bloqueoIdempotencia = bloqueoIdempotencia;
        this.historialPagosCache = historialPagosCache;
        this.firmaService = firmaService;
        this.idDistribuidor = idDistribuidor;
        this.codigoDispositivo = codigoDispositivo;
        this.unidad = unidad;
        this.esperaConfirmacion = Duration.ofSeconds(esperaConfirmacionSegundos);
    }

    @Override
    public VerificarReferenciaResponse verificarReferencia(VerificarReferenciaRequest request) {
        CatalogoProductoCache producto = productoOExcepcion(request.getIdServicio(), request.getIdProducto());
        if (producto.getTipoFront() == null || producto.getTipoFront() != 4) {
            throw ApiException.referenciaNoVerificable();
        }

        GestoPagoOperacionResponse respuesta = operar(() -> gestoPagoTxClient.verifyReference(token(), Map.of(
                "idProducto", request.getIdProducto().toString(),
                "idServicio", request.getIdServicio().toString(),
                "referencia", request.getReferencia())));
        GestoPagoMensajeOperacion mensaje = respuesta.getMensaje();
        String codigo = mensaje == null ? null : mensaje.getCodigo();
        if (CODIGO_EXITO.equals(codigo)) {
            return VerificarReferenciaResponse.valida(mensaje.getSaldo(), mensaje.getTexto());
        }
        return VerificarReferenciaResponse.invalida(
                mensaje == null ? "La referencia no es valida" : mensaje.getTexto());
    }

    @Override
    @Transactional
    public TransaccionDto crearTransaccion(Long usuarioId, PagoRequestDto request) {
        if (request.getReferencia() == null || request.getReferencia().isBlank()) {
            throw ApiException.referenciaInvalida();
        }
        CatalogoProductoCache producto = productoOExcepcion(request.getIdServicio(), request.getIdProducto());
        BigDecimal monto = montoAutorizado(producto, request.getMonto());

        ClaveIdempotencia clave = new ClaveIdempotencia(usuarioId, request.getIdempotencyKey());
        bloqueoIdempotencia.adquirir(clave);

        Optional<Transaccion> existente = transaccionRepository
                .findByUsuarioIdAndIdempotencyKey(usuarioId, request.getIdempotencyKey());
        if (existente.isPresent()
                && existente.get().getEstado() != EstadoTransaccion.FALLIDA
                && existente.get().getEstado() != EstadoTransaccion.RECHAZADA) {
            return TransaccionDto.from(existente.get());
        }

        Transaccion transaccion = prepararTransaccion(existente.orElse(null), usuarioId, producto,
                request.getReferencia(), monto, request.getIdempotencyKey());
        registrarEvento(transaccion.getId(), EstadoTransaccion.PENDIENTE, "API",
                "Transaccion registrada para envio al proveedor");

        String horaLocal = HORA_LOCAL.format(Instant.now());
        Map<String, String> body = cuerpoSendTxConHora(producto, request.getReferencia(), null,
                monto, transaccion.getUpc(), horaLocal);
        Firma firma = construirFirma(producto, body, request.getReferencia(), monto, transaccion.getUpc(), horaLocal);
        firmaService.encriptar(firma);

        try {
            String bearerToken = token();
            GestoPagoOperacionResponse respuesta = operar(() -> gestoPagoTxClient.sendTx(bearerToken, body));
            aplicarResultadoSendTx(transaccion, respuesta);
        } catch (Exception e) {
            log.warn("sendTx no concluyo para transaccion id={}, quedara en proceso", transaccion.getId(), e);
            cambiarEstado(transaccion, EstadoTransaccion.EN_PROCESO, "API",
                    "El proveedor no respondio; el resultado se confirmara despues");
        }
        return TransaccionDto.from(transaccion);
    }

    @Override
    @Transactional
    public PagarServicioResponseDto pagarServicio(Long usuarioId, PagarServicioRequestDto request) {
        String referencia = request.referenciaEfectiva();
        if (referencia == null || referencia.isBlank()) {
            throw ApiException.referenciaInvalida();
        }

        CatalogoProductoCache producto = productoOExcepcion(request.getIdServicio(), request.getIdProducto());
        BigDecimal monto = montoAutorizado(producto, request.getMontoPago());

        boolean tieneUpcExplicito = request.getUpc() != null && !request.getUpc().isBlank();
        String claveBase = tieneUpcExplicito
                ? request.getUpc().trim()
                : UUID.randomUUID().toString();
        String idempotencyKey = claveBase.length() <= 36 ? claveBase : claveBase.substring(0, 36);
        String upcGenerado = upc(claveBase);
        String horaLocal = (request.getHoraLocal() != null && !request.getHoraLocal().isBlank())
                ? request.getHoraLocal().trim()
                : HORA_LOCAL.format(Instant.now());

        Map<String, String> body = cuerpoSendTxConHora(
                producto, referencia, request.getTelefono(), monto, upcGenerado, horaLocal);

        // Paso 1: Firmar (crear instancia de Firma y encriptarla)
        Firma firmaObj = construirFirma(producto, body, referencia, monto, upcGenerado, horaLocal);
        String firmaEncriptada = firmaService.encriptar(firmaObj);
        log.info("Paso 1 [Firmar]: Firma encriptada generada para upc={}", upcGenerado);

        // Control de concurrencia y prevencion de cargos duplicados
        bloqueoIdempotencia.adquirir(new ClaveIdempotencia(usuarioId != null ? usuarioId : 0L, idempotencyKey));

        Optional<Transaccion> previa = Optional.empty();
        if (usuarioId != null) {
            previa = transaccionRepository.findByUsuarioIdAndIdempotencyKey(usuarioId, idempotencyKey);
        } else if (tieneUpcExplicito) {
            previa = transaccionRepository.findFirstByUpcOrderByCreatedAtDesc(upcGenerado);
        }

        if (previa.isPresent()
                && previa.get().getEstado() != EstadoTransaccion.FALLIDA
                && previa.get().getEstado() != EstadoTransaccion.RECHAZADA) {
            Transaccion existente = previa.get();
            return PagarServicioResponseDto.builder()
                    .idTransaccion(existente.getId())
                    .idServicio(existente.getIdServicio())
                    .idProducto(existente.getIdProducto())
                    .telefono(body.get("telefono"))
                    .referencia(existente.getReferencia())
                    .horaLocal(horaLocal)
                    .montoPago(existente.getMonto().toPlainString())
                    .upc(existente.getUpc())
                    .firma(firmaEncriptada)
                    .estado(existente.getEstado().name())
                    .codigoMensaje(existente.getEstado() == EstadoTransaccion.APROBADA ? CODIGO_EXITO : CODIGO_TIMEOUT)
                    .mensaje(existente.getErrorMensaje() != null
                            ? existente.getErrorMensaje()
                            : "Operacion previamente registrada (idempotente)")
                    .idTx(existente.getIdTx())
                    .numAutorizacion(existente.getNumeroAutorizacion())
                    .comision(existente.getComision() != null ? existente.getComision().toPlainString() : null)
                    .pin(existente.getPin())
                    .legend(existente.getLegend())
                    .build();
        }

        Transaccion transaccion = null;
        if (usuarioId != null) {
            transaccion = prepararTransaccion(previa.orElse(null), usuarioId, producto,
                    referencia, monto, idempotencyKey);
            transaccion.setUpc(upcGenerado);
            transaccionRepository.save(transaccion);
            registrarEvento(transaccion.getId(), EstadoTransaccion.PENDIENTE, "API",
                    "Transaccion firmada y registrada para envio al proveedor");
        }

        // Paso 2: Obtener Token y Paso 3: Enviar sendTx
        EstadoTransaccion estadoFinal = EstadoTransaccion.PENDIENTE;
        GestoPagoOperacionResponse respuesta = null;
        String codigoMensaje = null;
        String textoMensaje = null;

        try {
            String bearerToken = token();
            log.info("Paso 2 [Obtener Token]: Token activo obtenido para distribuidor={}", idDistribuidor);

            log.info("Paso 3 [Enviar sendTx]: Enviando sendTx para idServicio={}, idProducto={}, upc={}",
                    producto.getIdServicio(), producto.getIdProducto(), upcGenerado);
            respuesta = operar(() -> gestoPagoTxClient.sendTx(bearerToken, body));

            if (transaccion != null) {
                aplicarResultadoSendTx(transaccion, respuesta);
                estadoFinal = transaccion.getEstado();
            } else {
                estadoFinal = determinarEstadoSendTx(respuesta);
            }
            GestoPagoMensajeOperacion msg = respuesta.getMensaje();
            codigoMensaje = msg == null ? null : msg.getCodigo();
            textoMensaje = msg == null ? null : msg.getTexto();
        } catch (Exception e) {
            log.warn("sendTx no concluyo para upc={}, quedara en proceso", upcGenerado, e);
            estadoFinal = EstadoTransaccion.EN_PROCESO;
            textoMensaje = "El proveedor no respondio; el resultado se confirmara despues";
            if (transaccion != null) {
                cambiarEstado(transaccion, EstadoTransaccion.EN_PROCESO, "API", textoMensaje);
            }
        }

        GestoPagoMensajeOperacion msg = respuesta == null ? null : respuesta.getMensaje();
        return PagarServicioResponseDto.builder()
                .idTransaccion(transaccion == null ? null : transaccion.getId())
                .idServicio(producto.getIdServicio())
                .idProducto(producto.getIdProducto())
                .telefono(body.get("telefono"))
                .referencia(referencia)
                .horaLocal(horaLocal)
                .montoPago(monto.toPlainString())
                .upc(upcGenerado)
                .firma(firmaEncriptada)
                .estado(estadoFinal.name())
                .codigoMensaje(codigoMensaje)
                .mensaje(textoMensaje)
                .idTx(respuesta == null ? null : primeroNoVacio(respuesta.getIdTx(), msg == null ? null : msg.getIdTx()))
                .numAutorizacion(respuesta == null ? null : respuesta.getNumAutorizacion())
                .saldo(respuesta == null ? null : primeroNoVacio(respuesta.getSaldo(), msg == null ? null : msg.getSaldo()))
                .comision(respuesta == null ? null : respuesta.getComision())
                .pin(msg == null ? null : msg.getPin())
                .legend(msg == null ? null : msg.getLegend())
                .fecha(respuesta == null ? null : respuesta.getFecha())
                .build();
    }

    @Override
    @Transactional
    public PagarServicioResponseDto confirmarServicio(Long usuarioId, PagarServicioRequestDto request) {
        String referencia = request.referenciaEfectiva();
        if (referencia == null || referencia.isBlank()) {
            throw ApiException.referenciaInvalida();
        }
        if (request.getUpc() == null || request.getUpc().isBlank()) {
            throw new ApiException("PAGO-005", "El upc es obligatorio para conciliar la transaccion",
                    HttpStatus.UNPROCESSABLE_ENTITY);
        }

        CatalogoProductoCache producto = productoOExcepcion(request.getIdServicio(), request.getIdProducto());
        BigDecimal monto = montoAutorizado(producto, request.getMontoPago());
        String upcConciliacion = upc(request.getUpc().trim());
        String horaLocal = (request.getHoraLocal() != null && !request.getHoraLocal().isBlank())
                ? request.getHoraLocal().trim()
                : HORA_LOCAL.format(Instant.now());

        Optional<Transaccion> existente = transaccionRepository.findFirstByUpcOrderByCreatedAtDesc(upcConciliacion);
        if (existente.isPresent() && esEstadoFinal(existente.get().getEstado())) {
            Transaccion tx = existente.get();
            return PagarServicioResponseDto.builder()
                    .idTransaccion(tx.getId())
                    .idServicio(tx.getIdServicio())
                    .idProducto(tx.getIdProducto())
                    .referencia(tx.getReferencia())
                    .horaLocal(horaLocal)
                    .montoPago(tx.getMonto().toPlainString())
                    .upc(tx.getUpc())
                    .estado(tx.getEstado().name())
                    .mensaje(tx.getErrorMensaje() != null ? tx.getErrorMensaje() : "Transaccion ya conciliada")
                    .idTx(tx.getIdTx())
                    .numAutorizacion(tx.getNumeroAutorizacion())
                    .build();
        }

        Map<String, String> body = cuerpoSendTxConHora(
                producto, referencia, request.getTelefono(), monto, upcConciliacion, horaLocal);

        EstadoTransaccion estadoFinal = EstadoTransaccion.EN_PROCESO;
        GestoPagoOperacionResponse respuesta = null;
        String codigoMensaje = null;
        String textoMensaje = null;

        try {
            respuesta = operar(() -> gestoPagoTxClient.confirmTx(token(), body));
            if (existente.isPresent()) {
                aplicarResultadoConfirmTx(existente.get(), respuesta);
                estadoFinal = existente.get().getEstado();
            } else {
                GestoPagoMensajeOperacion msg = respuesta.getMensaje();
                String codigo = msg == null ? null : msg.getCodigo();
                if (CODIGO_EXITO.equals(codigo) || CODIGO_DUPLICADO.equals(codigo)) {
                    estadoFinal = EstadoTransaccion.APROBADA;
                } else if (CODIGO_TIMEOUT.equals(codigo)) {
                    estadoFinal = EstadoTransaccion.EN_PROCESO;
                } else {
                    estadoFinal = EstadoTransaccion.FALLIDA;
                }
            }
            GestoPagoMensajeOperacion msg = respuesta.getMensaje();
            codigoMensaje = msg == null ? null : msg.getCodigo();
            textoMensaje = msg == null ? null : msg.getTexto();
        } catch (Exception e) {
            log.warn("confirmTx no concluyo para upc={}, se mantiene en proceso", upcConciliacion, e);
            textoMensaje = "No fue posible confirmar con el proveedor; la operacion continua en proceso";
        }

        GestoPagoMensajeOperacion msg = respuesta == null ? null : respuesta.getMensaje();
        return PagarServicioResponseDto.builder()
                .idTransaccion(existente.map(Transaccion::getId).orElse(null))
                .idServicio(producto.getIdServicio())
                .idProducto(producto.getIdProducto())
                .telefono(body.get("telefono"))
                .referencia(referencia)
                .horaLocal(horaLocal)
                .montoPago(monto.toPlainString())
                .upc(upcConciliacion)
                .estado(estadoFinal.name())
                .codigoMensaje(codigoMensaje)
                .mensaje(textoMensaje)
                .idTx(respuesta == null ? null : primeroNoVacio(respuesta.getIdTx(), msg == null ? null : msg.getIdTx()))
                .numAutorizacion(respuesta == null ? null : respuesta.getNumAutorizacion())
                .saldo(respuesta == null ? null : primeroNoVacio(respuesta.getSaldo(), msg == null ? null : msg.getSaldo()))
                .comision(respuesta == null ? null : respuesta.getComision())
                .pin(msg == null ? null : msg.getPin())
                .legend(msg == null ? null : msg.getLegend())
                .fecha(respuesta == null ? null : respuesta.getFecha())
                .build();
    }

    @Override
    @Transactional
    public TransaccionDto confirmarTransaccion(Long usuarioId, Long id) {
        Transaccion transaccion = transaccionRepository.findByIdAndUsuarioId(id, usuarioId)
                .orElseThrow(() -> new ApiException("PAGO-005", "Transaccion no encontrada", HttpStatus.NOT_FOUND));
        if (esEstadoFinal(transaccion.getEstado())) {
            return TransaccionDto.from(transaccion);
        }

        Instant creada = transaccion.getCreatedAt();
        if (creada != null && Duration.between(creada, Instant.now()).compareTo(esperaConfirmacion) < 0) {
            return TransaccionDto.from(transaccion);
        }

        CatalogoProductoCache producto = productoOExcepcion(transaccion.getIdServicio(), transaccion.getIdProducto());
        try {
            GestoPagoOperacionResponse respuesta = operar(() -> gestoPagoTxClient.confirmTx(
                    token(), cuerpoSendTx(producto, transaccion.getReferencia(),
                            transaccion.getMonto(), transaccion.getUpc())));
            aplicarResultadoConfirmTx(transaccion, respuesta);
        } catch (Exception e) {
            log.warn("confirmTx no concluyo para transaccion id={}, se mantiene en proceso", transaccion.getId(), e);
        }
        return TransaccionDto.from(transaccion);
    }

    @Override
    public List<TransaccionDto> historial(Long usuarioId) {
        Optional<List<TransaccionDto>> cacheado = leerCache(usuarioId);
        if (cacheado.isPresent()) {
            return cacheado.get();
        }
        List<TransaccionDto> desdeBd = transaccionRepository.findByUsuarioIdOrderByCreatedAtDesc(usuarioId)
                .stream()
                .map(TransaccionDto::from)
                .toList();
        try {
            historialPagosCache.guardar(usuarioId, desdeBd);
        } catch (Exception e) {
            log.warn("No se pudo llenar el historial cacheado de usuario {}: {}", usuarioId, e.getMessage());
        }
        return desdeBd;
    }

    @Override
    public List<PagoPendienteDto> pendientes(Long usuarioId) {
        List<EstadoTransaccion> estados = List.of(
                EstadoTransaccion.PENDIENTE,
                EstadoTransaccion.EN_PROCESO,
                EstadoTransaccion.FALLIDA
        );
        List<PagoPendienteDto> pendientes = transaccionRepository
                .findByUsuarioIdAndEstadoInOrderByCreatedAtDesc(usuarioId, estados)
                .stream()
                .map(PagoPendienteDto::from)
                .toList();
        log.info("Pagos pendientes consultados para usuario {}: {} encontrados", usuarioId, pendientes.size());
        return pendientes;
    }

    private Optional<List<TransaccionDto>> leerCache(Long usuarioId) {
        try {
            return historialPagosCache.obtener(usuarioId);
        } catch (Exception e) {
            log.warn("No se pudo leer el historial cacheado de usuario {}, se ira a Postgres: {}",
                    usuarioId, e.getMessage());
            return Optional.empty();
        }
    }

    private CatalogoProductoCache productoOExcepcion(Integer idServicio, Integer idProducto) {
        if (idServicio == null || idServicio <= 0 || idProducto == null || idProducto <= 0) {
            throw ApiException.productoNoDisponible();
        }
        return catalogoConsulta.buscarActivo(idServicio, idProducto)
                .orElseThrow(ApiException::productoNoDisponible);
    }

    private EstadoTransaccion determinarEstadoSendTx(GestoPagoOperacionResponse respuesta) {
        GestoPagoMensajeOperacion mensaje = respuesta.getMensaje();
        String codigo = mensaje == null ? null : mensaje.getCodigo();
        if (CODIGO_EXITO.equals(codigo) || esDuplicadoAplicado(respuesta)) {
            return EstadoTransaccion.APROBADA;
        }
        if (CODIGO_TIMEOUT.equals(codigo)) {
            return EstadoTransaccion.EN_PROCESO;
        }
        return EstadoTransaccion.FALLIDA;
    }

    private BigDecimal montoAutorizado(CatalogoProductoCache producto, BigDecimal solicitado) {
        if (producto.getTipoFront() != null && producto.getTipoFront() == 1) {
            BigDecimal precioCatalogo = producto.getPrecio();
            if (precioCatalogo == null || precioCatalogo.compareTo(BigDecimal.ZERO) <= 0) {
                throw ApiException.montoInvalido();
            }
            if (solicitado != null && solicitado.compareTo(precioCatalogo) != 0) {
                throw ApiException.montoInvalido();
            }
            return precioCatalogo.setScale(2, RoundingMode.UNNECESSARY);
        }
        if (solicitado == null || solicitado.compareTo(BigDecimal.ZERO) <= 0
                || solicitado.scale() > 2) {
            throw ApiException.montoInvalido();
        }
        if (producto.getPrecio() != null && producto.getPrecio().compareTo(BigDecimal.ZERO) > 0
                && solicitado.compareTo(producto.getPrecio()) != 0) {
            throw ApiException.montoInvalido();
        }
        return solicitado.setScale(2, RoundingMode.UNNECESSARY);
    }

    private Transaccion prepararTransaccion(Transaccion previa, Long usuarioId, CatalogoProductoCache producto,
                                            String referencia, BigDecimal monto, String idempotencyKey) {
        Transaccion transaccion = previa != null ? previa : new Transaccion();
        if (transaccion.getId() == null) {
            transaccion.setUsuarioId(usuarioId);
            transaccion.setIdServicio(producto.getIdServicio());
            transaccion.setIdProducto(producto.getIdProducto());
            transaccion.setServicio(producto.getServicio());
            transaccion.setProducto(producto.getProducto());
            transaccion.setIdempotencyKey(idempotencyKey);
            transaccion.setUpc(upc(idempotencyKey));
            transaccion.setUnidad(unidad);
            transaccion.setComision(BigDecimal.ZERO);
        }
        transaccion.setReferencia(referencia);
        transaccion.setMonto(monto);
        transaccion.setEstado(EstadoTransaccion.PENDIENTE);
        transaccion.setErrorMensaje(null);
        return transaccionRepository.save(transaccion);
    }

    private void aplicarResultadoSendTx(Transaccion transaccion, GestoPagoOperacionResponse respuesta) {
        GestoPagoMensajeOperacion mensaje = respuesta.getMensaje();
        String codigo = mensaje == null ? null : mensaje.getCodigo();
        String texto = mensaje == null ? "El proveedor rechazo la operacion" : mensaje.getTexto();
        if (CODIGO_EXITO.equals(codigo) || esDuplicadoAplicado(respuesta)) {
            aplicarDatosExito(transaccion, respuesta);
            cambiarEstado(transaccion, EstadoTransaccion.APROBADA, ORIGEN_PROVEEDOR,
                    mensaje == null ? "Operacion realizada con exito" : texto);
            return;
        }
        if (CODIGO_TIMEOUT.equals(codigo)) {
            transaccion.setErrorMensaje(texto);
            cambiarEstado(transaccion, EstadoTransaccion.EN_PROCESO, ORIGEN_PROVEEDOR,
                    "Resultado incierto; se confirmara contra el proveedor despues");
            return;
        }
        transaccion.setErrorMensaje(texto);
        cambiarEstado(transaccion, EstadoTransaccion.FALLIDA, ORIGEN_PROVEEDOR, texto);
    }

    private void aplicarResultadoConfirmTx(Transaccion transaccion, GestoPagoOperacionResponse respuesta) {
        GestoPagoMensajeOperacion mensaje = respuesta.getMensaje();
        String codigo = mensaje == null ? null : mensaje.getCodigo();
        String texto = mensaje == null ? "Sin mensaje del proveedor" : mensaje.getTexto();
        if (CODIGO_EXITO.equals(codigo) || CODIGO_DUPLICADO.equals(codigo)) {
            aplicarDatosExito(transaccion, respuesta);
            cambiarEstado(transaccion, EstadoTransaccion.APROBADA, ORIGEN_PROVEEDOR, texto);
            return;
        }
        if (CODIGO_TIMEOUT.equals(codigo)) {
            transaccion.setErrorMensaje(texto);
            cambiarEstado(transaccion, EstadoTransaccion.EN_PROCESO, ORIGEN_PROVEEDOR,
                    "Timeout al confirmar; se mantiene en proceso para reintento posterior");
            return;
        }
        transaccion.setErrorMensaje(texto);
        cambiarEstado(transaccion, EstadoTransaccion.FALLIDA, ORIGEN_PROVEEDOR, texto);
    }

    private boolean esDuplicadoAplicado(GestoPagoOperacionResponse respuesta) {
        GestoPagoMensajeOperacion mensaje = respuesta.getMensaje();
        if (!CODIGO_DUPLICADO.equals(mensaje == null ? null : mensaje.getCodigo())) {
            return false;
        }
        return respuesta.getNumAutorizacion() != null
                && !respuesta.getNumAutorizacion().isBlank()
                && !NO_AUTORIZACION.equals(respuesta.getNumAutorizacion().trim());
    }

    private void aplicarDatosExito(Transaccion transaccion, GestoPagoOperacionResponse respuesta) {
        GestoPagoMensajeOperacion mensaje = respuesta.getMensaje();
        transaccion.setNumeroAutorizacion(respuesta.getNumAutorizacion());
        transaccion.setIdTx(primeroNoVacio(respuesta.getIdTx(), mensaje == null ? null : mensaje.getIdTx()));
        transaccion.setPin(mensaje == null ? null : mensaje.getPin());
        transaccion.setLegend(mensaje == null ? null : mensaje.getLegend());
        BigDecimal monto = decimal(respuesta.getMonto());
        if (monto != null) {
            transaccion.setMonto(monto);
        }
        BigDecimal comision = decimal(respuesta.getComision());
        if (comision != null) {
            transaccion.setComision(comision);
        }
        transaccion.setFecha(fecha(respuesta.getFecha()));
    }

    private Map<String, String> cuerpoSendTx(CatalogoProductoCache producto, String referencia,
                                             BigDecimal monto, String upc) {
        return cuerpoSendTxConHora(producto, referencia, null, monto, upc, HORA_LOCAL.format(Instant.now()));
    }

    private Map<String, String> cuerpoSendTxConHora(CatalogoProductoCache producto, String referencia,
                                                    String telefonoExplicito, BigDecimal monto,
                                                    String upc, String horaLocal) {
        boolean pagoServicio = producto.getTipoFront() != null && producto.getTipoFront() == 2;
        String tel = (telefonoExplicito != null && !telefonoExplicito.isBlank())
                ? telefonoExplicito.trim()
                : telefono(producto, referencia, pagoServicio);
        Map<String, String> body = new HashMap<>();
        body.put("idProducto", String.valueOf(producto.getIdProducto()));
        body.put("idServicio", String.valueOf(producto.getIdServicio()));
        body.put("telefono", tel);
        body.put("horaLocal", horaLocal);
        body.put("upc", upc);
        body.put("unidad", unidad);
        if (pagoServicio) {
            body.put("referencia", referencia);
            body.put("montoPago", monto.toPlainString());
        }
        return body;
    }

    private Firma construirFirma(CatalogoProductoCache producto, Map<String, String> body,
                                 String referencia, BigDecimal monto, String upc, String horaLocal) {
        return Firma.builder()
                .idDistribuidor(idDistribuidor)
                .codigoDispositivo(codigoDispositivo)
                .idServicio(producto.getIdServicio())
                .idProducto(producto.getIdProducto())
                .telefono(body.get("telefono"))
                .referencia(referencia)
                .horaLocal(horaLocal)
                .montoPago(monto.toPlainString())
                .upc(upc)
                .unidad(unidad)
                .build();
    }

    private String telefono(CatalogoProductoCache producto, String referencia, boolean pagoServicio) {
        if (producto.getIdCatTipoServicio() != null
                && (producto.getIdCatTipoServicio() == 10 || producto.getIdCatTipoServicio() == 11)) {
            return "#1111111111";
        }
        if (pagoServicio) {
            return "1111111111";
        }
        return referencia;
    }

    private String upc(String idempotencyKey) {
        if (idempotencyKey.length() >= 3 && idempotencyKey.length() <= 15) {
            return idempotencyKey;
        }
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(idempotencyKey.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash).substring(0, 15);
        } catch (Exception e) {
            throw new IllegalStateException("No se pudo derivar el upc", e);
        }
    }

    private String token() {
        Optional<GestoPagoToken> existente = gestoPagoTokenService
                .obtenerTokenActivo(idDistribuidor, codigoDispositivo);
        if (existente.isEmpty() || !esTokenValido(existente.get())) {
            gestoPagoTokenService.renovarToken();
            existente = gestoPagoTokenService.obtenerTokenActivo(idDistribuidor, codigoDispositivo);
        }
        GestoPagoToken token = existente
                .filter(this::esTokenValido)
                .orElseThrow(() -> new IllegalStateException("No hay token GestoPago valido guardado"));
        return "Bearer " + token.getToken();
    }

    private boolean esTokenValido(GestoPagoToken token) {
        if (token == null || token.getToken() == null || token.getToken().isBlank()) {
            return false;
        }
        if (Boolean.FALSE.equals(token.getActivo())) {
            return false;
        }
        if (token.getExpiresIn() != null && token.getExpiresIn() > 0 && token.getFechaActualizacion() != null) {
            LocalDateTime expiraEn = token.getFechaActualizacion().plusSeconds(token.getExpiresIn());
            if (LocalDateTime.now().isAfter(expiraEn)) {
                return false;
            }
        }
        return true;
    }

    private GestoPagoOperacionResponse operar(Operacion operacion) {
        return parsear(operacion.ejecutar());
    }

    private GestoPagoOperacionResponse parsear(String xml) {
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setNamespaceAware(false);
            factory.setExpandEntityReferences(false);
            Document doc = factory.newDocumentBuilder().parse(new InputSource(new StringReader(xml)));
            doc.getDocumentElement().normalize();

            GestoPagoOperacionResponse respuesta = new GestoPagoOperacionResponse();
            respuesta.setIdTx(texto(doc, "ID_TX"));
            respuesta.setNumAutorizacion(texto(doc, "NUM_AUTORIZACION"));
            respuesta.setSaldo(texto(doc, "SALDO"));
            respuesta.setComision(texto(doc, "COMISION"));
            respuesta.setFecha(texto(doc, "FECHA"));
            respuesta.setMonto(texto(doc, "MONTO"));
            respuesta.setMensaje(mensajeDe(doc));
            return respuesta;
        } catch (Exception e) {
            throw new IllegalStateException("Error al interpretar la respuesta de GestoPago", e);
        }
    }

    private GestoPagoMensajeOperacion mensajeDe(Document doc) {
        GestoPagoMensajeOperacion mensaje = new GestoPagoMensajeOperacion();
        mensaje.setCodigo(primeroNoVacio(texto(doc, "CODIGO_MENSAJE"), texto(doc, "CODIGO")));
        mensaje.setTexto(textoDeMensaje(doc.getElementsByTagName("MENSAJE")));
        mensaje.setSaldo(texto(doc, "SALDO"));
        mensaje.setReferencia(texto(doc, "REFERENCIA"));
        mensaje.setIdTx(texto(doc, "ID_TX"));
        mensaje.setPin(texto(doc, "PIN"));
        mensaje.setLegend(primeroNoVacio(texto(doc, "LEGEND"), texto(doc, "legend")));
        return mensaje;
    }

    private String texto(Document doc, String tag) {
        NodeList nodos = doc.getElementsByTagName(tag);
        if (nodos.getLength() == 0) {
            return null;
        }
        return nodos.item(0).getTextContent().trim();
    }

    private String textoDeMensaje(NodeList mensajes) {
        if (mensajes.getLength() == 0) {
            return null;
        }
        Element mensaje = (Element) mensajes.item(0);
        NodeList textos = mensaje.getElementsByTagName("TEXTO");
        if (textos.getLength() > 0) {
            return textos.item(0).getTextContent().trim();
        }
        return mensaje.getTextContent().trim();
    }

    private boolean esEstadoFinal(EstadoTransaccion estado) {
        return estado == EstadoTransaccion.APROBADA
                || estado == EstadoTransaccion.FALLIDA
                || estado == EstadoTransaccion.RECHAZADA;
    }

    private void cambiarEstado(Transaccion transaccion, EstadoTransaccion estado, String origen, String detalle) {
        transaccion.setEstado(estado);
        transaccionRepository.save(transaccion);
        registrarEvento(transaccion.getId(), estado, origen, detalle);
        publicarEnCacheAlConfirmar(transaccion);
    }

    /**
     * Escribe la transaccion en el historial de Redis solo cuando la transaccion de base de datos
     * confirma. Si se hiciera antes y la transaccion llegara a hacer rollback, Redis quedaria con un
     * pago que en Postgres no existe.
     */
    private void publicarEnCacheAlConfirmar(Transaccion transaccion) {
        TransaccionDto dto = TransaccionDto.from(transaccion);
        Long usuarioId = transaccion.getUsuarioId();
        Runnable escribir = () -> {
            try {
                historialPagosCache.registrar(usuarioId, dto);
            } catch (Exception e) {
                log.warn("No se pudo actualizar el historial cacheado de usuario {}: {}", usuarioId, e.getMessage());
            }
        };
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            escribir.run();
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                escribir.run();
            }
        });
    }

    private void registrarEvento(Long transaccionId, EstadoTransaccion estado, String origen, String detalle) {
        EventoTransaccion evento = new EventoTransaccion();
        evento.setTransaccionId(transaccionId);
        evento.setEstado(estado);
        evento.setOrigen(origen);
        evento.setDetalle(detalle);
        eventoTransaccionRepository.save(evento);
    }

    private BigDecimal decimal(String valor) {
        if (valor == null || valor.isBlank()) {
            return null;
        }
        try {
            return new BigDecimal(valor.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Instant fecha(String valor) {
        if (valor == null || valor.isBlank()) {
            return null;
        }
        try {
            return LocalDateTime.parse(valor.trim().replaceAll("\\s+", " "), ZONA_HORARIA)
                    .atZone(ZoneId.systemDefault())
                    .toInstant();
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private String primeroNoVacio(String a, String b) {
        if (a != null && !a.isBlank()) {
            return a;
        }
        return b;
    }

    @FunctionalInterface
    private interface Operacion {
        String ejecutar();
    }
}