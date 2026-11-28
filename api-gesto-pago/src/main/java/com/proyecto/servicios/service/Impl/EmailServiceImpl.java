package com.proyecto.servicios.service.Impl;

import com.fasterxml.jackson.databind.ObjectMapper;
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

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

@Service
@Slf4j
public class EmailServiceImpl implements EmailService {

    private final JavaMailSender mailSender;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    @Value("${spring.mail.username:}")
    private String remitente;

    @Value("${spring.mail.remitente-nombre:Gesto Pago Seguridad}")
    private String remitenteNombre;

    @Value("${email.resend.api-key:}")
    private String resendApiKey;

    @Value("${email.resend.from:Gesto Pago <onboarding@resend.dev>}")
    private String resendFrom;

    @Value("${email.brevo.api-key:}")
    private String brevoApiKey;

    @Autowired
    public EmailServiceImpl(@Autowired(required = false) JavaMailSender mailSender) {
        this.mailSender = mailSender;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
        this.objectMapper = new ObjectMapper();
    }

    @Override
    @Async
    public void enviarCodigo2Fa(String destinatario, String codigo2Fa, String dispositivo) {
        if (!StringUtils.hasText(destinatario)) {
            log.warn("No se puede enviar correo 2FA: destinatario vacío.");
            return;
        }

        String asunto = "Tu codigo de verificacion de 2 Factores - Gesto Pago";
        String html = construirHtml2Fa(codigo2Fa, dispositivo);

        // 1. Intento por Resend API (HTTPS Puerto 443 - Inmune a bloqueos de puertos SMTP en Render)
        if (StringUtils.hasText(resendApiKey)) {
            log.info("Enviando correo 2FA a [{}] via Resend HTTPS API...", destinatario);
            if (enviarViaResend(destinatario, asunto, html)) {
                return;
            }
            log.warn("Fallo el envio via Resend. Intentando metodos alternativos...");
        }

        // 2. Intento por Brevo API (HTTPS Puerto 443)
        if (StringUtils.hasText(brevoApiKey)) {
            log.info("Enviando correo 2FA a [{}] via Brevo HTTPS API...", destinatario);
            if (enviarViaBrevo(destinatario, asunto, html)) {
                return;
            }
            log.warn("Fallo el envio via Brevo. Intentando metodos alternativos...");
        }

        // 3. Intento por SMTP estandar (Gmail)
        if (mailSender == null || !StringUtils.hasText(remitente)) {
            log.warn("[SMTP/API NO CONFIGURADO] No se definieron credenciales de correo.");
            log.info("[SIMULADO EN CONSOLA PARA PRUEBAS] Codigo 2FA para [{}]: {}", destinatario, codigo2Fa);
            return;
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(remitente, remitenteNombre);
            helper.setTo(destinatario);
            helper.setSubject(asunto);
            helper.setText(html, true);

            mailSender.send(message);
            log.info("Correo de verificacion 2FA enviado exitosamente por SMTP a [{}] para dispositivo [{}]", destinatario, dispositivo);
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

        String asunto = "Comprobante de Movimiento: " + servicio + " (" + estado + ") - Gesto Pago";
        String html = construirHtmlMovimiento(nombreUsuario, servicio, referencia, monto, folioUpc, estado, fecha);

        // 1. Intento por Resend API (HTTPS)
        if (StringUtils.hasText(resendApiKey)) {
            if (enviarViaResend(destinatario, asunto, html)) {
                return;
            }
        }

        // 2. Intento por Brevo API (HTTPS)
        if (StringUtils.hasText(brevoApiKey)) {
            if (enviarViaBrevo(destinatario, asunto, html)) {
                return;
            }
        }

        // 3. Intento por SMTP estandar
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
            helper.setSubject(asunto);
            helper.setText(html, true);

            mailSender.send(message);
            log.info("Notificacion de movimiento enviada exitosamente por SMTP a [{}] para folio [{}]", destinatario, folioUpc);
        } catch (Exception e) {
            log.error("Error al enviar notificacion de movimiento por SMTP a [{}]: {}", destinatario, e.getMessage());
        }
    }

    private boolean enviarViaResend(String destinatario, String asunto, String html) {
        try {
            Map<String, Object> payload = new HashMap<>();
            String from = StringUtils.hasText(resendFrom) ? resendFrom : "Gesto Pago <onboarding@resend.dev>";
            payload.put("from", from);
            payload.put("to", Collections.singletonList(destinatario));
            payload.put("subject", asunto);
            payload.put("html", html);

            String json = objectMapper.writeValueAsString(payload);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create("https://api.resend.com/emails"))
                    .header("Authorization", "Bearer " + resendApiKey.trim())
                    .header("Content-Type", "application/json")
                    .timeout(Duration.ofSeconds(10))
                    .POST(HttpRequest.BodyPublishers.ofString(json, StandardCharsets.UTF_8))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                log.info("[RESEND HTTPS OK] Correo entregado a [{}] vía API (HTTP {}). ID: {}", destinatario, response.statusCode(), response.body());
                return true;
            } else {
                log.error("[RESEND HTTP ERROR] Codigo {}: {}", response.statusCode(), response.body());
                return false;
            }
        } catch (Exception e) {
            log.error("[RESEND EXCEPTION] Error en peticion HTTPS a Resend: {}", e.getMessage());
            return false;
        }
    }

    private boolean enviarViaBrevo(String destinatario, String asunto, String html) {
        try {
            Map<String, Object> sender = new HashMap<>();
            sender.put("name", remitenteNombre);
            sender.put("email", StringUtils.hasText(remitente) ? remitente : "notificaciones@gestopago.com");

            Map<String, Object> toItem = new HashMap<>();
            toItem.put("email", destinatario);

            Map<String, Object> payload = new HashMap<>();
            payload.put("sender", sender);
            payload.put("to", Collections.singletonList(toItem));
            payload.put("subject", asunto);
            payload.put("htmlContent", html);

            String json = objectMapper.writeValueAsString(payload);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create("https://api.brevo.com/v3/smtp/email"))
                    .header("api-key", brevoApiKey.trim())
                    .header("Content-Type", "application/json")
                    .timeout(Duration.ofSeconds(10))
                    .POST(HttpRequest.BodyPublishers.ofString(json, StandardCharsets.UTF_8))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                log.info("[BREVO HTTPS OK] Correo entregado a [{}] vía API (HTTP {}). Respuesta: {}", destinatario, response.statusCode(), response.body());
                return true;
            } else {
                log.error("[BREVO HTTP ERROR] Codigo {}: {}", response.statusCode(), response.body());
                return false;
            }
        } catch (Exception e) {
            log.error("[BREVO EXCEPTION] Error en peticion HTTPS a Brevo: {}", e.getMessage());
            return false;
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
