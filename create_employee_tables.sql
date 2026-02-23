-- Migration: Create Employee Management Tables
-- Date: 2026-02-23

-- Tabla de empleados
CREATE TABLE IF NOT EXISTS empleados (
  id BIGSERIAL PRIMARY KEY,
  negocio_id BIGINT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  numero_documento VARCHAR(50),
  email VARCHAR(255),
  telefono VARCHAR(20),
  cargo VARCHAR(100),
  estado BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT fk_empleados_negocio_id FOREIGN KEY (negocio_id) REFERENCES public.negocios(id) ON DELETE CASCADE,
  CONSTRAINT uk_empleados_documento UNIQUE (numero_documento)
);

-- Índices para empleados
CREATE INDEX IF NOT EXISTS idx_empleados_negocio_id ON empleados(negocio_id);
CREATE INDEX IF NOT EXISTS idx_empleados_estado ON empleados(estado);
CREATE INDEX IF NOT EXISTS idx_empleados_numero_documento ON empleados(numero_documento);

-- Tabla de relación empleado-usuario (para login opcional)
CREATE TABLE IF NOT EXISTS empleado_usuarios (
  empleado_id BIGINT NOT NULL,
  usuario_id BIGINT NOT NULL,
  asignado_en TIMESTAMP DEFAULT NOW(),
  CONSTRAINT fk_empleado_usuarios_empleado_id FOREIGN KEY (empleado_id) REFERENCES public.empleados(id) ON DELETE CASCADE,
  CONSTRAINT fk_empleado_usuarios_usuario_id FOREIGN KEY (usuario_id) REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT uk_empleado_usuarios_empleado_id UNIQUE (empleado_id),
  CONSTRAINT uk_empleado_usuarios_usuario_id UNIQUE (usuario_id),
  PRIMARY KEY (empleado_id, usuario_id)
);

-- Índices para empleado_usuarios
CREATE INDEX IF NOT EXISTS idx_empleado_usuarios_empleado_id ON empleado_usuarios(empleado_id);
CREATE INDEX IF NOT EXISTS idx_empleado_usuarios_usuario_id ON empleado_usuarios(usuario_id);

-- Tabla de roles (por negocio)
CREATE TABLE IF NOT EXISTS roles (
  id BIGSERIAL PRIMARY KEY,
  negocio_id BIGINT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  estado BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT fk_roles_negocio_id FOREIGN KEY (negocio_id) REFERENCES public.negocios(id) ON DELETE CASCADE
);

-- Índices para roles
CREATE INDEX IF NOT EXISTS idx_roles_negocio_id ON roles(negocio_id);
CREATE INDEX IF NOT EXISTS idx_roles_estado ON roles(estado);

-- Tabla de relación empleado-roles
CREATE TABLE IF NOT EXISTS empleado_roles (
  empleado_id BIGINT NOT NULL,
  role_id BIGINT NOT NULL,
  asignado_en TIMESTAMP DEFAULT NOW(),
  CONSTRAINT fk_empleado_roles_empleado_id FOREIGN KEY (empleado_id) REFERENCES public.empleados(id) ON DELETE CASCADE,
  CONSTRAINT fk_empleado_roles_role_id FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE,
  PRIMARY KEY (empleado_id, role_id)
);

-- Índices para empleado_roles
CREATE INDEX IF NOT EXISTS idx_empleado_roles_empleado_id ON empleado_roles(empleado_id);
CREATE INDEX IF NOT EXISTS idx_empleado_roles_role_id ON empleado_roles(role_id);

-- Sistema de módulos disponibles por sistema
CREATE TABLE IF NOT EXISTS system_modules (
  id BIGSERIAL PRIMARY KEY,
  sistema VARCHAR(50) NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  ruta VARCHAR(255),
  icono VARCHAR(100),
  estado BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de relación rol-módulos
CREATE TABLE IF NOT EXISTS role_modulos (
  role_id BIGINT NOT NULL,
  modulo_id BIGINT NOT NULL,
  asignado_en TIMESTAMP DEFAULT NOW(),
  CONSTRAINT fk_role_modulos_role_id FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE,
  CONSTRAINT fk_role_modulos_modulo_id FOREIGN KEY (modulo_id) REFERENCES public.system_modules(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, modulo_id)
);

-- Índices para role_modulos
CREATE INDEX IF NOT EXISTS idx_role_modulos_role_id ON role_modulos(role_id);
CREATE INDEX IF NOT EXISTS idx_role_modulos_modulo_id ON role_modulos(modulo_id);

-- Agregar columnas faltantes a system_modules
ALTER TABLE IF EXISTS system_modules ADD COLUMN IF NOT EXISTS sistema VARCHAR(50);
ALTER TABLE IF EXISTS system_modules ADD COLUMN IF NOT EXISTS ruta VARCHAR(255);
ALTER TABLE IF EXISTS system_modules ADD COLUMN IF NOT EXISTS icono VARCHAR(100);
ALTER TABLE IF EXISTS system_modules ADD COLUMN IF NOT EXISTS estado BOOLEAN DEFAULT true;

-- Insertar módulos por defecto (ignorar duplicados)
INSERT INTO system_modules (sistema, nombre, descripcion, ruta, icono, estado) VALUES
-- Repuesto system
('Repuesto', 'Inventario', 'Gestión de inventario de repuestos', '/repuesto/inventario', 'inventory', true),
('Repuesto', 'Proveedores', 'Gestión de proveedores y órdenes de compra', '/repuesto/proveedores', 'people', true),
('Repuesto', 'Ventas', 'Registro y gestión de ventas', '/repuesto/ventas', 'shopping_cart', true),
('Repuesto', 'Reportes', 'Reportes de inventario y ventas', '/repuesto/reportes', 'bar_chart', true),

-- Prestamo system
('Prestamo', 'Préstamos', 'Gestión de préstamos', '/prestamo/prestamos', 'money', true),
('Prestamo', 'Clientes', 'Gestión de clientes', '/prestamo/clientes', 'people', true),
('Prestamo', 'Pagos', 'Registro de pagos', '/prestamo/pagos', 'payment', true),
('Prestamo', 'Reportes', 'Reportes de préstamos y pagos', '/prestamo/reportes', 'bar_chart', true),

-- Inmuebles system
('Inmuebles', 'Propiedades', 'Gestión de propiedades', '/inmuebles/propiedades', 'home', true),
('Inmuebles', 'Inquilinos', 'Gestión de inquilinos', '/inmuebles/inquilinos', 'people', true),
('Inmuebles', 'Arriendos', 'Registro de arriendos', '/inmuebles/arriendos', 'calendar_today', true),
('Inmuebles', 'Reportes', 'Reportes de propiedades y arriendos', '/inmuebles/reportes', 'bar_chart', true)
ON CONFLICT (nombre) DO NOTHING;
