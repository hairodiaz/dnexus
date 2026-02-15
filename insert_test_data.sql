-- Insert test user for development
-- Password: Hernandez14 (SHA256 hashed)
-- SHA256 hash: 24b3f1e3f37b0a0d8b8d8b3e5c9d2f1a8c0e2d9f7a5b3c1d

INSERT INTO users (username, password, email, nombre_completo, rol, activo)
VALUES ('hairo', '24b3f1e3f37b0a0d8b8d8b3e5c9d2f1a8c0e2d9f', 'hairo@dnexus.local', 'Hairo Diaz', 'owner', true)
ON CONFLICT (username) DO NOTHING;

-- Insert admin user for development
-- Password: admin123 (SHA256 hashed)
-- SHA256 hash: 0192023a7bbd73250516f069df18b500

INSERT INTO users (username, password, email, nombre_completo, rol, activo)
VALUES ('admin', '0192023a7bbd73250516f069df18b500', 'admin@dnexus.local', 'Administrador', 'super_admin', true)
ON CONFLICT (username) DO NOTHING;
