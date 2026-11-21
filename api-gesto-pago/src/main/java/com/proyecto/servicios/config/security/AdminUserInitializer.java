package com.proyecto.servicios.config.security;

import com.proyecto.servicios.entity.auth.Rol;
import com.proyecto.servicios.entity.auth.Usuario;
import com.proyecto.servicios.repositorys.auth.RolRepository;
import com.proyecto.servicios.repositorys.auth.UsuarioRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.Set;

@Component
@Slf4j
public class AdminUserInitializer implements CommandLineRunner {

    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${security.admin.email:}")
    private String adminEmail;

    @Value("${security.admin.password:}")
    private String adminPassword;

    @Value("${security.admin.nombre:Administrador}")
    private String adminNombre;

    public AdminUserInitializer(UsuarioRepository usuarioRepository,
                                RolRepository rolRepository,
                                PasswordEncoder passwordEncoder) {
        this.usuarioRepository = usuarioRepository;
        this.rolRepository = rolRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) {
        Rol admin = rolRepository.findByNombre("ADMIN")
                .orElseThrow(() -> new IllegalStateException(
                        "No existe el rol ADMIN. Revisar la migracion R__seed_roles.sql"));
        Rol cliente = rolRepository.findByNombre("CLIENTE")
                .orElseThrow(() -> new IllegalStateException(
                        "No existe el rol CLIENTE. Revisar la migracion R__seed_roles.sql"));

        // 1. Inicializar Administrador
        if (StringUtils.hasText(adminEmail) && StringUtils.hasText(adminPassword)) {
            crearOActivarUsuario(
                    adminEmail.trim().toLowerCase(),
                    adminPassword,
                    adminNombre,
                    Set.of(admin, cliente)
            );
        }

        // 2. Inicializar Usuario de prueba del sistema (Cecilia Aurora)
        crearOActivarUsuario(
                "ceciaurora2017@gmail.com",
                "PasswordSeguro123!",
                "Cecilia Aurora",
                Set.of(cliente, admin)
        );
    }

    private void crearOActivarUsuario(String email, String password, String nombre, Set<Rol> roles) {
        usuarioRepository.findByEmail(email).ifPresentOrElse(
                u -> {
                    boolean modificado = false;
                    if (!Boolean.TRUE.equals(u.getActivo())) {
                        u.setActivo(true);
                        modificado = true;
                    }
                    if (u.getRoles() == null || u.getRoles().isEmpty()) {
                        u.setRoles(roles);
                        modificado = true;
                    }
                    if (!passwordEncoder.matches(password, u.getPasswordHash())) {
                        u.setPasswordHash(passwordEncoder.encode(password));
                        modificado = true;
                        log.info("[AUTH] Contrasena actualizada para usuario de prueba: {}", email);
                    }
                    if (modificado) {
                        usuarioRepository.save(u);
                        log.info("Usuario reactivado/actualizado: {}", email);
                    } else {
                        log.info("Usuario ya existe y se encuentra activo: {}", email);
                    }
                },
                () -> {
                    Usuario nuevo = new Usuario();
                    nuevo.setEmail(email);
                    nuevo.setPasswordHash(passwordEncoder.encode(password));
                    nuevo.setNombre(nombre);
                    nuevo.setActivo(true);
                    nuevo.setRoles(roles);
                    usuarioRepository.save(nuevo);
                    log.info("Usuario inicial creado exitosamente: {} ({})", email, nombre);
                }
        );
    }
}