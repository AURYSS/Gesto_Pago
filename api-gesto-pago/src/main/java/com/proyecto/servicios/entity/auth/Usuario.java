package com.proyecto.servicios.entity.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "usuarios")
@Getter
@Setter
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "email", nullable = false, unique = true, length = 150)
    private String email;

    @Column(name = "password_hash", nullable = false, length = 100)
    private String passwordHash;

    @Column(name = "nombre", nullable = false, length = 150)
    private String nombre;

    @Column(name = "activo", nullable = false)
    private Boolean activo = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    // --- Control de Sesión Única y 2FA ---
    @Column(name = "sesion_activa")
    private Boolean sesionActiva = false;

    @Column(name = "dispositivo_activo", length = 20)
    private String dispositivoActivo;

    @Column(name = "session_id_activo", length = 64)
    private String sessionIdActivo;

    @Column(name = "two_factor_codigo", length = 10)
    private String twoFactorCodigo;

    @Column(name = "two_factor_expiracion")
    private Instant twoFactorExpiracion;

    @Column(name = "two_factor_temp_token", length = 64)
    private String twoFactorTempToken;

    @Column(name = "two_factor_dispositivo", length = 20)
    private String twoFactorDispositivo;

    @Column(name = "fecha_ultimo_acceso")
    private Instant fechaUltimoAcceso;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
            name = "usuario_roles",
            joinColumns = @JoinColumn(name = "usuario_id"),
            inverseJoinColumns = @JoinColumn(name = "rol_id")
    )
    private Set<Rol> roles = new HashSet<>();

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
        updatedAt = Instant.now();
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public boolean esAdmin() {
        return roles.stream().anyMatch(r -> "ADMIN".equals(r.getNombre()));
    }
}