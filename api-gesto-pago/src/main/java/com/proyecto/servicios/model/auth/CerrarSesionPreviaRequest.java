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
public class CerrarSesionPreviaRequest {

    @NotBlank(message = "El token temporal es obligatorio")
    private String tempToken;
}
