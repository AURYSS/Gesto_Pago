package com.proyecto.servicios.service.Impl;

import com.proyecto.servicios.config.security.JwtService;
import com.proyecto.servicios.entity.auth.RefreshToken;
import com.proyecto.servicios.entity.auth.Rol;
import com.proyecto.servicios.entity.auth.Usuario;
import com.proyecto.servicios.exception.ApiException;
import com.proyecto.servicios.model.auth.CerrarSesionPreviaRequest;
import com.proyecto.servicios.model.auth.LoginRequest;
import com.proyecto.servicios.model.auth.RefreshRequest;
import com.proyecto.servicios.model.auth.RegisterRequest;
import com.proyecto.servicios.model.auth.TokenResponse;
import com.proyecto.servicios.model.auth.ValidarSesionResponse;
import com.proyecto.servicios.model.auth.Verify2FaRequest;
import com.proyecto.servicios.repositorys.auth.RefreshTokenRepository;
import com.proyecto.servicios.repositorys.auth.RolRepository;
import com.proyecto.servicios.repositorys.auth.UsuarioRepository;
import com.proyecto.servicios.service.AuthService;
import io.jsonwebtoken.Claims;
import com.proyecto.servicios.service.EmailService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@Slf4j
public class AuthServiceImpl implements AuthService {

    private final UsuarioRepository usuarioRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final RolRepository rolRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final EmailService emailService;
    private final long refreshTtlDays;
    private final boolean exposeDevCode;
    private final String dummyPasswordHash;
    private final SecureRandom secureRandom = new SecureRandom();

    @Autowired
    public AuthServiceImpl(UsuarioRepository usuarioRepository,
                           RefreshTokenRepository refreshTokenRepository,
                           RolRepository rolRepository,
                           PasswordEncoder passwordEncoder,
                           JwtService jwtService,
                           EmailService emailService,
                           @Value("${security.jwt.refresh-ttl-days:7}") long refreshTtlDays,
                           @Value("${security.2fa.expose-dev-code:false}") boolean exposeDevCode) {
        this.usuarioRepository = usuarioRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.rolRepository = rolRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.emailService = emailService;
        this.refreshTtlDays = refreshTtlDays;
        this.exposeDevCode = exposeDevCode;
        this.dummyPasswordHash = passwordEncoder.encode(UUID.randomUUID().toString());
    }

    public AuthServiceImpl(UsuarioRepository usuarioRepository,
                           RefreshTokenRepository refreshTokenRepository,
                           RolRepository rolRepository,
                           PasswordEncoder passwordEncoder,
                           JwtService jwtService,
                           long refreshTtlDays) {
        this(usuarioRepository, refreshTokenRepository, rolRepository, passwordEncoder, jwtService, (dest, cod, disp) -> {}, refreshTtlDays, false);
    }

    @Override
    @Transactional
    public TokenResponse login(LoginRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        String dispositivo = normalizarDispositivo(request.getDispositivo());
        Usuario usuario = usuarioRepository.findByEmail(email).orElse(null);

        if (usuario == null) {
            log.warn("[AUTH] Intento de login fallido: usuario no registrado [{}] desde dispositivo [{}]", email, dispositivo);
            passwordEncoder.matches(request.getPassword(), dummyPasswordHash);
            throw ApiException.authInvalida();
        }
        if (!passwordEncoder.matches(request.getPassword(), usuario.getPasswordHash())) {
            log.warn("[AUTH] Intento de login fallido: contrasena no coincide para [{}] desde dispositivo [{}]", email, dispositivo);
            throw ApiException.authInvalida();
        }
        if (!Boolean.TRUE.equals(usuario.getActivo())) {
            log.warn("[AUTH] Intento de login rechazado: cuenta inactiva para [{}]", email);
            throw ApiException.cuentaInactiva();
        }

        // Generar código 2FA numérico de 6 dígitos
        String codigo2Fa = String.format("%06d", secureRandom.nextInt(1_000_000));
        Instant expiracion = Instant.now().plus(Duration.ofMinutes(5));
        String tempToken = UUID.randomUUID().toString();

        usuario.setTwoFactorCodigo(codigo2Fa);
        usuario.setTwoFactorExpiracion(expiracion);
        usuario.setTwoFactorTempToken(tempToken);
        usuario.setTwoFactorDispositivo(dispositivo);
        usuarioRepository.save(usuario);

        log.info("=================================================================");
        log.info("[2FA api-gesto-pago] CODIGO GENERADO para [{}]: {}", email, codigo2Fa);
        log.info("Dispositivo solicitante: {} | Expira en: {}", dispositivo, expiracion);
        log.info("=================================================================");

        // Enviar correo real con el código OTP
        emailService.enviarCodigo2Fa(email, codigo2Fa, dispositivo);

        // NUNCA exponer el código al cliente a menos que explícitamente se active en propiedades
        String codigoDev = exposeDevCode ? codigo2Fa : null;
        return TokenResponse.requiere2Fa(tempToken, codigoDev, enmascararCorreo(email), dispositivo);
    }

    @Override
    @Transactional
    public TokenResponse verify2Fa(Verify2FaRequest request) {
        Usuario usuario = usuarioRepository.findByTwoFactorTempToken(request.getTempToken())
                .orElseThrow(ApiException::codigo2FaInvalido);

        if (usuario.getTwoFactorExpiracion() == null || usuario.getTwoFactorExpiracion().isBefore(Instant.now())) {
            throw ApiException.codigo2FaInvalido();
        }

        if (usuario.getTwoFactorCodigo() == null || !usuario.getTwoFactorCodigo().equals(request.getCodigo().trim())) {
            throw ApiException.codigo2FaInvalido();
        }

        String nuevoDispositivo = usuario.getTwoFactorDispositivo() != null
                ? usuario.getTwoFactorDispositivo()
                : "MOVIL";

        // Control de concurrencia: Verificar si ya existe una sesion activa (en cualquier dispositivo o en el mismo)
        boolean sesionPreviaActiva = Boolean.TRUE.equals(usuario.getSesionActiva())
                && usuario.getSessionIdActivo() != null;

        if (sesionPreviaActiva && !Boolean.TRUE.equals(request.getForzarCierre())) {
            String dispPrevio = usuario.getDispositivoActivo() != null ? usuario.getDispositivoActivo() : "OTRO";
            log.warn("[ALERTA] Conflicto de sesion en api-gesto-pago: Usuario {} con sesion activa en [{}] e intenta ingresar desde [{}]",
                    usuario.getEmail(), dispPrevio, nuevoDispositivo);
            return TokenResponse.sesionEnOtroDispositivo(request.getTempToken(), dispPrevio, nuevoDispositivo);
        }

        // Si no hay conflicto o se forzó el cierre, activar nueva sesión
        refreshTokenRepository.revocarTodosDe(usuario);
        String nuevoSessionId = UUID.randomUUID().toString();
        usuario.setSesionActiva(true);
        usuario.setDispositivoActivo(nuevoDispositivo);
        usuario.setSessionIdActivo(nuevoSessionId);
        usuario.setFechaUltimoAcceso(Instant.now());

        // Limpiar datos temporales de 2FA
        usuario.setTwoFactorCodigo(null);
        usuario.setTwoFactorExpiracion(null);
        usuario.setTwoFactorTempToken(null);
        usuario.setTwoFactorDispositivo(null);
        usuarioRepository.save(usuario);

        String access = jwtService.generarAccessToken(usuario);
        String refresh = guardarRefreshToken(usuario);

        log.info("[OK] Sesion y 2FA completados en api-gesto-pago para [{}] en dispositivo [{}] (SessionId: {})",
                usuario.getEmail(), nuevoDispositivo, nuevoSessionId);

        return TokenResponse.ok(access, refresh, jwtService.getAccessTtlSegundos(),
                usuario.getNombre(), roles(usuario), nuevoSessionId, nuevoDispositivo);
    }

    @Override
    @Transactional
    public TokenResponse cerrarSesionPrevia(CerrarSesionPreviaRequest request) {
        Usuario usuario = usuarioRepository.findByTwoFactorTempToken(request.getTempToken())
                .orElseThrow(ApiException::codigo2FaInvalido);

        if (usuario.getTwoFactorCodigo() == null) {
            throw ApiException.codigo2FaInvalido();
        }

        Verify2FaRequest verifyRequest = new Verify2FaRequest(request.getTempToken(), usuario.getTwoFactorCodigo(), true);
        return verify2Fa(verifyRequest);
    }

    @Override
    @Transactional
    public TokenResponse register(RegisterRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        if (usuarioRepository.findByEmail(email).isPresent()) {
            throw ApiException.emailYaRegistrado();
        }
        Rol rolCliente = rolRepository.findByNombre("CLIENTE")
                .orElseThrow(() -> new IllegalStateException(
                        "No existe el rol CLIENTE. Revisar la migracion R__seed_roles.sql"));

        Usuario usuario = new Usuario();
        usuario.setEmail(email);
        usuario.setNombre(request.getNombre());
        usuario.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        usuario.setActivo(true);
        usuario.setSesionActiva(false);
        usuario.setRoles(Set.of(rolCliente));
        usuarioRepository.save(usuario);

        String access = jwtService.generarAccessToken(usuario);
        String refresh = guardarRefreshToken(usuario);
        log.info("Registro exitoso email={}", email);
        return TokenResponse.ok(access, refresh, jwtService.getAccessTtlSegundos(),
                usuario.getNombre(), roles(usuario));
    }

    @Override
    @Transactional
    public TokenResponse refresh(RefreshRequest request) {
        RefreshToken token = refreshTokenRepository.findByTokenHash(jwtService.hash(request.getRefreshToken()))
                .orElseThrow(ApiException::refreshInvalido);

        if (Boolean.TRUE.equals(token.getRevocado()) || token.getExpiresAt().isBefore(Instant.now())) {
            token.setRevocado(true);
            throw ApiException.refreshInvalido();
        }

        Usuario usuario = token.getUsuario();
        if (!Boolean.TRUE.equals(usuario.getActivo())) {
            token.setRevocado(true);
            throw ApiException.cuentaInactiva();
        }
        if (!Boolean.TRUE.equals(usuario.getSesionActiva())) {
            token.setRevocado(true);
            throw ApiException.authInvalida();
        }

        token.setRevocado(true);
        refreshTokenRepository.save(token);

        String access = jwtService.generarAccessToken(usuario);
        String refresh = guardarRefreshToken(usuario);
        log.info("Refresh exitoso email={}", usuario.getEmail());
        return TokenResponse.ok(access, refresh, jwtService.getAccessTtlSegundos(),
                usuario.getNombre(), roles(usuario));
    }

    @Override
    @Transactional
    public void logout(String refreshToken) {
        logout(null, refreshToken);
    }

    @Override
    @Transactional
    public void logout(String email, String refreshToken) {
        if (refreshToken != null && !refreshToken.isBlank()) {
            refreshTokenRepository.findByTokenHash(jwtService.hash(refreshToken))
                    .ifPresent(t -> t.setRevocado(true));
        }
        if (email != null && !email.isBlank()) {
            usuarioRepository.findByEmail(email).ifPresent(usuario -> {
                usuario.setSesionActiva(false);
                usuario.setDispositivoActivo(null);
                usuario.setSessionIdActivo(null);
                usuarioRepository.save(usuario);
                log.info("[SESION] Sesion activa invalidada en api-gesto-pago para usuario: {}", email);
            });
        }
    }

    @Override
    @Transactional(readOnly = true)
    public ValidarSesionResponse validarSesion(String token) {
        try {
            if (token == null || token.isBlank()) {
                return ValidarSesionResponse.builder().valido(false).mensaje("Token vacío").build();
            }
            if (token.startsWith("Bearer ")) {
                token = token.substring(7);
            }

            Claims claims = jwtService.validarAccessToken(token);
            String email = claims.getSubject();
            String tokenSessionId = claims.get("sessionId", String.class);
            String tokenDispositivo = claims.get("dispositivo", String.class);

            Usuario usuario = usuarioRepository.findByEmail(email).orElse(null);
            if (usuario == null || !Boolean.TRUE.equals(usuario.getActivo())) {
                return ValidarSesionResponse.builder().valido(false).mensaje("Usuario inactivo o inexistente").build();
            }

            boolean sesionInvalida = !Boolean.TRUE.equals(usuario.getSesionActiva())
                    || usuario.getSessionIdActivo() == null
                    || !usuario.getSessionIdActivo().equals(tokenSessionId);

            if (sesionInvalida) {
                return ValidarSesionResponse.builder()
                        .valido(false)
                        .codigo("AUTH-009")
                        .error("SESION_REVOCADA")
                        .mensaje("Se inicio sesion en otro dispositivo.")
                        .dispositivo(usuario.getDispositivoActivo())
                        .build();
            }

            return ValidarSesionResponse.builder()
                    .valido(true)
                    .email(usuario.getEmail())
                    .usuarioId(usuario.getId())
                    .roles(roles(usuario))
                    .dispositivo(tokenDispositivo != null ? tokenDispositivo : usuario.getDispositivoActivo())
                    .sessionId(tokenSessionId)
                    .mensaje("Sesión activa y válida")
                    .build();

        } catch (Exception e) {
            log.warn("Error al validar sesión con token: {}", e.getMessage());
            return ValidarSesionResponse.builder().valido(false).mensaje("Token inválido: " + e.getMessage()).build();
        }
    }

    private String guardarRefreshToken(Usuario usuario) {
        String raw = jwtService.generarRefreshToken();
        RefreshToken token = new RefreshToken();
        token.setUsuario(usuario);
        token.setTokenHash(jwtService.hash(raw));
        token.setExpiresAt(Instant.now().plus(Duration.ofDays(refreshTtlDays)));
        token.setRevocado(false);
        token.setCreatedAt(Instant.now());
        refreshTokenRepository.save(token);
        return raw;
    }

    private List<String> roles(Usuario usuario) {
        return usuario.getRoles().stream()
                .map(Rol::getNombre)
                .sorted()
                .toList();
    }

    private String normalizarDispositivo(String dispositivo) {
        if (dispositivo == null || dispositivo.isBlank()) {
            return "MOVIL";
        }
        return dispositivo.trim().equalsIgnoreCase("WEB") ? "WEB" : "MOVIL";
    }

    private String enmascararCorreo(String correo) {
        int atIndex = correo.indexOf('@');
        if (atIndex <= 2) {
            return correo;
        }
        return correo.substring(0, 2) + "***" + correo.substring(atIndex);
    }
}
