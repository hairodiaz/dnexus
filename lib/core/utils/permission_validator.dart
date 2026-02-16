import '../../shared/models/user_model.dart';
import '../../shared/services/role_service.dart';
import '../../core/config/app_config.dart';

/// Helper para validar permisos de usuarios
class PermissionValidator {
  
  /// Verifica si un usuario tiene permiso para una acción específica
  /// Retorna true si tiene el permiso, false en caso contrario
  static Future<bool> hasPermission({
    required UserModel user,
    required String permissionName,
    String sistema = 'repuestos',
  }) async {
    try {
      // Si el usuario es owner o super_admin, tiene todos los permisos
      if (user.role == 'owner' || user.role == 'super_admin') {
        return true;
      }

      // Para admin_negocio del sistema, verificar sus roles y permisos
      if (user.role == 'admin_negocio') {
        final hasPermission = await RoleService.userHasPermission(
          userId: user.id,
          permissionName: permissionName,
          sistema: sistema,
        );
        return hasPermission;
      }

      return false;
    } catch (e) {
      AppConfig.logger.e('Error validating permission: $e');
      return false;
    }
  }

  /// Verifica si un usuario tiene alguno de los permisos en la lista
  static Future<bool> hasAnyPermission({
    required UserModel user,
    required List<String> permissionNames,
    String sistema = 'repuestos',
  }) async {
    try {
      if (user.role == 'owner' || user.role == 'super_admin') {
        return true;
      }

      for (var permission in permissionNames) {
        final has = await hasPermission(
          user: user,
          permissionName: permission,
          sistema: sistema,
        );
        if (has) return true;
      }

      return false;
    } catch (e) {
      AppConfig.logger.e('Error validating any permission: $e');
      return false;
    }
  }

  /// Verifica si un usuario tiene todos los permisos en la lista
  static Future<bool> hasAllPermissions({
    required UserModel user,
    required List<String> permissionNames,
    String sistema = 'repuestos',
  }) async {
    try {
      if (user.role == 'owner' || user.role == 'super_admin') {
        return true;
      }

      for (var permission in permissionNames) {
        final has = await hasPermission(
          user: user,
          permissionName: permission,
          sistema: sistema,
        );
        if (!has) return false;
      }

      return true;
    } catch (e) {
      AppConfig.logger.e('Error validating all permissions: $e');
      return false;
    }
  }

  /// Obtiene todos los permisos de un usuario
  static Future<List<String>> getUserPermissions({
    required UserModel user,
    String sistema = 'repuestos',
  }) async {
    try {
      if (user.role == 'owner' || user.role == 'super_admin') {
        // Retornar todos los permisos del sistema
        final allPermissions = await RoleService.getAllPermissions(sistema: sistema);
        return allPermissions.map((p) => p.nombre).toList();
      }

      return await RoleService.getUserPermissions(
        userId: user.id,
        sistema: sistema,
      );
    } catch (e) {
      AppConfig.logger.e('Error getting user permissions: $e');
      return [];
    }
  }
}
