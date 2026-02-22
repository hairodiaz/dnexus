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

-- Tabla de clientes (GLOBAL - compartido entre tous les negocios)
CREATE TABLE IF NOT EXISTS clientes (
  id BIGSERIAL PRIMARY KEY,
  numero_documento VARCHAR(50) UNIQUE NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  telefono VARCHAR(20),
  direccion TEXT,
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
-- Tabla de módulos del sistema (para SuperAdmin)
CREATE TABLE IF NOT EXISTS system_modules (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de auditoría para registrar acciones delicadas
CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGSERIAL PRIMARY KEY,
  usuario_id BIGINT REFERENCES users(id),
  nombre_usuario VARCHAR(255),
  tipo VARCHAR(100), -- 'crear_usuario', 'crear_negocio', 'crear_empleado', etc.
  descripcion TEXT,
  detalles JSONB, -- Detalles adicionales en JSON
  estado VARCHAR(50) DEFAULT 'exitoso', -- 'exitoso', 'error'
  motivo TEXT, -- Razón si falló
  fecha_hora TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);
-- Insertar usuario SuperAdmin
-- Password: 123456 (SHA256: 8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92)
INSERT INTO users (username, password, email, nombre_completo, rol, activo)
VALUES ('superadmin', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'admin@dnexus.com', 'Super Administrador', 'superadmin', true)
ON CONFLICT (username) DO NOTHING;

-- Insertar usuario de prueba: Owner
-- Password: Hernandez14 (SHA256: f9c1796c5bb5379b8d64fb832ff5022ff46278b1b0392e9a3b1a97931fe3f337)
INSERT INTO users (username, password, email, nombre_completo, rol, activo)
VALUES ('hairo', 'f9c1796c5bb5379b8d64fb832ff5022ff46278b1b0392e9a3b1a97931fe3f337', 'hairo@dnexus.local', 'Hairo Diaz', 'owner', true)
ON CONFLICT (username) DO NOTHING;

-- Insertar usuario de prueba: Admin
-- Password: admin123 (SHA256: 240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9)
INSERT INTO users (username, password, email, nombre_completo, rol, activo)
VALUES ('admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'admin@dnexus.local', 'Administrador', 'super_admin', true)
ON CONFLICT (username) DO NOTHING;

-- Tabla de permisos de módulos por usuario
CREATE TABLE IF NOT EXISTS user_module_permissions (
  id BIGSERIAL PRIMARY KEY,
  usuario_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  modulo_id BIGINT NOT NULL REFERENCES system_modules(id) ON DELETE CASCADE,
  habilitado BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(usuario_id, modulo_id)
);

-- Insertar módulos del sistema
INSERT INTO system_modules (nombre, descripcion, activo)
VALUES 
  ('Cash Register', 'Módulo de caja registradora', true),
  ('Inventario', 'Gestión de productos e inventario', true),
  ('Facturas', 'Creación y gestión de facturas', true),
  ('Empleados', 'Gestión de empleados y permisos', true),
  ('Contabilidad', 'Módulo contable y reportes', true),
  ('Reportes', 'Reportes y análisis del sistema', true)
ON CONFLICT (nombre) DO NOTHING;

-- Crear índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_clientes_documento ON clientes(numero_documento);
CREATE INDEX IF NOT EXISTS idx_productos_negocio ON productos(negocio_id);
CREATE INDEX IF NOT EXISTS idx_transacciones_negocio ON transacciones(negocio_id);
CREATE INDEX IF NOT EXISTS idx_transacciones_cliente ON transacciones(cliente_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_fecha ON audit_logs(fecha_hora DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_usuario ON audit_logs(usuario_id);

-- Enable RLS (Row Level Security) - IMPORTANTE para seguridad
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE negocios ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE transacciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_module_permissions ENABLE ROW LEVEL SECURITY;

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
CREATE POLICY "Allow all user_module_permissions" ON user_module_permissions FOR ALL USING (true);
