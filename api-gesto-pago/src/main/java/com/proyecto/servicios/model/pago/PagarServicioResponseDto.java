package com.proyecto.servicios.model.pago;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Respuesta del flujo "pagar servicio":
 * Cuadro central -> Firmar -> Obtener Token -> Enviar sendTx.
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PagarServicioResponseDto {

    private Long idTransaccion;
    private Integer idServicio;
    private Integer idProducto;
    private String telefono;
    private String referencia;
    private String horaLocal;
    private String montoPago;
    private String upc;
    private String firma;
    private String estado;
    private String codigoMensaje;
    private String mensaje;
    private String idTx;
    private String numAutorizacion;
    private String saldo;
    private String comision;
    private String pin;
    private String legend;
    private String fecha;
}
