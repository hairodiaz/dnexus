-- Script para LIMPIAR la base de datos de D-Nexus
-- Deja solo el usuario OWNER: hairo (Hernandez14)
-- Ejecuta esto en: https://app.supabase.com/project/[tu-proyecto]/sql/new

-- 1. Limpiar tablas dependientes primero
DELETE FROM audit_logs;
DELETE FROM user_module_permissions;
DELETE FROM transacciones;
DELETE FROM productos;
DELETE FROM clientes;
DELETE FROM negocios;

-- 2. Eliminar todos los usuarios EXCEPTO 'hairo' (owner)
DELETE FROM users WHERE username != 'hairo';

-- 3. Mostrar estado final
SELECT 'Total usuarios' as tipo, COUNT(*) as cantidad FROM users
UNION ALL
SELECT 'Total negocios', COUNT(*) FROM negocios
UNION ALL
SELECT 'Total clientes', COUNT(*) FROM clientes
UNION ALL
SELECT 'Total productos', COUNT(*) FROM productos
UNION ALL
SELECT 'Total transacciones', COUNT(*) FROM transacciones
UNION ALL
SELECT 'Total audit logs', COUNT(*) FROM audit_logs;

-- 4. Verificar usuario hairo
SELECT id, username, nombre_completo, rol, activo FROM users WHERE username = 'hairo';
