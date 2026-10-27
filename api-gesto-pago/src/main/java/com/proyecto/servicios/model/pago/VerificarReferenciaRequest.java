package com.proyecto.servicios.model.pago;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class VerificarReferenciaRequest {

    @NotNull(message = "idServicio es obligatorio")
    @Positive(message = "idServicio debe ser mayor a 0")
    private Integer idServicio;

    @NotNull(message = "idProducto es obligatorio")
    @Positive(message = "idProducto debe ser mayor a 0")
    private Integer idProducto;

    @NotBlank(message = "La referencia es obligatoria")
    @Size(max = 100, message = "La referencia no puede exceder 100 caracteres")
    private String referencia;
}