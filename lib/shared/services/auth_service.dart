import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../core/database/database_connection.dart';
import '../../core/config/app_config.dart';
import '../models/user_model.dart';

/// Servicio de autenticación para D-Nexus
class AuthService {

  /// Autentica a un usuario con username y password
  static Future<UserModel?> login(String username, String password) async {
    try {
      AppConfig.logger.i('Attempting login for username: $username');
      
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
      
      AppConfig.logger.i('Login successful for user: ${user.username} (${user.role})');
      return user.copyWith(lastLogin: DateTime.now());
      
    } catch (e, stackTrace) {
      AppConfig.logger.e('Error during login: $e', error: e, stackTrace: stackTrace);
      return null;
    }
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

  /// Verifica si un usuario tiene permisos de administrador
  static bool isAdmin(UserModel user) {
    return user.role == 'superadmin' || user.role == 'admin';
  }
}