-- Script para agregar políticas RLS faltantes
-- Ejecuta esto en Supabase SQL Editor

-- Para tabla users - agregar políticas UPDATE y DELETE
CREATE POLICY "Enable public update" ON users FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable public delete" ON users FOR DELETE USING (true);

-- Para tabla systems (si existe) - agregar todas las políticas
ALTER TABLE systems ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable public read" ON systems FOR SELECT USING (true);
CREATE POLICY "Enable public write" ON systems FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable public update" ON systems FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable public delete" ON systems FOR DELETE USING (true);

-- Para tabla negocios
CREATE POLICY "Enable public update" ON negocios FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable public delete" ON negocios FOR DELETE USING (true);

-- Para tabla clientes
CREATE POLICY "Enable public update" ON clientes FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable public delete" ON clientes FOR DELETE USING (true);

-- Para tabla productos
CREATE POLICY "Enable public update" ON productos FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable public delete" ON productos FOR DELETE USING (true);

-- Para tabla transacciones
CREATE POLICY "Enable public update" ON transacciones FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Enable public delete" ON transacciones FOR DELETE USING (true);
