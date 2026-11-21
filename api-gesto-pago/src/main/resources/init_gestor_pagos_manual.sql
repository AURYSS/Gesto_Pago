-- =========================================================================
-- SCRIPT DE INICIALIZACIÓN COMPLETA PARA EL ESQUEMA: gestor_pagos
-- =========================================================================

CREATE SCHEMA IF NOT EXISTS gestor_pagos;
SET search_path TO gestor_pagos, public;

-- 1. Tokens de GestoPago
CREATE TABLE IF NOT EXISTS gestopago_tokens (
    id                  SERIAL PRIMARY KEY,
    id_distribuidor     INTEGER         NOT NULL,
    codigo_dispositivo  VARCHAR(100)    NOT NULL,
    token               TEXT            NOT NULL,
    token_type          VARCHAR(50),
    expires_in          BIGINT,
    fecha_creacion      TIMESTAMP       NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP       NOT NULL DEFAULT NOW(),
    activo              BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_gestopago_tokens UNIQUE (id_distribuidor, codigo_dispositivo)
);

-- 2. Catálogo de versiones y productos
CREATE TABLE IF NOT EXISTS catalogo_versiones (
    id              BIGSERIAL PRIMARY KEY,
    version         INTEGER      NOT NULL,
    estado          VARCHAR(20)  NOT NULL,
    total_productos INTEGER      NOT NULL DEFAULT 0,
    checksum        VARCHAR(64),
    fecha_inicio    TIMESTAMPTZ,
    fecha_fin       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_catalogo_version UNIQUE (version),
    CONSTRAINT ck_catalogo_estado CHECK (estado IN ('EN_CARGA', 'ACTIVA', 'ARCHIVADA', 'FALLIDA'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_catalogo_activa ON catalogo_versiones (estado) WHERE estado = 'ACTIVA';

CREATE TABLE IF NOT EXISTS productos (
    id                     BIGSERIAL PRIMARY KEY,
    version_id             BIGINT        NOT NULL REFERENCES catalogo_versiones (id),
    id_servicio            INTEGER       NOT NULL,
    id_producto            INTEGER       NOT NULL,
    servicio               VARCHAR(256)  NOT NULL,
    producto               VARCHAR(256)  NOT NULL,
    id_cat_tipo_servicio   INTEGER       NOT NULL,
    tipo_front             SMALLINT      NOT NULL,
    tipo_referencia        VARCHAR(3)    NOT NULL,
    precio                 NUMERIC(12, 2) NOT NULL,
    legend                 TEXT,
    has_digito_verificador BOOLEAN       NOT NULL DEFAULT FALSE,
    show_ayuda             BOOLEAN       NOT NULL DEFAULT FALSE,
    activo                 BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at             TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- 3. Usuarios, Roles, 2FA y Sesiones Concurrentes
CREATE TABLE IF NOT EXISTS usuarios (
    id                     BIGSERIAL PRIMARY KEY,
    email                  VARCHAR(150) NOT NULL,
    password_hash          VARCHAR(100) NOT NULL,
    nombre                 VARCHAR(150) NOT NULL,
    activo                 BOOLEAN      NOT NULL DEFAULT TRUE,
    sesion_activa          BOOLEAN      DEFAULT FALSE,
    dispositivo_activo     VARCHAR(20),
    session_id_activo      VARCHAR(64),
    two_factor_codigo      VARCHAR(10),
    two_factor_expiracion  TIMESTAMPTZ,
    two_factor_temp_token  VARCHAR(64),
    two_factor_dispositivo VARCHAR(20),
    fecha_ultimo_acceso    TIMESTAMPTZ,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_usuarios_email UNIQUE (email)
);

CREATE INDEX IF NOT EXISTS idx_usuarios_temp_token ON usuarios (two_factor_temp_token);

CREATE TABLE IF NOT EXISTS roles (
    id     BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    CONSTRAINT uq_roles_nombre UNIQUE (nombre)
);

CREATE TABLE IF NOT EXISTS usuario_roles (
    usuario_id BIGINT NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    rol_id     BIGINT NOT NULL REFERENCES roles (id),
    PRIMARY KEY (usuario_id, rol_id)
);

CREATE INDEX IF NOT EXISTS idx_usuario_roles_rol ON usuario_roles (rol_id);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id         BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT      NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    token_hash VARCHAR(64) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    revocado   BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_refresh_token_hash UNIQUE (token_hash)
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_usuario ON refresh_tokens (usuario_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expira ON refresh_tokens (expires_at);

-- 4. Rate Limiting
CREATE TABLE IF NOT EXISTS rate_limit_hits (
    subject      VARCHAR(150) NOT NULL,
    endpoint     VARCHAR(150) NOT NULL,
    window_start TIMESTAMPTZ  NOT NULL,
    count        INTEGER      NOT NULL DEFAULT 0,
    PRIMARY KEY (subject, endpoint, window_start)
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_window ON rate_limit_hits (window_start);

-- 5. Pagos y Transacciones
CREATE TABLE IF NOT EXISTS transacciones (
    id                  BIGSERIAL PRIMARY KEY,
    usuario_id          BIGINT         NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    id_servicio         INTEGER        NOT NULL,
    id_producto         INTEGER        NOT NULL,
    servicio            VARCHAR(256)   NOT NULL,
    producto            VARCHAR(256)   NOT NULL,
    referencia          VARCHAR(100)   NOT NULL,
    monto               NUMERIC(12, 2) NOT NULL,
    comision            NUMERIC(12, 2) NOT NULL DEFAULT 0,
    estado              VARCHAR(20)    NOT NULL,
    idempotency_key     VARCHAR(36)    NOT NULL,
    upc                 VARCHAR(15),
    unidad              VARCHAR(25),
    numero_autorizacion VARCHAR(60),
    id_tx               VARCHAR(40),
    pin                 TEXT,
    legend              TEXT,
    error_mensaje       TEXT,
    fecha               TIMESTAMPTZ,
    created_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_transacciones_reintento UNIQUE (usuario_id, idempotency_key),
    CONSTRAINT ck_transaccion_estado CHECK (estado IN ('PENDIENTE', 'EN_PROCESO', 'APROBADA', 'FALLIDA', 'RECHAZADA')),
    CONSTRAINT ck_transaccion_monto CHECK (monto > 0)
);

CREATE INDEX IF NOT EXISTS idx_transacciones_usuario_fecha ON transacciones (usuario_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transacciones_estado ON transacciones (estado);

CREATE TABLE IF NOT EXISTS eventos_transaccion (
    id             BIGSERIAL   PRIMARY KEY,
    transaccion_id BIGINT      NOT NULL REFERENCES transacciones (id) ON DELETE CASCADE,
    estado         VARCHAR(20) NOT NULL,
    origen         VARCHAR(30) NOT NULL,
    detalle        TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_eventos_transaccion ON eventos_transaccion (transaccion_id, created_at);

-- 6. Semilla de Roles
INSERT INTO roles (nombre)
VALUES ('CLIENTE'), ('ADMIN')
ON CONFLICT (nombre) DO NOTHING;

-- 7. Usuarios de Prueba con BCrypt
-- admin@prueba.com / linux123#
INSERT INTO usuarios (email, password_hash, nombre, activo)
VALUES (
    'admin@prueba.com',
    '$2a$10$w3v6nCq0xGsmXN40vS2pquqQ1h2B91bVqAecp24HhXz5U83E.mY5S',
    'Administrador',
    TRUE
)
ON CONFLICT (email) DO UPDATE SET activo = TRUE;

-- ceciaurora2017@gmail.com / PasswordSeguro123!
INSERT INTO usuarios (email, password_hash, nombre, activo)
VALUES (
    'ceciaurora2017@gmail.com',
    '$2a$10$CLHMroUEsfkZB.Z//ZXgs.P/8QA9VBRRSLLXNJvNpSykVunmvO3Ma',
    'Cecilia Aurora',
    TRUE
)
ON CONFLICT (email) DO UPDATE SET activo = TRUE;

-- Asignar roles a los usuarios
INSERT INTO usuario_roles (usuario_id, rol_id)
SELECT u.id, r.id FROM usuarios u, roles r
WHERE u.email = 'admin@prueba.com' AND r.nombre IN ('ADMIN', 'CLIENTE')
ON CONFLICT DO NOTHING;

INSERT INTO usuario_roles (usuario_id, rol_id)
SELECT u.id, r.id FROM usuarios u, roles r
WHERE u.email = 'ceciaurora2017@gmail.com' AND r.nombre IN ('ADMIN', 'CLIENTE')
ON CONFLICT DO NOTHING;
