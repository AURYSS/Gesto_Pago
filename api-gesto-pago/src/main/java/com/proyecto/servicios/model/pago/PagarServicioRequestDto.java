package com.proyecto.servicios.model.pago;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/**
 * Datos de entrada del cuadro central del diagrama para ejecutar "pagar servicio".
 * horaLocal y upc se generan automaticamente en el microservicio si no se envian.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PagarServicioRequestDto {

    @NotNull(message = "idServicio es obligatorio")
    private Integer idServicio;

    @NotNull(message = "idProducto es obligatorio")
    private Integer idProducto;

    @Size(max = 100, message = "El telefono no puede exceder 100 caracteres")
    private String telefono;

    @Size(max = 100, message = "La referencia no puede exceder 100 caracteres")
    private String referencia;

    @JsonAlias({"monto", "montoPago"})
    @Positive(message = "montoPago debe ser mayor a 0")
    private BigDecimal montoPago;

    private String horaLocal;

    @Size(max = 36, message = "upc invalido")
    private String upc;

    private Short tipoFront;

    /**
     * Devuelve la referencia o telefono principal enviado en la peticion.
     */
    public String referenciaEfectiva() {
        if (referencia != null && !referencia.isBlank()) {
            return referencia.trim();
        }
        if (telefono != null && !telefono.isBlank()) {
            return telefono.trim();
        }
        return null;
    }
}
