package com.proyecto.servicios.model.auth;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class TokenResponse {

    private String accessToken;
    private String refreshToken;
    private String tokenType;
    private Long expiresIn;
    private String nombre;
    private List<String> roles;

    // --- Control 2FA ---
    private Boolean requiere2Fa;
    private String tempToken;
    private String codigo2FaDev;
    private String correoEnmascarado;
    private String dispositivo;
    private String mensaje;

    // --- Control de Sesión Concurrente ---
    private Boolean sesionActivaEnOtroDispositivo;
    private String dispositivoActivo;
    private String sessionId;

    public TokenResponse(String accessToken, String refreshToken, String tokenType, Long expiresIn,
                         String nombre, List<String> roles) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.tokenType = tokenType;
        this.expiresIn = expiresIn;
        this.nombre = nombre;
        this.roles = roles;
    }

    public static TokenResponse ok(String accessToken, String refreshToken, Long expiresIn,
                                   String nombre, List<String> roles) {
        return new TokenResponse(accessToken, refreshToken, "Bearer", expiresIn, nombre, roles);
    }

    public static TokenResponse ok(String accessToken, String refreshToken, Long expiresIn,
                                   String nombre, List<String> roles, String sessionId, String dispositivo) {
        TokenResponse response = new TokenResponse(accessToken, refreshToken, "Bearer", expiresIn, nombre, roles);
        response.setSessionId(sessionId);
        response.setDispositivo(dispositivo);
        response.setRequiere2Fa(false);
        response.setMensaje("Autenticación y 2FA completados exitosamente.");
        return response;
    }

    public static TokenResponse requiere2Fa(String tempToken, String codigo2FaDev, String correoEnmascarado, String dispositivo) {
        TokenResponse response = new TokenResponse();
        response.setRequiere2Fa(true);
        response.setTempToken(tempToken);
        response.setCodigo2FaDev(codigo2FaDev);
        response.setCorreoEnmascarado(correoEnmascarado);
        response.setDispositivo(dispositivo);
        response.setMensaje("Código de verificación 2FA generado. Ingréselo para continuar.");
        return response;
    }

    public static TokenResponse sesionEnOtroDispositivo(String tempToken, String dispositivoActivo, String dispositivoSolicitado) {
        TokenResponse response = new TokenResponse();
        response.setRequiere2Fa(false);
        response.setSesionActivaEnOtroDispositivo(true);
        response.setTempToken(tempToken);
        response.setDispositivoActivo(dispositivoActivo);
        response.setDispositivo(dispositivoSolicitado);
        String descDispositivo = "WEB".equalsIgnoreCase(dispositivoActivo)
                ? "otro navegador o ventana Web"
                : "un dispositivo movil";
        response.setMensaje("Existe una sesion activa en " + descDispositivo + ". Confirme si desea cerrar la sesion previa para continuar aqui.");
        return response;
    }
}
