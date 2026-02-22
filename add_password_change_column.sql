-- Agregar columna password_needs_change a la tabla users
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_needs_change BOOLEAN DEFAULT false;

-- Comentario en la columna
COMMENT ON COLUMN users.password_needs_change IS 'Indica si el usuario debe cambiar su contraseña en el próximo login (para admins recién creados)';
