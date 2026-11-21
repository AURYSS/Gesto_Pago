package com.proyecto.servicios.config.security;

import com.proyecto.servicios.entity.auth.Usuario;
import com.proyecto.servicios.repositorys.auth.UsuarioRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
@Slf4j
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String BEARER = "Bearer ";

    private final JwtService jwtService;
    private final UsuarioRepository usuarioRepository;

    public JwtAuthenticationFilter(JwtService jwtService, UsuarioRepository usuarioRepository) {
        this.jwtService = jwtService;
        this.usuarioRepository = usuarioRepository;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (StringUtils.hasText(header) && header.startsWith(BEARER)) {
            String token = header.substring(BEARER.length());
            try {
                Claims claims = jwtService.validarAccessToken(token);
                String email = claims.getSubject();

                // Control de concurrencia: Validar si la sesión sigue activa
                String tokenSessionId = claims.get("sessionId", String.class);
                if (email != null) {
                    Usuario usuario = usuarioRepository.findByEmail(email).orElse(null);
                    if (usuario != null) {
                        boolean sesionInvalida = !Boolean.TRUE.equals(usuario.getSesionActiva())
                                || usuario.getSessionIdActivo() == null
                                || !usuario.getSessionIdActivo().equals(tokenSessionId);
                        if (sesionInvalida) {
                            log.warn("[SESION] Sesion revocada para usuario {}: sessionId del token [{}] != activo [{}]",
                                    email, tokenSessionId, usuario.getSessionIdActivo());
                            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                            response.setContentType("application/json;charset=UTF-8");
                            response.getWriter().write(
                                    "{\"codigo\":\"AUTH-009\",\"error\":\"SESION_REVOCADA\",\"mensaje\":\"Se inicio sesion en otro dispositivo.\"}"
                            );
                            return;
                        }
                    }
                }

                List<SimpleGrantedAuthority> authorities = extraerRoles(claims);
                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(email, null, authorities);
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (JwtException e) {
                log.warn("Token JWT invalido: {}", e.getMessage());
                SecurityContextHolder.clearContext();
            }
        }
        filterChain.doFilter(request, response);
    }

    @SuppressWarnings("unchecked")
    private List<SimpleGrantedAuthority> extraerRoles(Claims claims) {
        List<String> roles = claims.get("roles", List.class);
        return roles == null ? List.of()
                : roles.stream().map(SimpleGrantedAuthority::new).toList();
    }
}
