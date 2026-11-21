package com.proyecto.servicios.model.auth;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ValidarSesionResponse {

    private boolean valido;
    private String codigo;
    private String error;
    private String mensaje;
    private String email;
    private Long usuarioId;
    private List<String> roles;
    private String dispositivo;
    private String sessionId;
}
