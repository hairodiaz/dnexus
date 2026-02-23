-- Migration: Create Business Management Tables
-- Date: 2026-02-22

-- Tabla de negocios
CREATE TABLE IF NOT EXISTS negocios (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  nit VARCHAR(20),
  fecha_registro DATE,
  estado BOOLEAN DEFAULT true,
  created_by BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para negocios
CREATE INDEX IF NOT EXISTS idx_negocios_created_by ON negocios(created_by);
CREATE INDEX IF NOT EXISTS idx_negocios_estado ON negocios(estado);

-- Tabla de contactos de negocios
CREATE TABLE IF NOT EXISTS negocio_contactos (
  id BIGSERIAL PRIMARY KEY,
  negocio_id BIGINT NOT NULL REFERENCES negocios(id) ON DELETE CASCADE,
  tipo VARCHAR(20) NOT NULL, -- 'telefono' | 'email'
  valor VARCHAR(255) NOT NULL,
  principal BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Índices para contactos
CREATE INDEX IF NOT EXISTS idx_negocio_contactos_negocio_id ON negocio_contactos(negocio_id);
CREATE INDEX IF NOT EXISTS idx_negocio_contactos_tipo ON negocio_contactos(tipo);

-- Tabla de direcciones de negocios
CREATE TABLE IF NOT EXISTS negocio_direcciones (
  id BIGSERIAL PRIMARY KEY,
  negocio_id BIGINT NOT NULL REFERENCES negocios(id) ON DELETE CASCADE,
  tipo VARCHAR(50) NOT NULL, -- 'principal' | 'sucursal' | 'otro'
  calle VARCHAR(255) NOT NULL,
  ciudad VARCHAR(100),
  departamento VARCHAR(100),
  codigo_postal VARCHAR(20),
  principal BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Índices para direcciones
CREATE INDEX IF NOT EXISTS idx_negocio_direcciones_negocio_id ON negocio_direcciones(negocio_id);
CREATE INDEX IF NOT EXISTS idx_negocio_direcciones_principal ON negocio_direcciones(principal);

-- Tabla de relación admin-negocio (para colaboración futura)
CREATE TABLE IF NOT EXISTS admin_negocio (
  admin_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  negocio_id BIGINT NOT NULL REFERENCES negocios(id) ON DELETE CASCADE,
  rol VARCHAR(50) NOT NULL DEFAULT 'propietario', -- 'propietario' | 'editor' | 'lector'
  asignado_en TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (admin_id, negocio_id)
);

-- Índices para admin_negocio
CREATE INDEX IF NOT EXISTS idx_admin_negocio_admin_id ON admin_negocio(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_negocio_negocio_id ON admin_negocio(negocio_id);

-- RLS Policies (Row Level Security)
ALTER TABLE negocios ENABLE ROW LEVEL SECURITY;
ALTER TABLE negocio_contactos ENABLE ROW LEVEL SECURITY;
ALTER TABLE negocio_direcciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_negocio ENABLE ROW LEVEL SECURITY;

-- Policy: Admin puede ver solo sus negocios
CREATE POLICY "admin_see_own_businesses" ON negocios
  FOR SELECT USING (created_by = auth.uid());

-- Policy: Admin puede crear negocios
CREATE POLICY "admin_create_business" ON negocios
  FOR INSERT WITH CHECK (created_by = auth.uid());

-- Policy: Admin puede actualizar sus negocios
CREATE POLICY "admin_update_own_business" ON negocios
  FOR UPDATE USING (created_by = auth.uid());

-- Policy: Admin puede ver contactos de sus negocios
CREATE POLICY "admin_see_own_contacts" ON negocio_contactos
  FOR SELECT USING (
    negocio_id IN (SELECT id FROM negocios WHERE created_by = auth.uid())
  );

-- Policy: Admin puede crear contactos en sus negocios
CREATE POLICY "admin_create_contacts" ON negocio_contactos
  FOR INSERT WITH CHECK (
    negocio_id IN (SELECT id FROM negocios WHERE created_by = auth.uid())
  );

-- Policy: Admin puede eliminar contactos de sus negocios
CREATE POLICY "admin_delete_contacts" ON negocio_contactos
  FOR DELETE USING (
    negocio_id IN (SELECT id FROM negocios WHERE created_by = auth.uid())
  );

-- Similar policies for negocio_direcciones...
CREATE POLICY "admin_see_own_addresses" ON negocio_direcciones
  FOR SELECT USING (
    negocio_id IN (SELECT id FROM negocios WHERE created_by = auth.uid())
  );

CREATE POLICY "admin_create_addresses" ON negocio_direcciones
  FOR INSERT WITH CHECK (
    negocio_id IN (SELECT id FROM negocios WHERE created_by = auth.uid())
  );

CREATE POLICY "admin_delete_addresses" ON negocio_direcciones
  FOR DELETE USING (
    negocio_id IN (SELECT id FROM negocios WHERE created_by = auth.uid())
  );

-- Policies for admin_negocio...
CREATE POLICY "admin_see_own_admin_negocio" ON admin_negocio
  FOR SELECT USING (admin_id = auth.uid());

CREATE POLICY "admin_create_admin_negocio" ON admin_negocio
  FOR INSERT WITH CHECK (admin_id = auth.uid());
