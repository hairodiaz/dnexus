-- Insertar o actualizar usuario Owner
-- Ejecutar en Supabase SQL Editor

INSERT INTO usuarios (username, password, email, nombre_completo, rol, activo)
VALUES ('hairo', 'f9c1796c5bb5379b8d64fb832ff5022ff46278b1b0392e9a3b1a97931fe3f337', 'hairo@owner.local', 'Hairo Owner', 'owner', true)
ON CONFLICT (username) 
DO UPDATE SET 
  password = 'f9c1796c5bb5379b8d64fb832ff5022ff46278b1b0392e9a3b1a97931fe3f337',
  rol = 'owner',
  activo = true
WHERE usuarios.username = 'hairo';
