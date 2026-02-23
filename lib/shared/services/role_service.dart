/// DEPRECATED - Use EmployeeRepository instead
/// 
/// This service is kept for backward compatibility to prevent compilation errors
/// in pages that still use it (roles_management_page, users_management_page).
/// All functions are stubs that return empty collections.
///
/// For new code, use EmployeeRepository from lib/core/repositories/employee_repository.dart
///
/// Migration planned for Sprint: [TBD]

import 'package:dnexus/shared/models/role_model.dart';

class RoleService {
  // Stub implementations to prevent compilation errors in legacy pages

  static Future<List<RoleModel>> getAllRoles() async {
    return [];
  }

  static Future<Map<String, dynamic>> getPermissionsByModule() async {
    return {};
  }

  static Future<RoleModel?> createRole({
    required String negocioId,
    required String nombre,
    String? descripcion,
    List<int>? moduloIds,
  }) async {
    return null;
  }

  static Future<RoleModel?> getRoleWithPermissions(int roleId) async {
    return null;
  }

  static Future<List<Map<String, dynamic>>> getAllPermissions() async {
    return [];
  }

  static Future<bool> assignPermissionsToRole({
    required int roleId,
    required List<int> permissionIds,
  }) async {
    return false;
  }

  static Future<bool> deleteRole(int roleId) async {
    return false;
  }

  static Future<List<RoleModel>> getUserRoles(int userId) async {
    return [];
  }

  static Future<bool> assignRoleToUser({
    required int userId,
    required int roleId,
  }) async {
    return false;
  }

  static Future<bool> removeRoleFromUser({
    required int userId,
    required int roleId,
  }) async {
    return false;
  }

  static Future<List<Map<String, dynamic>>> getRoleStats() async {
    return [];
  }
}
