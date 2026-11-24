package com.proyecto.servicios.service;

/**
 * Servicio para el envío real de correos electrónicos transaccionales y de seguridad.
 */
public interface EmailService {

    /**
     * Envía el código de verificación 2FA (OTP) al correo del usuario.
     *
     * @param destinatario correo electrónico del usuario
     * @param codigo2Fa    código de 6 dígitos generado
     * @param dispositivo  origen del intento de inicio de sesión ("MOVIL" o "WEB")
     */
    void enviarCodigo2Fa(String destinatario, String codigo2Fa, String dispositivo);

    /**
     * Envía una notificación por correo electrónico con los detalles del movimiento / transacción.
     */
    void enviarNotificacionMovimiento(
            String destinatario,
            String nombreUsuario,
            String servicio,
            String referencia,
            String monto,
            String folioUpc,
            String estado,
            String fecha
    );
}
