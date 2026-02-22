import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/database/database_connection.dart';
import '../../core/config/app_config.dart';
import '../models/user_model.dart';
import 'session_service.dart';

/// Servicio de autenticación para D-Nexus
class AuthService {

  /// Autentica a un usuario con username y password
  /// Si se proporciona [system], también valida que el usuario tenga acceso a ese sistema
  static Future<UserModel?> login(String username, String password, {String? system}) async {
    try {
      AppConfig.logger.i('Attempting login for username: $username${system != null ? ' on system: $system' : ''}');
      
      // En web, usar Supabase
      if (kIsWeb) {
        return await _loginWeb(username, password, system: system);
      }
      
      // Hash de la contraseña para comparar con la base de datos
      final hashedPassword = _hashPassword(password);
      
      // Consulta para verificar credenciales
      const query = '''
        SELECT id, username, email, nombre_completo, rol_sistema, activo, created_at, updated_at 
        FROM usuarios 
        WHERE username = \$1 AND password_hash = \$2 AND activo = true
      ''';
      
      final result = await DatabaseConnection.query(query, parameters: [username, hashedPassword]);
      
      if (result.isEmpty) {
        AppConfig.logger.w('Login failed for username: $username - Invalid credentials');
        return null;
      }
      
      final userRow = result.first;
      final userMap = {
        'id': userRow[0],
        'username': userRow[1],
        'email': userRow[2],
        'full_name': userRow[3],
        'role': userRow[4],
        'is_active': userRow[5],
        'created_at': userRow[6].toString(),
        'last_login': userRow[7]?.toString(),
      };
      final user = UserModel.fromMap(userMap);
      
      // Actualizar último login
      await _updateLastLogin(user.id);
      
      // Guardar sesión
      await SessionService.saveSession(user.copyWith(lastLogin: DateTime.now()));

      AppConfig.logger.i('Login successful for user: ${user.username} (${user.role})');
      return user.copyWith(lastLogin: DateTime.now());
      
    } catch (e, stackTrace) {
      AppConfig.logger.e('Error during login: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Login con Supabase para web mode
  static Future<UserModel?> _loginWeb(String username, String password, {String? system}) async {
    try {
      AppConfig.logger.i('Attempting Supabase login for username: $username');
      
      // Consultar usuario desde Supabase
      final response = await Supabase.instance.client
          .from('users')
          .select('id, username, email, nombre_completo, rol, activo, created_at, updated_at, password')
          .eq('username', username)
          .single();
      
      // Verificar si el usuario está bloqueado
      final isActive = response['activo'] as bool? ?? false;
      if (!isActive) {
        AppConfig.logger.w('Login blocked for inactive user: $username');
        return null; // Retorna null para indicar usuario bloqueado
      }
      
      // Verificar contraseña
      final hashedPassword = _hashPassword(password);
      final dbHashedPassword = response['password'] as String?;
      
      if (dbHashedPassword != hashedPassword) {
        AppConfig.logger.w('Login failed for username: $username - Invalid password');
        return null;
      }
      
      final user = UserModel(
        id: response['id'] as int,
        username: response['username'] as String,
        email: response['email'] as String,
        fullName: response['nombre_completo'] as String,
        role: response['rol'] as String,
        isActive: response['activo'] as bool,
        createdAt: DateTime.parse(response['created_at'] as String),
        lastLogin: DateTime.now(),
      );
      
      // Si se proporciona un sistema, validar acceso
      if (system != null) {
        final hasAccess = await hasSystemAccess(user.id, system);
        if (!hasAccess) {
          AppConfig.logger.w('User ${user.username} does not have access to system: $system');
          return null; // No tiene acceso al sistema solicitado
        }
      }
      
      // Actualizar último login en Supabase
      await Supabase.instance.client
          .from('users')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);
      
      // Guardar sesión para persistencia
      await SessionService.saveSession(user);
      
      AppConfig.logger.i('Supabase login successful for user: ${user.username} (${user.role})');
      return user;
      
    } catch (e) {
      AppConfig.logger.w('Supabase login failed: $e. Using fallback mock data...');
      // Fallback a datos mock cuando Supabase no esté disponible
      return await _loginWebMockFallback(username, password);
    }
  }

  /// Fallback: Login mock para web cuando Supabase no está disponible
  static Future<UserModel?> _loginWebMockFallback(String username, String password) async {
    final mockUsers = {
      'hairo': {
        'password': 'Hernandez14',
        'id': 1,
        'email': 'hairo@dnexus.local',
        'full_name': 'Hairo Diaz',
        'role': 'owner',
        'is_active': true,
      },
      'admin': {
        'password': 'admin123',
        'id': 2,
        'email': 'admin@dnexus.local',
        'full_name': 'Administrador',
        'role': 'super_admin',
        'is_active': true,
      },
    };

    final mockUser = mockUsers[username];
    if (mockUser == null || mockUser['password'] != password) {
      AppConfig.logger.w('Mock fallback login failed for username: $username');
      return null;
    }

    final user = UserModel(
      id: mockUser['id'] as int,
      username: username,
      email: mockUser['email'] as String,
      fullName: mockUser['full_name'] as String,
      role: mockUser['role'] as String,
      isActive: mockUser['is_active'] as bool,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLogin: DateTime.now(),
    );

    // Guardar sesión para persistencia
    await SessionService.saveSession(user);

    AppConfig.logger.i('Mock fallback login successful for user: ${user.username} (${user.role})');
    return user;
  }

  /// Verifica si un usuario existe por username
  static Future<bool> userExists(String username) async {
    try {
      const query = 'SELECT COUNT(*) as count FROM usuarios WHERE username = \$1';
      final result = await DatabaseConnection.query(query, parameters: [username]);
      
      final count = result.first[0] as int;
      return count > 0;
      
    } catch (e) {
      AppConfig.logger.e('Error checking if user exists: $e');
      return false;
    }
  }

  /// Obtiene información de un usuario por ID
  static Future<UserModel?> getUserById(int userId) async {
    try {
      const query = '''
        SELECT id, username, email, nombre_completo, rol_sistema, activo, created_at, updated_at 
        FROM usuarios 
        WHERE id = \$1
      ''';
      
      final result = await DatabaseConnection.query(query, parameters: [userId]);
      
      if (result.isEmpty) {
        return null;
      }
      
      final userRow = result.first;
      final userMap = {
        'id': userRow[0],
        'username': userRow[1],
        'email': userRow[2],
        'full_name': userRow[3],
        'role': userRow[4],
        'is_active': userRow[5],
        'created_at': userRow[6].toString(),
        'last_login': userRow[7]?.toString(),
      };
      return UserModel.fromMap(userMap);
      
    } catch (e) {
      AppConfig.logger.e('Error getting user by ID: $e');
      return null;
    }
  }

  /// Actualiza la fecha de último login del usuario
  static Future<void> _updateLastLogin(int userId) async {
    try {
      const query = '''
        UPDATE usuarios 
        SET updated_at = NOW() 
        WHERE id = \$1
      ''';
      
      await DatabaseConnection.execute(query, parameters: [userId]);
      
    } catch (e) {
      AppConfig.logger.e('Error updating last login: $e');
    }
  }

  /// Genera hash SHA-256 de la contraseña
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Valida el formato de username
  static bool isValidUsername(String username) {
    if (username.isEmpty || username.length < 3) {
      return false;
    }
    
    // Solo letras, números y guiones bajos, debe empezar con letra
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
    return regex.hasMatch(username);
  }

  /// Valida el formato de password
  static bool isValidPassword(String password) {
    // Mínimo 4 caracteres para el super admin inicial
    return password.isNotEmpty && password.length >= 4;
  }

  /// Obtiene el rol del usuario actual (para futuras expansiones)
  static String getUserRole(UserModel user) {
    return user.role;
  }

  /// Verifica si un usuario existe pero está bloqueado
  static Future<bool> isUserBlocked(String username) async {
    try {
      if (!kIsWeb) return false;
      
      final response = await Supabase.instance.client
          .from('users')
          .select('activo')
          .eq('username', username)
          .single();
      
      final isActive = response['activo'] as bool? ?? true;
      return !isActive;
    } catch (e) {
      // Si no encontramos el usuario, no está bloqueado
      return false;
    }
  }

  /// Verifica si un usuario tiene acceso a un sistema específico
  /// El acceso se valida a través de la tabla admin_sistemas
  static Future<bool> hasSystemAccess(int userId, String system) async {
    try {
      if (!kIsWeb) return true; // En modo no-web, asumir acceso
      
      // Buscar si existe registro en admin_sistemas
      final response = await Supabase.instance.client
          .from('admin_sistemas')
          .select('id')
          .eq('admin_id', userId)
          .eq('sistema', system)
          .single();
      
      return true; // Si no hay excepción, existe el acceso
    } catch (e) {
      AppConfig.logger.w('System access check for user $userId on system $system: $e');
      return false;
    }
  }

  /// Verifica si un usuario tiene permisos de administrador
  static bool isAdmin(UserModel user) {
    return user.role == 'superadmin' || user.role == 'admin';
  }
}