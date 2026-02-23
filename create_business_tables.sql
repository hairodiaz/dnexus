-- Migration: Create Business Management Tables
-- Date: 2026-02-22

-- Tabla de negocios
CREATE TABLE IF NOT EXISTS negocios (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  nit VARCHAR(20),
  fecha_registro DATE,
  estado BOOLEAN DEFAULT true,
  created_by BIGINT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT fk_negocios_created_by FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE
);

-- Índices para negocios
CREATE INDEX IF NOT EXISTS idx_negocios_created_by ON negocios(created_by);
CREATE INDEX IF NOT EXISTS idx_negocios_estado ON negocios(estado);

-- Tabla de contactos de negocios
CREATE TABLE IF NOT EXISTS negocio_contactos (
  id BIGSERIAL PRIMARY KEY,
  negocio_id BIGINT NOT NULL,
  tipo VARCHAR(20) NOT NULL,
  valor VARCHAR(255) NOT NULL,
  principal BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT fk_negocio_contactos_negocio_id FOREIGN KEY (negocio_id) REFERENCES public.negocios(id) ON DELETE CASCADE
);

-- Índices para contactos
CREATE INDEX IF NOT EXISTS idx_negocio_contactos_negocio_id ON negocio_contactos(negocio_id);
CREATE INDEX IF NOT EXISTS idx_negocio_contactos_tipo ON negocio_contactos(tipo);

-- Tabla de direcciones de negocios
CREATE TABLE IF NOT EXISTS negocio_direcciones (
  id BIGSERIAL PRIMARY KEY,
  negocio_id BIGINT NOT NULL,
  tipo VARCHAR(50) NOT NULL,
  calle VARCHAR(255) NOT NULL,
  ciudad VARCHAR(100),
  departamento VARCHAR(100),
  codigo_postal VARCHAR(20),
  principal BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT fk_negocio_direcciones_negocio_id FOREIGN KEY (negocio_id) REFERENCES public.negocios(id) ON DELETE CASCADE
);

-- Índices para direcciones
CREATE INDEX IF NOT EXISTS idx_negocio_direcciones_negocio_id ON negocio_direcciones(negocio_id);
CREATE INDEX IF NOT EXISTS idx_negocio_direcciones_principal ON negocio_direcciones(principal);

-- Tabla de relación admin-negocio (para colaboración futura)
CREATE TABLE IF NOT EXISTS admin_negocio (
  admin_id BIGINT NOT NULL,
  negocio_id BIGINT NOT NULL,
  rol VARCHAR(50) NOT NULL DEFAULT 'propietario',
  asignado_en TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (admin_id, negocio_id),
  CONSTRAINT fk_admin_negocio_admin_id FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT fk_admin_negocio_negocio_id FOREIGN KEY (negocio_id) REFERENCES public.negocios(id) ON DELETE CASCADE
);

-- Índices para admin_negocio
CREATE INDEX IF NOT EXISTS idx_admin_negocio_admin_id ON admin_negocio(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_negocio_negocio_id ON admin_negocio(negocio_id);

-- RLS Policies (Row Level Security)
-- Nota: Las policies se generarán cuando implementes JWT con ID numérico
-- Por ahora, desactiva RLS en Supabase o crea un trigger personalizado
-- ALTER TABLE negocios ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE negocio_contactos ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE negocio_direcciones ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE admin_negocio ENABLE ROW LEVEL SECURITY;
