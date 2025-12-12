-- Script para crear tablas en Supabase
-- Ejecuta esto en: https://app.supabase.com/project/[tu-proyecto]/sql/new

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  nombre_completo VARCHAR(255),
  rol VARCHAR(50),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de negocios
CREATE TABLE IF NOT EXISTS negocios (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  tipo VARCHAR(100),
  descripcion TEXT,
  propietario_id BIGINT REFERENCES users(id),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de clientes
CREATE TABLE IF NOT EXISTS clientes (
  id BIGSERIAL PRIMARY KEY,
  cedula VARCHAR(20) UNIQUE,
  nombre_completo VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  telefono VARCHAR(20),
  direccion TEXT,
  negocio_id BIGINT REFERENCES negocios(id),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de productos
CREATE TABLE IF NOT EXISTS productos (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  codigo VARCHAR(100) UNIQUE,
  precio DECIMAL(10, 2),
  stock INTEGER DEFAULT 0,
  negocio_id BIGINT REFERENCES negocios(id),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de transacciones
CREATE TABLE IF NOT EXISTS transacciones (
  id BIGSERIAL PRIMARY KEY,
  tipo VARCHAR(50),
  monto DECIMAL(10, 2),
  concepto VARCHAR(255),
  categoria VARCHAR(100),
  metodo_pago VARCHAR(100),
  cliente_id BIGINT REFERENCES clientes(id),
  negocio_id BIGINT REFERENCES negocios(id),
  fecha TIMESTAMP DEFAULT NOW(),
  observaciones TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Insertar usuario SuperAdmin
INSERT INTO users (username, password, email, nombre_completo, rol, activo)
VALUES ('superadmin', '123456', 'admin@dnexus.com', 'Super Administrador', 'superadmin', true)
ON CONFLICT (username) DO NOTHING;

-- Crear índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_clientes_negocio ON clientes(negocio_id);
CREATE INDEX IF NOT EXISTS idx_productos_negocio ON productos(negocio_id);
CREATE INDEX IF NOT EXISTS idx_transacciones_negocio ON transacciones(negocio_id);
CREATE INDEX IF NOT EXISTS idx_transacciones_cliente ON transacciones(cliente_id);

-- Enable RLS (Row Level Security) - IMPORTANTE para seguridad
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE negocios ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE transacciones ENABLE ROW LEVEL SECURITY;

-- Crear políticas públicas para desarrollo (CAMBIAR EN PRODUCCIÓN)
CREATE POLICY "Allow all for public users" ON users FOR SELECT USING (true);
CREATE POLICY "Allow all for public negocios" ON negocios FOR SELECT USING (true);
CREATE POLICY "Allow all for public clientes" ON clientes FOR SELECT USING (true);
CREATE POLICY "Allow all for public productos" ON productos FOR SELECT USING (true);
CREATE POLICY "Allow all for public transacciones" ON transacciones FOR SELECT USING (true);

-- Permitir inserts
CREATE POLICY "Allow insert users" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow insert clientes" ON clientes FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow insert productos" ON productos FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow insert transacciones" ON transacciones FOR INSERT WITH CHECK (true);
