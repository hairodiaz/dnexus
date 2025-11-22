import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/user_extensions.dart';

/// Servicio de autenticación con sistema de roles integrado
class AuthService {
  static UserModel? _currentUser;
  
  /// Usuario actualmente logueado
  static UserModel? get currentUser => _currentUser;

  /// Simula login de usuarios con diferentes roles
  static Future<UserModel?> login(String username, String password) async {
    // Simulación de usuarios para prueba
    final testUsers = {
      'admin': UserModel(
        id: 1,
        username: 'admin',
        email: 'admin@dnexus.com',
        fullName: 'Administrador Principal',
        role: UserRole.admin.value,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLogin: DateTime.now(),
      ),
      'caja': UserModel(
        id: 2,
        username: 'caja',
        email: 'caja@dnexus.com',
        fullName: 'Cajero Principal',
        role: UserRole.caja.value,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        lastLogin: DateTime.now(),
      ),
      'facturador': UserModel(
        id: 3,
        username: 'facturador',
        email: 'facturador@dnexus.com',
        fullName: 'Facturador Principal',
        role: UserRole.facturador.value,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lastLogin: DateTime.now(),
      ),
      'vendedor': UserModel(
        id: 4,
        username: 'vendedor',
        email: 'vendedor@dnexus.com',
        fullName: 'Vendedor Principal',
        role: UserRole.vendedor.value,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        lastLogin: DateTime.now(),
      ),
      'superadmin': UserModel(
        id: 0,
        username: 'superadmin',
        email: 'super@dnexus.com',
        fullName: 'Super Administrador',
        role: UserRole.superAdmin.value,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        lastLogin: DateTime.now(),
      ),
    };

    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 800));

    // Verificar credenciales (en producción esto sería contra una base de datos)
    if (testUsers.containsKey(username.toLowerCase()) && password == '123456') {
      _currentUser = testUsers[username.toLowerCase()];
      return _currentUser;
    }

    return null; // Credenciales inválidas
  }

  /// Cierra la sesión del usuario actual
  static Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  /// Verifica si hay un usuario logueado
  static bool get isLoggedIn => _currentUser != null;

  /// Verifica si el usuario actual tiene un permiso específico
  static bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    return RolePermissions.hasPermission(_currentUser!.userRole, permission);
  }

  /// Verifica si el usuario actual tiene un rol específico
  static bool hasRole(UserRole role) {
    if (_currentUser == null) return false;
    return _currentUser!.userRole == role;
  }

  /// Verifica si el usuario actual es administrador
  static bool get isAdmin {
    if (_currentUser == null) return false;
    return _currentUser!.isAdmin;
  }

  /// Verifica si el usuario actual puede manejar dinero
  static bool get canHandleMoney {
    if (_currentUser == null) return false;
    return _currentUser!.canHandleMoney;
  }

  /// Obtiene información resumida del usuario actual
  static Map<String, dynamic>? getCurrentUserInfo() {
    if (_currentUser == null) return null;
    
    return {
      'id': _currentUser!.id,
      'username': _currentUser!.username,
      'fullName': _currentUser!.fullName,
      'role': _currentUser!.roleDisplayName,
      'permissions': RolePermissions.getPermissions(_currentUser!.userRole),
      'accessibleModules': _currentUser!.accessibleModules,
    };
  }

  /// Actualiza la última conexión del usuario
  static Future<void> updateLastLogin() async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        lastLogin: DateTime.now(),
      );
    }
  }

  /// Obtiene todos los roles disponibles para mostrar en UI
  static List<Map<String, dynamic>> getAvailableRoles() {
    return UserRole.values.map((role) => {
      'value': role.value,
      'displayName': role.displayName,
      'color': role.colorValue,
      'icon': role.iconCodePoint,
    }).toList();
  }

  /// Verifica credenciales y devuelve información del error si las hay
  static Future<AuthResult> authenticateWithDetails(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return AuthResult(
        success: false,
        message: 'Por favor ingresa usuario y contraseña',
      );
    }

    try {
      final user = await login(username, password);
      
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'Credenciales incorrectas',
        );
      }

      if (!user.isActive) {
        return AuthResult(
          success: false,
          message: 'Usuario inactivo. Contacta al administrador.',
        );
      }

      return AuthResult(
        success: true,
        message: 'Bienvenido ${user.fullName ?? user.username}',
        user: user,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error de conexión. Inténtalo de nuevo.',
      );
    }
  }
}

/// Resultado de autenticación
class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  const AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}