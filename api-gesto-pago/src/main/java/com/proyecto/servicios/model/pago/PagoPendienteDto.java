package com.proyecto.servicios.model.pago;

import com.proyecto.servicios.entity.pago.EstadoTransaccion;
import com.proyecto.servicios.entity.pago.Transaccion;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.EnumSet;
import java.util.Set;

/**
 * Pago que todavia no esta resuelto para el usuario.
 *
 * No es un recibo con fecha de vencimiento: son las transacciones que el
 * usuario lanzo y que siguen sin terminarse (EN_PROCESO esperando confirmacion
 * del proveedor, PENDIENTE sin enviar, FALLIDA reintentable). Todo el dato
 * viene de la fila real de `transacciones`, no de una lista inventada en el
 * cliente, y por eso cada una expone la accion que si corresponde:
 * confirmar, pagar o reintentar.
 */
@Getter
@Setter
@NoArgsConstructor
public class PagoPendienteDto {

    private static final DateTimeFormatter ISO_UTC =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'").withZone(ZoneOffset.UTC);

    /**
     * Estados que siguen siendo accion del usuario. APROBADA y RECHAZADA
     * quedan fuera: son finales y viven en el historial.
     */
    private static final Set<EstadoTransaccion> ESTADOS_PENDIENTES =
            EnumSet.of(EstadoTransaccion.PENDIENTE, EstadoTransaccion.EN_PROCESO, EstadoTransaccion.FALLIDA);

    private Long id;
    private Integer idServicio;
    private Integer idProducto;
    private String servicio;
    private String producto;
    private String referencia;
    private String monto;
    private String comision;
    private String estado;
    private String fecha;
    private String errorMensaje;
    private Boolean puedeConfirmar;
    private Boolean puedeReintentar;

    public static boolean esPendiente(EstadoTransaccion estado) {
        return estado != null && ESTADOS_PENDIENTES.contains(estado);
    }

    public static PagoPendienteDto from(Transaccion tx) {
        PagoPendienteDto dto = new PagoPendienteDto();
        dto.setId(tx.getId());
        dto.setIdServicio(tx.getIdServicio());
        dto.setIdProducto(tx.getIdProducto());
        dto.setServicio(tx.getServicio());
        dto.setProducto(tx.getProducto());
        dto.setReferencia(tx.getReferencia());
        dto.setMonto(texto(tx.getMonto()));
        dto.setComision(texto(tx.getComision()));
        dto.setEstado(tx.getEstado() == null ? null : tx.getEstado().name());
        dto.setFecha(fecha(tx.getFecha() != null ? tx.getFecha() : tx.getCreatedAt()));
        dto.setErrorMensaje(tx.getErrorMensaje());
        // EN_PROCESO se resuelve consultando al proveedor; FALLIDA se
        // reintenta con la misma clave de idempotencia, que reutiliza la fila.
        dto.setPuedeConfirmar(tx.getEstado() == EstadoTransaccion.EN_PROCESO);
        dto.setPuedeReintentar(tx.getEstado() == EstadoTransaccion.FALLIDA
                || tx.getEstado() == EstadoTransaccion.PENDIENTE);
        return dto;
    }

    private static String texto(java.math.BigDecimal valor) {
        return valor == null ? null : valor.toPlainString();
    }

    private static String fecha(Instant instante) {
        return instante == null ? null : ISO_UTC.format(instante);
    }
}
