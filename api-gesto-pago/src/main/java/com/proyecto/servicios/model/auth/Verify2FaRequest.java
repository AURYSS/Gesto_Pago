package com.proyecto.servicios.model.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Verify2FaRequest {

    @NotBlank(message = "El token temporal es obligatorio")
    private String tempToken;

    @NotBlank(message = "El código 2FA es obligatorio")
    private String codigo;

    /**
     * Si es true, finaliza cualquier sesión previa activa en otro dispositivo.
     */
    private Boolean forzarCierre;
}
