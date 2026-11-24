package com.proyecto.servicios.service.Impl;

import com.proyecto.servicios.service.EmailService;
import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
@Slf4j
public class EmailServiceImpl implements EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username:}")
    private String remitente;

    @Value("${spring.mail.remitente-nombre:Gesto Pago Seguridad}")
    private String remitenteNombre;

    @Autowired
    public EmailServiceImpl(@Autowired(required = false) JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    @Override
    @Async
    public void enviarCodigo2Fa(String destinatario, String codigo2Fa, String dispositivo) {
        if (!StringUtils.hasText(destinatario)) {
            log.warn("No se puede enviar correo 2FA: destinatario vacío.");
            return;
        }

        if (mailSender == null || !StringUtils.hasText(remitente)) {
            log.warn("[SMTP NO CONFIGURADO] spring.mail.username no esta definido en .env.");
            log.warn("Para enviar correos reales via Gmail/SMTP, agrega MAIL_USERNAME y MAIL_PASSWORD en tu .env.");
            log.info("[SIMULADO EN CONSOLA PARA PRUEBAS] Codigo 2FA para [{}]: {}", destinatario, codigo2Fa);
            return;
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(remitente, remitenteNombre);
            helper.setTo(destinatario);
            helper.setSubject("Tu codigo de verificacion de 2 Factores - Gesto Pago");

            String html = construirHtml2Fa(codigo2Fa, dispositivo);
            helper.setText(html, true);

            mailSender.send(message);
            log.info("Correo de verificacion 2FA enviado exitosamente a [{}] para dispositivo [{}]", destinatario, dispositivo);
        } catch (Exception e) {
            log.error("Error al enviar correo 2FA a [{}]: {}. [CODIGO 2FA DE RESPALDO]: {}", destinatario, e.getMessage(), codigo2Fa);
        }
    }

    @Override
    @Async
    public void enviarNotificacionMovimiento(
            String destinatario,
            String nombreUsuario,
            String servicio,
            String referencia,
            String monto,
            String folioUpc,
            String estado,
            String fecha) {
        if (!StringUtils.hasText(destinatario)) return;

        if (mailSender == null || !StringUtils.hasText(remitente)) {
            log.info("[SIMULADO EN CONSOLA] Notificacion de movimiento para [{}]: Servicio={}, Monto={}, Folio={}, Estado={}",
                    destinatario, servicio, monto, folioUpc, estado);
            return;
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(remitente, remitenteNombre);
            helper.setTo(destinatario);
            helper.setSubject("Comprobante de Movimiento: " + servicio + " (" + estado + ") - Gesto Pago");

            String html = construirHtmlMovimiento(nombreUsuario, servicio, referencia, monto, folioUpc, estado, fecha);
            helper.setText(html, true);

            mailSender.send(message);
            log.info("Notificacion de movimiento enviada exitosamente a [{}] para folio [{}]", destinatario, folioUpc);
        } catch (Exception e) {
            log.error("Error al enviar notificacion de movimiento a [{}]: {}", destinatario, e.getMessage());
        }
    }

    private String construirHtmlMovimiento(
            String nombreUsuario,
            String servicio,
            String referencia,
            String monto,
            String folioUpc,
            String estado,
            String fecha) {
        String colorEstado = "APROBADA".equalsIgnoreCase(estado) ? "#10b981" : "#f59e0b";
        String saludo = StringUtils.hasText(nombreUsuario) ? "Hola, <strong>" + nombreUsuario + "</strong>" : "Estimado cliente";
        return """
            <!DOCTYPE html>
            <html lang="es">
            <head>
                <meta charset="UTF-8">
                <style>
                    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0b0f19; color: #f8fafc; margin: 0; padding: 20px; }
                    .container { max-width: 540px; margin: 0 auto; background: #131a29; border: 1px solid #222d42; border-radius: 16px; padding: 32px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
                    .header { text-align: center; margin-bottom: 24px; }
                    .brand { font-size: 24px; font-weight: 800; color: #10b981; letter-spacing: -0.5px; }
                    .subtitle { font-size: 14px; color: #94a3b8; margin-top: 4px; }
                    .amount-card { background: #0f1523; border: 1px solid #1e293b; border-radius: 12px; padding: 20px; text-align: center; margin: 20px 0; }
                    .amount { font-size: 32px; font-weight: 800; color: #34d399; margin: 8px 0; }
                    .status-badge { display: inline-block; padding: 4px 12px; border-radius: 9999px; font-size: 12px; font-weight: 700; text-transform: uppercase; background: rgba(16, 185, 129, 0.15); color: %s; border: 1px solid %s; }
                    .detail-table { width: 100%%; border-collapse: collapse; margin-top: 16px; font-size: 13px; }
                    .detail-table td { padding: 10px 0; border-bottom: 1px solid #1e293b; color: #cbd5e1; }
                    .detail-table td.label { color: #64748b; font-weight: 600; width: 40%%; }
                    .footer { text-align: center; font-size: 12px; color: #64748b; margin-top: 28px; border-top: 1px solid #1e293b; padding-top: 16px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <div class="brand">Gesto Pago</div>
                        <div class="subtitle">Notificación de Movimiento Transaccional</div>
                    </div>
                    <p style="font-size: 14px; color: #cbd5e1; line-height: 1.5;">
                        %s. Te informamos que se ha procesado un movimiento en tu cuenta:
                    </p>
                    <div class="amount-card">
                        <div style="font-size: 12px; color: #94a3b8; text-transform: uppercase; font-weight: 700;">Monto Pagado</div>
                        <div class="amount">%s</div>
                        <span class="status-badge">%s</span>
                    </div>
                    <table class="detail-table">
                        <tr>
                            <td class="label">Servicio / Producto:</td>
                            <td><strong>%s</strong></td>
                        </tr>
                        <tr>
                            <td class="label">Referencia / Teléfono:</td>
                            <td>%s</td>
                        </tr>
                        <tr>
                            <td class="label">Folio / UPC de Operación:</td>
                            <td style="font-family: monospace;">%s</td>
                        </tr>
                        <tr>
                            <td class="label">Fecha y Hora:</td>
                            <td>%s</td>
                        </tr>
                    </table>
                    <p style="font-size: 12px; color: #94a3b8; margin-top: 20px; line-height: 1.4;">
                        Este comprobante digital es generado automáticamente por el ecosistema Gesto Pago.
                    </p>
                    <div class="footer">
                        Gesto Pago &bull; Ecosistema de Comercio Digital Seguro &bull; Unidad II
                    </div>
                </div>
            </body>
            </html>
            """.formatted(colorEstado, colorEstado, saludo, monto, estado, servicio, referencia, folioUpc, fecha);
    }

    private String construirHtml2Fa(String codigo2Fa, String dispositivo) {
        String dispNombre = "WEB".equalsIgnoreCase(dispositivo) ? "Plataforma Web" : "Aplicación Móvil";
        return """
            <!DOCTYPE html>
            <html lang="es">
            <head>
                <meta charset="UTF-8">
                <style>
                    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0b0f19; color: #f8fafc; margin: 0; padding: 20px; }
                    .container { max-width: 520px; margin: 0 auto; background: #131a29; border: 1px solid #222d42; border-radius: 16px; padding: 32px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
                    .header { text-align: center; margin-bottom: 24px; }
                    .brand { font-size: 24px; font-weight: 800; color: #10b981; letter-spacing: -0.5px; }
                    .subtitle { font-size: 14px; color: #94a3b8; margin-top: 4px; }
                    .card { background: #0f1523; border: 1px solid #1e293b; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0; }
                    .otp-box { font-size: 38px; font-weight: 900; letter-spacing: 8px; color: #34d399; font-family: monospace; margin: 12px 0; }
                    .info { font-size: 13px; color: #94a3b8; line-height: 1.6; }
                    .alert { background: rgba(245, 158, 11, 0.1); border-left: 4px solid #f59e0b; padding: 12px; font-size: 12px; color: #fbbf24; text-align: left; border-radius: 4px; margin-top: 16px; }
                    .footer { text-align: center; font-size: 12px; color: #64748b; margin-top: 32px; border-top: 1px solid #1e293b; padding-top: 16px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <div class="brand">Gesto Pago</div>
                        <div class="subtitle">Verificación de Seguridad en Dos Pasos (2FA)</div>
                    </div>
                    <p class="info">
                        Has solicitado ingresar a tu cuenta desde la <strong>%s</strong>. Utiliza el siguiente código de un solo uso para completar tu autenticación:
                    </p>
                    <div class="card">
                        <div style="font-size: 12px; color: #94a3b8; text-transform: uppercase; font-weight: 700;">Código de Verificación</div>
                        <div class="otp-box">%s</div>
                        <div style="font-size: 12px; color: #64748b;">Válido únicamente durante los próximos 5 minutos.</div>
                    </div>
                    <div class="alert">
                        <strong>Aviso de seguridad:</strong> Si no reconoces este intento de inicio de sesion, ignora este correo y cambia tu contrasena de inmediato. Nunca compartas este codigo con nadie.
                    </div>
                    <div class="footer">
                        Gesto Pago &bull; Ecosistema de Comercio Digital Seguro &bull; Unidad II
                    </div>
                </div>
            </body>
            </html>
            """.formatted(dispNombre, codigo2Fa);
    }
}
