-- Migration: RBAC (Role-Based Access Control) para Sistema Repuestos
-- Crea tablas de roles, permisos y sus relaciones

-- Tabla de Roles para Repuestos
CREATE TABLE IF NOT EXISTS roles_repuestos (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  descripcion TEXT,
  sistema VARCHAR(50) DEFAULT 'repuestos',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(nombre, sistema)
);

-- Tabla de Permisos para Repuestos
CREATE TABLE IF NOT EXISTS permissions_repuestos (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  descripcion TEXT,
  modulo VARCHAR(50), -- dashboard, inventario, usuarios, reportes, etc
  sistema VARCHAR(50) DEFAULT 'repuestos',
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(nombre, sistema)
);

-- Tabla de relación Roles-Permisos
CREATE TABLE IF NOT EXISTS role_permissions_repuestos (
  id BIGSERIAL PRIMARY KEY,
  role_id BIGINT NOT NULL REFERENCES roles_repuestos(id) ON DELETE CASCADE,
  permission_id BIGINT NOT NULL REFERENCES permissions_repuestos(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(role_id, permission_id)
);

-- Tabla de relación Usuarios-Roles
CREATE TABLE IF NOT EXISTS user_roles_repuestos (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id BIGINT NOT NULL REFERENCES roles_repuestos(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, role_id)
);

-- Crear índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_roles_repuestos_nombre ON roles_repuestos(nombre);
CREATE INDEX IF NOT EXISTS idx_permissions_repuestos_nombre ON permissions_repuestos(nombre);
CREATE INDEX IF NOT EXISTS idx_permissions_repuestos_modulo ON permissions_repuestos(modulo);
CREATE INDEX IF NOT EXISTS idx_role_permissions_repuestos_role_id ON role_permissions_repuestos(role_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_repuestos_user_id ON user_roles_repuestos(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_repuestos_role_id ON user_roles_repuestos(role_id);

-- Habilitar RLS
ALTER TABLE roles_repuestos ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions_repuestos ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions_repuestos ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles_repuestos ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para roles_repuestos (permitir lectura y escritura públicas por ahora)
CREATE POLICY "Enable public read" ON roles_repuestos FOR SELECT USING (true);
CREATE POLICY "Enable public write" ON roles_repuestos FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable public update" ON roles_repuestos FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable public delete" ON roles_repuestos FOR DELETE USING (true);

-- Políticas RLS para permissions_repuestos
CREATE POLICY "Enable public read" ON permissions_repuestos FOR SELECT USING (true);
CREATE POLICY "Enable public write" ON permissions_repuestos FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable public update" ON permissions_repuestos FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable public delete" ON permissions_repuestos FOR DELETE USING (true);

-- Políticas RLS para role_permissions_repuestos
CREATE POLICY "Enable public read" ON role_permissions_repuestos FOR SELECT USING (true);
CREATE POLICY "Enable public write" ON role_permissions_repuestos FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable public update" ON role_permissions_repuestos FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable public delete" ON role_permissions_repuestos FOR DELETE USING (true);

-- Políticas RLS para user_roles_repuestos
CREATE POLICY "Enable public read" ON user_roles_repuestos FOR SELECT USING (true);
CREATE POLICY "Enable public write" ON user_roles_repuestos FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable public update" ON user_roles_repuestos FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable public delete" ON user_roles_repuestos FOR DELETE USING (true);

-- Insertar Permisos predefinidos para Repuestos
INSERT INTO permissions_repuestos (nombre, descripcion, modulo, sistema) VALUES
  -- Dashboard
  ('view_dashboard', 'Ver panel de control', 'dashboard', 'repuestos'),
  
  -- Inventario
  ('view_inventory', 'Ver inventario de productos', 'inventario', 'repuestos'),
  ('create_product', 'Crear nuevos productos', 'inventario', 'repuestos'),
  ('edit_product', 'Editar productos', 'inventario', 'repuestos'),
  ('delete_product', 'Eliminar productos', 'inventario', 'repuestos'),
  ('manage_stock', 'Gestionar stock de productos', 'inventario', 'repuestos'),
  
  -- Categorías
  ('view_categories', 'Ver categorías', 'categorias', 'repuestos'),
  ('create_category', 'Crear categorías', 'categorias', 'repuestos'),
  ('edit_category', 'Editar categorías', 'categorias', 'repuestos'),
  ('delete_category', 'Eliminar categorías', 'categorias', 'repuestos'),
  
  -- Clientes
  ('view_customers', 'Ver clientes', 'clientes', 'repuestos'),
  ('create_customer', 'Crear clientes', 'clientes', 'repuestos'),
  ('edit_customer', 'Editar clientes', 'clientes', 'repuestos'),
  ('delete_customer', 'Eliminar clientes', 'clientes', 'repuestos'),
  
  -- Ventas/Caja
  ('view_sales', 'Ver ventas', 'ventas', 'repuestos'),
  ('create_sale', 'Crear ventas', 'ventas', 'repuestos'),
  ('process_payment', 'Procesar pagos', 'ventas', 'repuestos'),
  
  -- Reportes
  ('view_reports', 'Ver reportes', 'reportes', 'repuestos'),
  ('export_reports', 'Exportar reportes', 'reportes', 'repuestos'),
  
  -- Administración
  ('manage_users', 'Gestionar usuarios del sistema', 'administracion', 'repuestos'),
  ('manage_roles', 'Gestionar roles y permisos', 'administracion', 'repuestos')
ON CONFLICT (nombre, sistema) DO NOTHING;

-- Insertar Roles predefinidos
INSERT INTO roles_repuestos (nombre, descripcion, sistema) VALUES
  ('Gerente', 'Acceso total al sistema', 'repuestos'),
  ('Cajero', 'Gestión de ventas y pagos', 'repuestos'),
  ('Almacenero', 'Gestión de inventario y stock', 'repuestos'),
  ('Vendedor', 'Crear y consultar ventas', 'repuestos'),
  ('Supervisor', 'Visualización de reportes y control', 'repuestos')
ON CONFLICT (nombre, sistema) DO NOTHING;

-- Asignar permisos a Gerente (todos)
INSERT INTO role_permissions_repuestos (role_id, permission_id)
SELECT r.id, p.id FROM roles_repuestos r, permissions_repuestos p 
WHERE r.nombre = 'Gerente' AND p.sistema = 'repuestos'
ON CONFLICT DO NOTHING;

-- Asignar permisos a Cajero
INSERT INTO role_permissions_repuestos (role_id, permission_id)
SELECT r.id, p.id FROM roles_repuestos r, permissions_repuestos p 
WHERE r.nombre = 'Cajero' AND p.sistema = 'repuestos'
AND p.nombre IN ('view_dashboard', 'view_sales', 'create_sale', 'process_payment', 'create_customer', 'view_customers')
ON CONFLICT DO NOTHING;

-- Asignar permisos a Almacenero
INSERT INTO role_permissions_repuestos (role_id, permission_id)
SELECT r.id, p.id FROM roles_repuestos r, permissions_repuestos p 
WHERE r.nombre = 'Almacenero' AND p.sistema = 'repuestos'
AND p.nombre IN ('view_dashboard', 'view_inventory', 'manage_stock', 'view_categories', 'view_products')
ON CONFLICT DO NOTHING;

-- Asignar permisos a Vendedor
INSERT INTO role_permissions_repuestos (role_id, permission_id)
SELECT r.id, p.id FROM roles_repuestos r, permissions_repuestos p 
WHERE r.nombre = 'Vendedor' AND p.sistema = 'repuestos'
AND p.nombre IN ('view_dashboard', 'view_sales', 'create_sale', 'view_inventory', 'view_customers', 'create_customer')
ON CONFLICT DO NOTHING;

-- Asignar permisos a Supervisor
INSERT INTO role_permissions_repuestos (role_id, permission_id)
SELECT r.id, p.id FROM roles_repuestos r, permissions_repuestos p 
WHERE r.nombre = 'Supervisor' AND p.sistema = 'repuestos'
AND p.nombre IN ('view_dashboard', 'view_sales', 'view_inventory', 'view_reports', 'view_categories', 'view_customers')
ON CONFLICT DO NOTHING;
