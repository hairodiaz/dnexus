-- Script para crear tabla de relación admin_sistemas
-- Ejecuta esto en Supabase SQL Editor

-- Crear tabla de relación admin_sistemas
CREATE TABLE IF NOT EXISTS admin_sistemas (
  id BIGSERIAL PRIMARY KEY,
  admin_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sistema VARCHAR(50) NOT NULL CHECK (sistema IN ('repuestos', 'prestamos', 'inmuebles')),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(admin_id, sistema)
);

-- Agregar índice para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_admin_sistemas_admin_id ON admin_sistemas(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_sistemas_sistema ON admin_sistemas(sistema);

-- Migrar datos existentes de la columna sistema (si existen)
INSERT INTO admin_sistemas (admin_id, sistema)
SELECT id, sistema FROM users 
WHERE sistema IS NOT NULL AND rol = 'admin_negocio'
ON CONFLICT (admin_id, sistema) DO NOTHING;

-- Habilitar RLS
ALTER TABLE admin_sistemas ENABLE ROW LEVEL SECURITY;

-- Crear políticas RLS para admin_sistemas
CREATE POLICY "Enable public read" ON admin_sistemas FOR SELECT USING (true);
CREATE POLICY "Enable public write" ON admin_sistemas FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable public update" ON admin_sistemas FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable public delete" ON admin_sistemas FOR DELETE USING (true);
