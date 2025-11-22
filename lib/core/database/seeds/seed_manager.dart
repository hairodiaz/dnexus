import '../database_connection.dart';
import '../../config/app_config.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Administrador de seeds (datos iniciales) para D-Nexus
class SeedManager {
  /// Ejecutar todos los seeds necesarios
  static Future<void> runSeeds() async {
    AppConfig.logger.i('Starting database seeding...');
    
    try {
      // 1. Crear super admin si no existe
      await _createSuperAdmin();
      
      // 2. Crear negocios
      await _createBusinesses();
      
      // 3. Crear usuarios por negocio
      await _createBusinessUsers();
      
      // 4. Crear módulos base
      await _createBaseModules();
      
      AppConfig.logger.i('Database seeding completed successfully');
      
    } catch (e) {
      AppConfig.logger.e('Database seeding failed: $e');
      rethrow;
    }
  }

  /// Crear el super administrador inicial
  static Future<void> _createSuperAdmin() async {
    AppConfig.logger.i('Creating super admin user...');
    
    // Verificar si ya existe un super admin
    const checkSql = '''
      SELECT COUNT(*) as count FROM usuarios 
      WHERE rol_sistema = \$1;
    ''';
    
    final result = await DatabaseConnection.query(checkSql, parameters: ['super_admin']);
    final count = result.first[0] as int;
    
    if (count > 0) {
      AppConfig.logger.i('Super admin already exists, skipping creation');
      return;
    }

    // Crear el super admin
    final passwordHash = _hashPassword('admin123'); // Cambiar en producción
    
    const insertSql = '''
      INSERT INTO usuarios (
        username, 
        email, 
        password_hash, 
        nombre_completo, 
        rol_sistema, 
        activo
      ) VALUES (
        \$1, 
        \$2, 
        \$3, 
        \$4, 
        \$5, 
        \$6
      );
    ''';
    
    await DatabaseConnection.execute(insertSql, parameters: [
      'superadmin',
      'admin@dnexus.com',
      passwordHash,
      'Super Administrador D-Nexus',
      'super_admin',
      true,
    ]);
    
    AppConfig.logger.i('Super admin created successfully');
    AppConfig.logger.w('Super admin credentials: username=superadmin, password=admin123');
  }

  /// Crear los módulos base del sistema
  static Future<void> _createBaseModules() async {
    AppConfig.logger.i('Creating base modules...');
    
    final modules = [
      {
        'nombre': 'Transacciones',
        'codigo': 'transacciones',
        'descripcion': 'Registro y gestión de ingresos y egresos',
        'icono': 'attach_money',
      },
      {
        'nombre': 'Reportes',
        'codigo': 'reportes',
        'descripcion': 'Informes y estadísticas financieras',
        'icono': 'assessment',
      },
      {
        'nombre': 'Dashboard',
        'codigo': 'dashboard',
        'descripcion': 'Panel principal con resumen ejecutivo',
        'icono': 'dashboard',
      },
      {
        'nombre': 'Configuración',
        'codigo': 'configuracion',
        'descripcion': 'Configuración del negocio y usuarios',
        'icono': 'settings',
      },
      {
        'nombre': 'Inventario',
        'codigo': 'inventario',
        'descripcion': 'Control de productos y stock (módulo futuro)',
        'icono': 'inventory',
      },
      {
        'nombre': 'Ventas',
        'codigo': 'ventas',
        'descripcion': 'Sistema de punto de venta (módulo futuro)',
        'icono': 'shopping_cart',
      },
      {
        'nombre': 'Préstamos',
        'codigo': 'prestamos',
        'descripcion': 'Gestión de préstamos informales (módulo futuro)',
        'icono': 'account_balance',
      },
      {
        'nombre': 'Clientes',
        'codigo': 'clientes',
        'descripcion': 'Base de datos de clientes (módulo futuro)',
        'icono': 'people',
      },
    ];

    for (final module in modules) {
      await _createModuleIfNotExists(module);
    }
    
    AppConfig.logger.i('Base modules created successfully');
  }

  /// Crear un módulo si no existe
  static Future<void> _createModuleIfNotExists(Map<String, dynamic> moduleData) async {
    // Verificar si el módulo ya existe
    const checkSql = '''
      SELECT COUNT(*) as count FROM modulos 
      WHERE codigo = \$1;
    ''';
    
    final result = await DatabaseConnection.query(checkSql, parameters: [
      moduleData['codigo'],
    ]);
    
    final count = result.first[0] as int;
    
    if (count > 0) {
      AppConfig.logger.d('Module ${moduleData['codigo']} already exists, skipping');
      return;
    }

    // Crear el módulo
    const insertSql = '''
      INSERT INTO modulos (
        nombre, 
        codigo, 
        descripcion, 
        activo
      ) VALUES (
        \$1, 
        \$2, 
        \$3, 
        \$4
      );
    ''';
    
    await DatabaseConnection.execute(insertSql, parameters: [
      moduleData['nombre'],
      moduleData['codigo'],
      moduleData['descripcion'],
      true,
    ]);
    
    AppConfig.logger.d('Module ${moduleData['codigo']} created');
  }

  /// Crear los negocios iniciales
  static Future<void> _createBusinesses() async {
    AppConfig.logger.i('Creating businesses...');

    final businesses = [
      {
        'nombre': 'Repuestos El Mecánico',
        'tipo': 'repuestos',
        'descripcion': 'Venta de repuestos automotrices',
      },
      {
        'nombre': 'Préstamos Rápidos',
        'tipo': 'prestamos',
        'descripcion': 'Servicio de préstamos personales',
      },
      {
        'nombre': 'Electrodomésticos La Casa',
        'tipo': 'electrodomesticos',
        'descripcion': 'Venta de electrodomésticos para el hogar',
      },
    ];

    for (final businessData in businesses) {
      await _createBusinessIfNotExists(businessData);
    }

    AppConfig.logger.i('Businesses created successfully');
  }

  /// Crear un negocio si no existe
  static Future<void> _createBusinessIfNotExists(Map<String, dynamic> businessData) async {
    const checkSql = '''
      SELECT COUNT(*) as count FROM negocios 
      WHERE nombre = \$1;
    ''';
    
    final result = await DatabaseConnection.query(checkSql, parameters: [businessData['nombre']]);
    final count = result.first[0] as int;
    
    if (count > 0) {
      AppConfig.logger.d('Business ${businessData['nombre']} already exists, skipping');
      return;
    }

    const insertSql = '''
      INSERT INTO negocios (nombre, tipo, descripcion, activo) 
      VALUES (\$1, \$2, \$3, \$4);
    ''';
    
    await DatabaseConnection.execute(insertSql, parameters: [
      businessData['nombre'],
      businessData['tipo'],
      businessData['descripcion'],
      true,
    ]);
    
    AppConfig.logger.d('Business ${businessData['nombre']} created');
  }

  /// Crear usuarios específicos para cada negocio
  static Future<void> _createBusinessUsers() async {
    AppConfig.logger.i('Creating business users...');

    final users = [
      {
        'username': 'repuestos_user',
        'password': 'repuestos123',
        'email': 'repuestos@dnexus.com',
        'nombre_completo': 'Usuario Repuestos',
        'business_name': 'Repuestos El Mecánico',
      },
      {
        'username': 'prestamos_user',
        'password': 'prestamos123',
        'email': 'prestamos@dnexus.com',
        'nombre_completo': 'Usuario Préstamos',
        'business_name': 'Préstamos Rápidos',
      },
      {
        'username': 'electro_user',
        'password': 'electro123',
        'email': 'electro@dnexus.com',
        'nombre_completo': 'Usuario Electrodomésticos',
        'business_name': 'Electrodomésticos La Casa',
      },
    ];

    for (final userData in users) {
      await _createBusinessUserIfNotExists(userData);
    }

    AppConfig.logger.i('Business users created successfully');
  }

  /// Crear un usuario de negocio si no existe
  static Future<void> _createBusinessUserIfNotExists(Map<String, dynamic> userData) async {
    const checkSql = '''
      SELECT COUNT(*) as count FROM usuarios 
      WHERE username = \$1;
    ''';
    
    final result = await DatabaseConnection.query(checkSql, parameters: [userData['username']]);
    final count = result.first[0] as int;
    
    if (count > 0) {
      AppConfig.logger.d('User ${userData['username']} already exists, skipping');
      return;
    }

    // Obtener ID del negocio
    const businessSql = '''
      SELECT id FROM negocios WHERE nombre = \$1;
    ''';
    
    final businessResult = await DatabaseConnection.query(businessSql, parameters: [userData['business_name']]);
    if (businessResult.isEmpty) {
      AppConfig.logger.w('Business ${userData['business_name']} not found for user ${userData['username']}');
      return;
    }
    
    final businessId = businessResult.first[0] as int;
    final passwordHash = _hashPassword(userData['password']);

    const insertSql = '''
      INSERT INTO usuarios (
        username, 
        email, 
        password_hash, 
        nombre_completo, 
        rol_sistema, 
        activo
      ) VALUES (\$1, \$2, \$3, \$4, \$5, \$6);
    ''';
    
    await DatabaseConnection.execute(insertSql, parameters: [
      userData['username'],
      userData['email'],
      passwordHash,
      userData['nombre_completo'],
      'admin_negocio', // Rol para administrar su negocio
      true,
    ]);
    
    // Vincular usuario con su negocio
    final userId = await _getUserId(userData['username']);
    await _linkUserToBusiness(userId, businessId);
    
    AppConfig.logger.d('User ${userData['username']} created and linked to business');
    AppConfig.logger.w('User credentials: ${userData['username']} / ${userData['password']}');
  }

  /// Obtener ID de usuario por username
  static Future<int> _getUserId(String username) async {
    const sql = 'SELECT id FROM usuarios WHERE username = \$1';
    final result = await DatabaseConnection.query(sql, parameters: [username]);
    return result.first[0] as int;
  }

  /// Vincular usuario con negocio
  static Future<void> _linkUserToBusiness(int userId, int businessId) async {
    // Actualizar la tabla negocios con el propietario
    const updateSql = '''
      UPDATE negocios 
      SET propietario_id = \$1 
      WHERE id = \$2;
    ''';
    
    await DatabaseConnection.execute(updateSql, parameters: [userId, businessId]);
  }

  /// Hash simple para contraseñas (mejorar en producción)
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Limpiar todos los seeds (útil para testing)
  static Future<void> clearSeeds() async {
    AppConfig.logger.w('Clearing all seed data...');
    
    await DatabaseConnection.transaction((ctx) async {
      await ctx.execute('DELETE FROM transacciones;');
      await ctx.execute('DELETE FROM usuario_modulo_permisos;');
      await ctx.execute('DELETE FROM usuario_negocio_permisos;');
      await ctx.execute('DELETE FROM negocio_modulos;');
      await ctx.execute('DELETE FROM negocios;');
      await ctx.execute('DELETE FROM modulos;');
      await ctx.execute('DELETE FROM usuarios;');
    });
    
    AppConfig.logger.i('Seed data cleared successfully');
  }
}