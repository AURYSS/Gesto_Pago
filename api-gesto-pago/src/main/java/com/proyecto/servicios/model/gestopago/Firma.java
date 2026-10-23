package com.proyecto.servicios.model.gestopago;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Representa los datos de la operacion que se firman y encriptan
 * antes de obtener el token y enviar la transaccion (sendTx) a GestoPago.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Firma {

    private Integer idDistribuidor;
    private String codigoDispositivo;
    private Integer idServicio;
    private Integer idProducto;
    private String telefono;
    private String referencia;
    private String horaLocal;
    private String montoPago;
    private String upc;
    private String unidad;

    /**
     * Construye la cadena original concatenada que sera encriptada.
     */
    public String cadenaOriginal() {
        return String.join("|",
                valor(idDistribuidor),
                valor(codigoDispositivo),
                valor(idServicio),
                valor(idProducto),
                valor(telefono),
                valor(referencia),
                valor(horaLocal),
                valor(montoPago),
                valor(upc),
                valor(unidad)
        );
    }

    private String valor(Object campo) {
        return campo == null ? "" : String.valueOf(campo).trim();
    }
}
