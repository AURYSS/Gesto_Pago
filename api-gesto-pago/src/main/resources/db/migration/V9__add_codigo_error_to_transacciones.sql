-- Migracion V9: Agregar codigo_error a la tabla transacciones para detalle de errores de proveedor y validacion
ALTER TABLE transacciones ADD COLUMN IF NOT EXISTS codigo_error VARCHAR(50);
