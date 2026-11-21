package com.proyecto.servicios.service;

import com.proyecto.servicios.model.auth.CerrarSesionPreviaRequest;
import com.proyecto.servicios.model.auth.LoginRequest;
import com.proyecto.servicios.model.auth.RefreshRequest;
import com.proyecto.servicios.model.auth.RegisterRequest;
import com.proyecto.servicios.model.auth.TokenResponse;
import com.proyecto.servicios.model.auth.ValidarSesionResponse;
import com.proyecto.servicios.model.auth.Verify2FaRequest;

public interface AuthService {

    /**
     * Paso 1: Inicia login, valida credenciales y genera código 2FA.
     */
    TokenResponse login(LoginRequest request);

    /**
     * Paso 2: Valida 2FA y verifica concurrencia de sesión (Móvil vs Web).
     */
    TokenResponse verify2Fa(Verify2FaRequest request);

    /**
     * Confirma el cierre de la sesión previa en el otro dispositivo.
     */
    TokenResponse cerrarSesionPrevia(CerrarSesionPreviaRequest request);

    TokenResponse register(RegisterRequest request);

    TokenResponse refresh(RefreshRequest request);

    void logout(String refreshToken);

    void logout(String email, String refreshToken);

    ValidarSesionResponse validarSesion(String token);
}
