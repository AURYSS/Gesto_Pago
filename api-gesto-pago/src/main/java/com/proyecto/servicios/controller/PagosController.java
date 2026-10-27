package com.proyecto.servicios.controller;

import com.proyecto.servicios.exception.ApiException;
import com.proyecto.servicios.model.pago.PagarServicioRequestDto;
import com.proyecto.servicios.model.pago.PagarServicioResponseDto;
import com.proyecto.servicios.model.pago.PagoPendienteDto;
import com.proyecto.servicios.model.pago.PagoRequestDto;
import com.proyecto.servicios.model.pago.TransaccionDto;
import com.proyecto.servicios.model.pago.VerificarReferenciaRequest;
import com.proyecto.servicios.model.pago.VerificarReferenciaResponse;
import com.proyecto.servicios.repositorys.auth.UsuarioRepository;
import com.proyecto.servicios.service.PagosService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/pagos")
@Tag(name = "Pagos", description = "Verificacion de referencias, pago de servicios y confirmacion de transacciones")
@SecurityRequirement(name = "bearerAuth")
public class PagosController {

    private final PagosService pagosService;
    private final UsuarioRepository usuarioRepository;

    public PagosController(PagosService pagosService, UsuarioRepository usuarioRepository) {
        this.pagosService = pagosService;
        this.usuarioRepository = usuarioRepository;
    }

    @PostMapping(value = "/pagar-servicio", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Pagar servicio ejecutando el flujo: Firmar -> Obtener Token -> Enviar sendTx")
    public ResponseEntity<PagarServicioResponseDto> pagarServicio(
            @Valid @RequestBody PagarServicioRequestDto request, Authentication authentication) {
        return ResponseEntity.ok(pagosService.pagarServicio(usuarioIdOpcional(authentication), request));
    }

    @PostMapping(value = "/confirmar-servicio", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Conciliar una operacion en proceso contra confirmTx.do del proveedor")
    public ResponseEntity<PagarServicioResponseDto> confirmarServicio(
            @Valid @RequestBody PagarServicioRequestDto request, Authentication authentication) {
        return ResponseEntity.ok(pagosService.confirmarServicio(usuarioIdOpcional(authentication), request));
    }

    @PostMapping(value = "/verificar-referencia", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Verificar una referencia contra el proveedor")
    public ResponseEntity<VerificarReferenciaResponse> verificarReferencia(
            @Valid @RequestBody VerificarReferenciaRequest request, Authentication authentication) {
        return ResponseEntity.ok(pagosService.verificarReferencia(request));
    }

    @PostMapping(value = "/transacciones", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Crear y enviar una transaccion de pago")
    public ResponseEntity<TransaccionDto> crearTransaccion(
            @Valid @RequestBody PagoRequestDto request, Authentication authentication) {
        return ResponseEntity.ok(pagosService.crearTransaccion(usuarioId(authentication), request));
    }

    @PostMapping(value = "/transacciones/{id}/confirmar", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Confirmar el resultado de una transaccion contra el proveedor")
    public ResponseEntity<TransaccionDto> confirmarTransaccion(
            @PathVariable Long id, Authentication authentication) {
        return ResponseEntity.ok(pagosService.confirmarTransaccion(usuarioId(authentication), id));
    }

    @GetMapping(value = "/transacciones", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Historial de transacciones del usuario")
    public ResponseEntity<List<TransaccionDto>> historial(Authentication authentication) {
        return ResponseEntity.ok(pagosService.historial(usuarioId(authentication)));
    }

    @GetMapping(value = "/pendientes", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Pagos pendientes del usuario (en proceso, pendientes o fallidos reintentables)")
    public ResponseEntity<List<PagoPendienteDto>> pendientes(Authentication authentication) {
        return ResponseEntity.ok(pagosService.pendientes(usuarioId(authentication)));
    }

    private Long usuarioId(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw ApiException.noAutenticado();
        }
        String email = authentication.getName();
        return usuarioRepository.findByEmail(email)
                .map(u -> {
                    if (!Boolean.TRUE.equals(u.getActivo())) {
                        throw ApiException.cuentaInactiva();
                    }
                    return u.getId();
                })
                .orElseThrow(ApiException::noAutenticado);
    }

    private Long usuarioIdOpcional(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            return null;
        }
        return usuarioRepository.findByEmail(authentication.getName())
                .map(u -> {
                    if (!Boolean.TRUE.equals(u.getActivo())) {
                        throw ApiException.cuentaInactiva();
                    }
                    return u.getId();
                })
                .orElse(null);
    }
}