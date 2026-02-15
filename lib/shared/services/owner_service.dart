import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/database/database_connection.dart';
import '../../core/config/app_config.dart';
import '../models/user_model.dart';
import 'session_service.dart';

/// Servicio para operaciones del Owner (Dueño del Sistema)
/// Permite crear empresas, administradores, etc.
class OwnerService {
  
  /// Crear una nueva empresa y su administrador automáticamente
  static Future<Map<String, dynamic>?> createBusinessWithAdmin({
    required String businessName,
    required String businessType, // 'repuestos', 'prestamos', 'electrodomesticos'
    required String businessDescription,
    required String adminUsername,
    required String adminPassword,
    required int ownerId,
  }) async {
    try {
      AppConfig.logger.i('Creating business: $businessName with admin: $adminUsername');
      
      if (kIsWeb) {
        return await _createBusinessWithAdminWeb(
          businessName: businessName,
          businessType: businessType,
          businessDescription: businessDescription,
          adminUsername: adminUsername,
          adminPassword: adminPassword,
          ownerId: ownerId,
        );
      }
      
      // Verificar que el owner existe y tiene rol 'owner'
      final ownerUser = await _verifyOwnerExists(ownerId);
      if (ownerUser == null) {
        AppConfig.logger.e('Owner with ID $ownerId does not exist or is not an owner');
        return null;
      }

      // Verificar si el negocio ya existe
      if (await _businessExists(businessName)) {
        AppConfig.logger.w('Business $businessName already exists');
        return null;
      }

      // Verificar si el username del admin ya existe
      if (await _userExists(adminUsername)) {
        AppConfig.logger.w('Admin username $adminUsername already exists');
        return null;
      }

      // Crear la empresa
      final businessId = await _createBusiness(
        name: businessName,
        type: businessType,
        description: businessDescription,
        ownerId: ownerId,
      );

      if (businessId == null) {
        AppConfig.logger.e('Failed to create business');
        return null;
      }

      // Crear el usuario administrador de la empresa
      final adminUserId = await _createBusinessAdmin(
        businessId: businessId,
        username: adminUsername,
        password: adminPassword,
        businessName: businessName,
      );

      if (adminUserId == null) {
        AppConfig.logger.e('Failed to create business admin');
        return null;
      }

      AppConfig.logger.i('Business and admin created successfully');
      
      return {
        'business_id': businessId,
        'business_name': businessName,
        'business_type': businessType,
        'admin_id': adminUserId,
        'admin_username': adminUsername,
        'success': true,
      };
      
    } catch (e, stackTrace) {
      AppConfig.logger.e('Error creating business with admin: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Crear empresa con admin en Supabase (web mode)
  static Future<Map<String, dynamic>?> _createBusinessWithAdminWeb({
    required String businessName,
    required String businessType,
    required String businessDescription,
    required String adminUsername,
    required String adminPassword,
    required int ownerId,
  }) async {
    try {
      // Verificar que el negocio no existe
      final existingBusiness = await Supabase.instance.client
          .from('negocios')
          .select('id')
          .eq('nombre', businessName)
          .maybeSingle();
      
      if (existingBusiness != null) {
        AppConfig.logger.w('Business $businessName already exists');
        return null;
      }

      // Verificar que el username del admin no existe
      final existingUser = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('username', adminUsername)
          .maybeSingle();
      
      if (existingUser != null) {
        AppConfig.logger.w('Admin username $adminUsername already exists');
        return null;
      }

      // Crear la empresa en Supabase
      final businessResponse = await Supabase.instance.client
          .from('negocios')
          .insert({
            'nombre': businessName,
            'tipo': businessType,
            'descripcion': businessDescription,
            'propietario_id': ownerId,
            'activo': true,
          })
          .select('id')
          .single();

      final businessId = businessResponse['id'] as int;
      AppConfig.logger.i('Business created in Supabase with ID: $businessId');

      // Crear usuario admin en Supabase
      final passwordHash = _hashPassword(adminPassword);
      
      final userResponse = await Supabase.instance.client
          .from('users')
          .insert({
            'username': adminUsername,
            'email': '$adminUsername@$businessName.dnexus.com',
            'password': passwordHash,
            'nombre_completo': 'Administrador de $businessName',
            'rol': 'admin_negocio',
            'activo': true,
          })
          .select('id')
          .single();

      final adminUserId = userResponse['id'] as int;
      AppConfig.logger.i('Admin user created in Supabase with ID: $adminUserId');

      // Vincular usuario con negocio
      await Supabase.instance.client
          .from('usuario_negocio_permisos')
          .insert({
            'usuario_id': adminUserId,
            'negocio_id': businessId,
            'rol': 'admin',
          });

      return {
        'business_id': businessId,
        'business_name': businessName,
        'business_type': businessType,
        'admin_id': adminUserId,
        'admin_username': adminUsername,
        'success': true,
      };
      
    } catch (e, stackTrace) {
      AppConfig.logger.e('❌ Error creating business with admin in Supabase: $e', error: e, stackTrace: stackTrace);
      // Re-lanzar el error para que el UI lo muestre claramente
      throw Exception('Error al crear empresa: $e');
    }
  }

  /// Fallback: Crear empresa con admin en mock quando Supabase no esté disponible
  static Map<String, dynamic>? _createBusinessWithAdminMockFallback({
    required String businessName,
    required String businessType,
    required String businessDescription,
    required String adminUsername,
    required String adminPassword,
    required int ownerId,
  }) {
    try {
      // Generar IDs simulados
      final businessId = _mockBusinesses.fold<int>(0, (max, b) => max > (b['id'] as int) ? max : (b['id'] as int)) + 1;
      final adminUserId = businessId + 1000;
      
      // Crear registro de negocio mock
      _mockBusinesses.add({
        'id': businessId,
        'nombre': businessName,
        'tipo': businessType,
        'descripcion': businessDescription,
        'propietario_id': ownerId,
        'activo': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      AppConfig.logger.i('Mock fallback: Business created with ID: $businessId');
      
      return {
        'business_id': businessId,
        'business_name': businessName,
        'business_type': businessType,
        'admin_id': adminUserId,
        'admin_username': adminUsername,
        'success': true,
      };
    } catch (e) {
      AppConfig.logger.e('Error in mock fallback: $e');
      return null;
    }
  }

  /// Crear solo una empresa (sin admin automático)
  static Future<int?> createBusiness({
    required String name,
    required String type,
    required String description,
    required int ownerId,
  }) async {
    try {
      AppConfig.logger.i('Creating business: $name');
      
      return await _createBusiness(
        name: name,
        type: type,
        description: description,
        ownerId: ownerId,
      );
      
    } catch (e) {
      AppConfig.logger.e('Error creating business: $e');
      return null;
    }
  }

  /// Obtener todas las empresas del owner
  static Future<List<Map<String, dynamic>>> getOwnerBusinesses(int ownerId) async {
    try {
      if (kIsWeb) {
        return await _getOwnerBusinessesWeb(ownerId);
      }
      
      const sql = '''
        SELECT 
          id,
          nombre,
          tipo,
          descripcion,
          activo,
          created_at,
          updated_at
        FROM negocios
        WHERE propietario_id = \$1
        ORDER BY created_at DESC;
      ''';
      
      final result = await DatabaseConnection.query(sql, parameters: [ownerId]);
      
      return result.map((row) {
        return {
          'id': row[0],
          'nombre': row[1],
          'tipo': row[2],
          'descripcion': row[3],
          'activo': row[4],
          'created_at': row[5].toString(),
          'updated_at': row[6].toString(),
        };
      }).toList();
      
    } catch (e) {
      AppConfig.logger.e('Error fetching owner businesses: $e');
      return [];
    }
  }

  /// Obtener empresas del owner desde Supabase (web mode)
  static Future<List<Map<String, dynamic>>> _getOwnerBusinessesWeb(int ownerId) async {
    try {
      final response = await Supabase.instance.client
          .from('negocios')
          .select('id, nombre, tipo, descripcion, activo, created_at, updated_at')
          .eq('propietario_id', ownerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
      
    } catch (e) {
      AppConfig.logger.w('Error fetching owner businesses from Supabase: $e. Using mock fallback...');
      // Fallback a mock data cuando Supabase no esté disponible
      return _getOwnerBusinessesMockFallback(ownerId);
    }
  }

  /// Fallback: Obtener empresas mock cuando Supabase no esté disponible
  static List<Map<String, dynamic>> _getOwnerBusinessesMockFallback(int ownerId) {
    try {
      return _mockBusinesses
          .where((b) => b['propietario_id'] == ownerId)
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (e) {
      AppConfig.logger.e('Error in mock fallback for businesses: $e');
      return [];
    }
  }

  /// Datos mock para cuando Supabase no esté disponible
  static final List<Map<String, dynamic>> _mockBusinesses = [];

  /// Obtener administradores de una empresa
  static Future<List<Map<String, dynamic>>> getBusinessAdmins(int businessId) async {
    try {
      const sql = '''
        SELECT 
          u.id,
          u.username,
          u.nombre_completo,
          u.email,
          u.activo,
          u.created_at
        FROM usuarios u
        WHERE u.rol_sistema = \$1
        AND EXISTS (
          SELECT 1 FROM usuario_negocio_permisos unp 
          WHERE unp.usuario_id = u.id 
          AND unp.negocio_id = \$2 
          AND unp.rol = 'admin'
        )
        ORDER BY u.created_at DESC;
      ''';
      
      final result = await DatabaseConnection.query(
        sql, 
        parameters: ['admin_negocio', businessId],
      );
      
      return result.map((row) {
        return {
          'id': row[0],
          'username': row[1],
          'nombre_completo': row[2],
          'email': row[3],
          'activo': row[4],
          'created_at': row[5].toString(),
        };
      }).toList();
      
    } catch (e) {
      AppConfig.logger.e('Error fetching business admins: $e');
      return [];
    }
  }

  /// Cambiar propietario de una empresa (solo Owner)
  static Future<bool> changeBusinessOwner({
    required int businessId,
    required int newOwnerId,
    required int currentOwnerId,
  }) async {
    try {
      // Verificar que el usuario actual es el owner
      final ownerUser = await _verifyOwnerExists(currentOwnerId);
      if (ownerUser == null) {
        return false;
      }

      // Verificar que el nuevo owner existe
      final newOwner = await _getUserById(newOwnerId);
      if (newOwner == null) {
        return false;
      }

      // Actualizar propietario
      const sql = '''
        UPDATE negocios
        SET propietario_id = \$1, updated_at = CURRENT_TIMESTAMP
        WHERE id = \$2;
      ''';
      
      await DatabaseConnection.execute(sql, parameters: [newOwnerId, businessId]);
      
      AppConfig.logger.i('Business owner changed successfully');
      return true;
      
    } catch (e) {
      AppConfig.logger.e('Error changing business owner: $e');
      return false;
    }
  }

  // ============ MÉTODOS PRIVADOS ============

  /// Verificar que un usuario existe y es Owner
  static Future<UserModel?> _verifyOwnerExists(int userId) async {
    try {
      const sql = '''
        SELECT 
          id, username, email, nombre_completo, 
          rol_sistema, activo, created_at
        FROM usuarios
        WHERE id = \$1 AND rol_sistema = 'owner';
      ''';
      
      final result = await DatabaseConnection.query(sql, parameters: [userId]);
      
      if (result.isEmpty) {
        return null;
      }

      final row = result.first;
      return UserModel(
        id: row[0] as int,
        username: row[1] as String,
        email: row[2] as String,
        fullName: row[3] as String?,
        role: row[4] as String,
        isActive: row[5] as bool,
        createdAt: row[6] as DateTime,
      );
      
    } catch (e) {
      AppConfig.logger.e('Error verifying owner: $e');
      return null;
    }
  }

  /// Obtener usuario por ID
  static Future<UserModel?> _getUserById(int userId) async {
    try {
      const sql = '''
        SELECT 
          id, username, email, nombre_completo, 
          rol_sistema, activo, created_at
        FROM usuarios
        WHERE id = \$1;
      ''';
      
      final result = await DatabaseConnection.query(sql, parameters: [userId]);
      
      if (result.isEmpty) {
        return null;
      }

      final row = result.first;
      return UserModel(
        id: row[0] as int,
        username: row[1] as String,
        email: row[2] as String,
        fullName: row[3] as String?,
        role: row[4] as String,
        isActive: row[5] as bool,
        createdAt: row[6] as DateTime,
      );
      
    } catch (e) {
      AppConfig.logger.e('Error fetching user: $e');
      return null;
    }
  }

  /// Verificar si una empresa existe
  static Future<bool> _businessExists(String businessName) async {
    try {
      const sql = 'SELECT COUNT(*) as count FROM negocios WHERE nombre = \$1;';
      final result = await DatabaseConnection.query(sql, parameters: [businessName]);
      final count = result.first[0] as int;
      return count > 0;
    } catch (e) {
      AppConfig.logger.e('Error checking business exists: $e');
      return false;
    }
  }

  /// Verificar si un usuario existe
  static Future<bool> _userExists(String username) async {
    try {
      const sql = 'SELECT COUNT(*) as count FROM usuarios WHERE username = \$1;';
      final result = await DatabaseConnection.query(sql, parameters: [username]);
      final count = result.first[0] as int;
      return count > 0;
    } catch (e) {
      AppConfig.logger.e('Error checking user exists: $e');
      return false;
    }
  }

  /// Crear una empresa en la base de datos
  static Future<int?> _createBusiness({
    required String name,
    required String type,
    required String description,
    required int ownerId,
  }) async {
    try {
      const sql = '''
        INSERT INTO negocios (nombre, tipo, descripcion, propietario_id, activo)
        VALUES (\$1, \$2, \$3, \$4, \$5)
        RETURNING id;
      ''';
      
      final result = await DatabaseConnection.execute(
        sql,
        parameters: [name, type, description, ownerId, true],
      );

      if (result.isEmpty) {
        return null;
      }

      final businessId = result.first[0] as int;
      AppConfig.logger.i('Business created with ID: $businessId');
      return businessId;
      
    } catch (e) {
      AppConfig.logger.e('Error creating business in DB: $e');
      return null;
    }
  }

  /// Crear administrador de empresa
  static Future<int?> _createBusinessAdmin({
    required int businessId,
    required String username,
    required String password,
    required String businessName,
  }) async {
    try {
      // Crear usuario admin
      final passwordHash = _hashPassword(password);
      
      const userInsertSql = '''
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
        )
        RETURNING id;
      ''';
      
      final userResult = await DatabaseConnection.execute(
        userInsertSql,
        parameters: [
          username,
          '$username@$businessName.dnexus.com',
          passwordHash,
          'Administrador de $businessName',
          'admin_negocio',
          true,
        ],
      );

      if (userResult.isEmpty) {
        return null;
      }

      final adminUserId = userResult.first[0] as int;

      // Vincular usuario con negocio
      const permissionInsertSql = '''
        INSERT INTO usuario_negocio_permisos (usuario_id, negocio_id, rol)
        VALUES (\$1, \$2, \$3)
        ON CONFLICT (usuario_id, negocio_id) DO NOTHING;
      ''';
      
      await DatabaseConnection.execute(
        permissionInsertSql,
        parameters: [adminUserId, businessId, 'admin'],
      );

      AppConfig.logger.i('Business admin created with ID: $adminUserId');
      return adminUserId;
      
    } catch (e) {
      AppConfig.logger.e('Error creating business admin: $e');
      return null;
    }
  }

  /// Hash de contraseña
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validar login del Owner (Propietario del Sistema)
  static Future<UserModel?> validateOwnerLogin(
    String username,
    String password,
  ) async {
    try {
      AppConfig.logger.i('Validating Owner login for: $username');
      
      final supabase = Supabase.instance.client;
      final hashedPassword = _hashPassword(password);

      // Buscar usuario con rol 'owner'
      final response = await supabase
          .from('users')
          .select()
          .eq('username', username)
          .eq('rol', 'owner')
          .single();

      final user = UserModel.fromJson(response);

      // Verificar si el usuario está bloqueado
      if (!user.isActive) {
        AppConfig.logger.w('Login blocked for inactive owner: $username');
        return null;
      }

      // Validar contraseña
      if (user.password != hashedPassword) {
        AppConfig.logger.w('Invalid password for owner: $username');
        return null;
      }

      // Guardar sesión para persistencia
      await SessionService.saveSession(user);

      AppConfig.logger.i('Owner login successful for: $username');
      return user;

    } on PostgrestException catch (e) {
      AppConfig.logger.e('Postgrest error during owner login: $e');
      return null;
    } catch (e, stackTrace) {
      AppConfig.logger.e('Error during owner login: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
