package com.proyecto.servicios.controller;

import com.proyecto.servicios.model.auth.CerrarSesionPreviaRequest;
import com.proyecto.servicios.model.auth.LoginRequest;
import com.proyecto.servicios.model.auth.RefreshRequest;
import com.proyecto.servicios.model.auth.RegisterRequest;
import com.proyecto.servicios.model.auth.TokenResponse;
import com.proyecto.servicios.model.auth.ValidarSesionResponse;
import com.proyecto.servicios.model.auth.Verify2FaRequest;
import com.proyecto.servicios.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/auth")
@Tag(name = "Autenticacion", description = "Login, 2FA (OTP), control de sesión concurrente (Web vs Móvil) y logout")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    @Operation(summary = "Paso 1: Iniciar sesión y generar código 2FA", description = "Valida credenciales y emite el código OTP de 6 dígitos con expiración de 5 minutos.")
    public ResponseEntity<TokenResponse> login(@Valid @RequestBody LoginRequest request) {
        TokenResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping({"/2fa/verify", "/verify-2fa"})
    @Operation(summary = "Paso 2: Validar 2FA y verificar sesión única concurrente", description = "Valida el OTP. Si hay sesión activa en otro dispositivo, retorna HTTP 409 Conflict.")
    public ResponseEntity<TokenResponse> verify2Fa(@Valid @RequestBody Verify2FaRequest request) {
        TokenResponse response = authService.verify2Fa(request);
        if (Boolean.TRUE.equals(response.getSesionActivaEnOtroDispositivo())) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(response);
        }
        return ResponseEntity.ok(response);
    }

    @PostMapping("/cerrar-sesion-previa")
    @Operation(summary = "Confirmar traspaso de sesión y revocar sesión en el otro dispositivo")
    public ResponseEntity<TokenResponse> cerrarSesionPrevia(@Valid @RequestBody CerrarSesionPreviaRequest request) {
        TokenResponse response = authService.cerrarSesionPrevia(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register")
    @Operation(summary = "Registrar un nuevo usuario")
    public ResponseEntity<TokenResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/refresh")
    @Operation(summary = "Rotar refresh token y obtener nuevos tokens")
    public ResponseEntity<TokenResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        return ResponseEntity.ok(authService.refresh(request));
    }

    @PostMapping("/logout")
    @Operation(summary = "Revocar tokens y cerrar sesión activa")
    public ResponseEntity<Void> logout(@RequestHeader(value = "Authorization", required = false) String authorization,
                                       Authentication authentication) {
        String refreshToken = null;
        if (authorization != null && authorization.startsWith("Refresh ")) {
            refreshToken = authorization.substring("Refresh ".length());
        }
        String email = authentication != null ? authentication.getName() : null;
        authService.logout(email, refreshToken);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/validar-sesion")
    @Operation(summary = "Validar token y estado de sesión activa")
    public ResponseEntity<ValidarSesionResponse> validarSesion(
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        ValidarSesionResponse response = authService.validarSesion(authorization);
        HttpStatus status = response.isValido() ? HttpStatus.OK : HttpStatus.UNAUTHORIZED;
        return ResponseEntity.status(status).body(response);
    }

    @PostMapping("/validar-token")
    @Operation(summary = "Validar token por body")
    public ResponseEntity<ValidarSesionResponse> validarTokenBody(@RequestBody Map<String, String> body) {
        String token = body != null ? body.get("token") : null;
        ValidarSesionResponse response = authService.validarSesion(token);
        HttpStatus status = response.isValido() ? HttpStatus.OK : HttpStatus.UNAUTHORIZED;
        return ResponseEntity.status(status).body(response);
    }
}
