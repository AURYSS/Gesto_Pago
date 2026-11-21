-- Migracion V8: Soporte para 2FA y control de sesiones concurrentes (MOVIL vs WEB)
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS sesion_activa BOOLEAN DEFAULT FALSE;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS dispositivo_activo VARCHAR(20);
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS session_id_activo VARCHAR(64);
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS two_factor_codigo VARCHAR(10);
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS two_factor_expiracion TIMESTAMPTZ;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS two_factor_temp_token VARCHAR(64);
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS two_factor_dispositivo VARCHAR(20);
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS fecha_ultimo_acceso TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_usuarios_temp_token ON usuarios (two_factor_temp_token);
