import 'package:postgres/postgres.dart';
import 'migration.dart';

/// Migration 001: Crear todas las tablas iniciales para D-Nexus
class CreateInitialTablesMigration extends Migration {
  @override
  int get version => 1;
  
  @override
  String get description => 'Create initial tables: usuarios, negocios, modulos, transacciones, permisos';
  
  @override
  Future<void> up(TxSession ctx) async {
    // Crear tabla usuarios
    await execute(ctx, '''
      CREATE TABLE usuarios (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        nombre_completo VARCHAR(100) NOT NULL,
        rol_sistema VARCHAR(20) DEFAULT 'usuario' CHECK (rol_sistema IN ('super_admin', 'admin_negocio', 'usuario')),
        activo BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');    // Crear tabla negocios
    await execute(ctx, '''
      CREATE TABLE negocios (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('repuestos', 'prestamos', 'electrodomesticos')),
        descripcion TEXT,
        propietario_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
        activo BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // Crear tabla modulos
    await execute(ctx, '''
      CREATE TABLE modulos (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        codigo VARCHAR(50) UNIQUE NOT NULL,
        descripcion TEXT,
        icono VARCHAR(50),
        activo BOOLEAN DEFAULT true,
        version VARCHAR(20) DEFAULT '1.0',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // Crear tabla negocio_modulos (qué módulos tiene cada negocio)
    await execute(ctx, '''
      CREATE TABLE negocio_modulos (
        id SERIAL PRIMARY KEY,
        negocio_id INTEGER REFERENCES negocios(id) ON DELETE CASCADE,
        modulo_id INTEGER REFERENCES modulos(id) ON DELETE CASCADE,
        activo BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(negocio_id, modulo_id)
      );
    ''');

    // Crear tabla usuario_negocio_permisos
    await execute(ctx, '''
      CREATE TABLE usuario_negocio_permisos (
        id SERIAL PRIMARY KEY,
        usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
        negocio_id INTEGER REFERENCES negocios(id) ON DELETE CASCADE,
        rol VARCHAR(20) NOT NULL CHECK (rol IN ('propietario', 'admin', 'editor', 'viewer', 'contador')),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(usuario_id, negocio_id)
      );
    ''');

    // Crear tabla usuario_modulo_permisos
    await execute(ctx, '''
      CREATE TABLE usuario_modulo_permisos (
        id SERIAL PRIMARY KEY,
        usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
        negocio_id INTEGER REFERENCES negocios(id) ON DELETE CASCADE,
        modulo_id INTEGER REFERENCES modulos(id) ON DELETE CASCADE,
        permisos JSONB DEFAULT '{}',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(usuario_id, negocio_id, modulo_id)
      );
    ''');

    // Crear tabla transacciones
    await execute(ctx, '''
      CREATE TABLE transacciones (
        id SERIAL PRIMARY KEY,
        negocio_id INTEGER REFERENCES negocios(id) ON DELETE CASCADE,
        usuario_id INTEGER REFERENCES usuarios(id) ON DELETE SET NULL,
        concepto VARCHAR(200) NOT NULL,
        monto DECIMAL(12,2) NOT NULL,
        tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('ingreso', 'egreso')),
        categoria VARCHAR(100),
        fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        notas TEXT,
        metadata JSONB DEFAULT '{}',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    // Crear índices para mejor performance
    await createIndexIfNotExists(ctx, 'idx_usuarios_username', 
      'CREATE INDEX idx_usuarios_username ON usuarios(username);');
    
    await createIndexIfNotExists(ctx, 'idx_usuarios_email', 
      'CREATE INDEX idx_usuarios_email ON usuarios(email);');
      
    await createIndexIfNotExists(ctx, 'idx_negocios_tipo', 
      'CREATE INDEX idx_negocios_tipo ON negocios(tipo);');
      
    await createIndexIfNotExists(ctx, 'idx_negocios_propietario', 
      'CREATE INDEX idx_negocios_propietario ON negocios(propietario_id);');
      
    await createIndexIfNotExists(ctx, 'idx_transacciones_negocio_fecha', 
      'CREATE INDEX idx_transacciones_negocio_fecha ON transacciones(negocio_id, fecha DESC);');
      
    await createIndexIfNotExists(ctx, 'idx_transacciones_tipo', 
      'CREATE INDEX idx_transacciones_tipo ON transacciones(tipo);');
      
    await createIndexIfNotExists(ctx, 'idx_transacciones_usuario', 
      'CREATE INDEX idx_transacciones_usuario ON transacciones(usuario_id);');

    await createIndexIfNotExists(ctx, 'idx_usuario_negocio_permisos', 
      'CREATE INDEX idx_usuario_negocio_permisos ON usuario_negocio_permisos(usuario_id, negocio_id);');
  }

  @override
  Future<void> down(TxSession ctx) async {
    // Eliminar tablas en orden inverso debido a las foreign keys
    await execute(ctx, 'DROP TABLE IF EXISTS transacciones CASCADE;');
    await execute(ctx, 'DROP TABLE IF EXISTS usuario_modulo_permisos CASCADE;');
    await execute(ctx, 'DROP TABLE IF EXISTS usuario_negocio_permisos CASCADE;');
    await execute(ctx, 'DROP TABLE IF EXISTS negocio_modulos CASCADE;');
    await execute(ctx, 'DROP TABLE IF EXISTS modulos CASCADE;');
    await execute(ctx, 'DROP TABLE IF EXISTS negocios CASCADE;');
    await execute(ctx, 'DROP TABLE IF EXISTS usuarios CASCADE;');
  }
}