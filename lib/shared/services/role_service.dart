import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../models/role_model.dart';
import '../models/permission_model.dart';

/// Servicio para gestión de Roles y Permisos en Repuestos
class RoleService {
  
  static const String _rolesTable = 'roles_repuestos';
  static const String _permissionsTable = 'permissions_repuestos';
  static const String _rolePermissionsTable = 'role_permissions_repuestos';
  static const String _userRolesTable = 'user_roles_repuestos';

  /// Obtiene todos los roles del sistema
  static Future<List<RoleModel>> getAllRoles({String sistema = 'repuestos'}) async {
    try {
      if (!kIsWeb) return [];
      
      final response = await Supabase.instance.client
          .from(_rolesTable)
          .select()
          .eq('sistema', sistema)
          .order('nombre', ascending: true);

      final roles = (response as List)
          .map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
          .toList();

      AppConfig.logger.i('Loaded ${roles.length} roles for system: $sistema');
      return roles;
    } catch (e) {
      AppConfig.logger.e('Error loading roles: $e');
      return [];
    }
  }

  /// Obtiene un rol específico con sus permisos
  static Future<RoleModel?> getRoleWithPermissions(int roleId) async {
    try {
      if (!kIsWeb) return null;
      
      // Obtener rol
      final roleResponse = await Supabase.instance.client
          .from(_rolesTable)
          .select()
          .eq('id', roleId)
          .single();

      final role = RoleModel.fromJson(roleResponse);

      // Obtener permisos del rol
      final permissionsResponse = await Supabase.instance.client
          .from(_rolePermissionsTable)
          .select('$_permissionsTable(nombre)')
          .eq('role_id', roleId);

      final permissionNames = (permissionsResponse as List)
          .map((p) => (p['permissions_repuestos'] as Map<String, dynamic>)['nombre'] as String)
          .toList();

      return role.copyWith(permissionNames: permissionNames);
    } catch (e) {
      AppConfig.logger.e('Error loading role with permissions: $e');
      return null;
    }
  }

  /// Obtiene todos los permisos del sistema
  static Future<List<PermissionModel>> getAllPermissions({String sistema = 'repuestos'}) async {
    try {
      if (!kIsWeb) return [];
      
      final response = await Supabase.instance.client
          .from(_permissionsTable)
          .select()
          .eq('sistema', sistema)
          .order('modulo', ascending: true);

      final permissions = (response as List)
          .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
          .toList();

      AppConfig.logger.i('Loaded ${permissions.length} permissions for system: $sistema');
      return permissions;
    } catch (e) {
      AppConfig.logger.e('Error loading permissions: $e');
      return [];
    }
  }

  /// Agrupa permisos por módulo
  static Future<Map<String, List<PermissionModel>>> getPermissionsByModule({String sistema = 'repuestos'}) async {
    try {
      final permissions = await getAllPermissions(sistema: sistema);
      
      final grouped = <String, List<PermissionModel>>{};
      for (var permission in permissions) {
        final modulo = permission.modulo ?? 'general';
        if (!grouped.containsKey(modulo)) {
          grouped[modulo] = [];
        }
        grouped[modulo]!.add(permission);
      }

      return grouped;
    } catch (e) {
      AppConfig.logger.e('Error grouping permissions: $e');
      return {};
    }
  }

  /// Crea un nuevo rol
  static Future<RoleModel?> createRole({
    required String nombre,
    String? descripcion,
    String sistema = 'repuestos',
  }) async {
    try {
      if (!kIsWeb) return null;
      
      AppConfig.logger.i('Creating role: $nombre in system: $sistema');
      
      final response = await Supabase.instance.client
          .from(_rolesTable)
          .insert({
            'nombre': nombre,
            'descripcion': descripcion,
            'sistema': sistema,
          })
          .select();

      final role = RoleModel.fromJson(response[0]);
      AppConfig.logger.i('Role created successfully: $nombre');
      return role;
    } catch (e) {
      AppConfig.logger.e('Error creating role: $e');
      return null;
    }
  }

  /// Actualiza un rol existente
  static Future<bool> updateRole({
    required int roleId,
    required String nombre,
    String? descripcion,
  }) async {
    try {
      if (!kIsWeb) return false;
      
      AppConfig.logger.i('Updating role: $roleId');
      
      await Supabase.instance.client
          .from(_rolesTable)
          .update({
            'nombre': nombre,
            'descripcion': descripcion,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', roleId);

      AppConfig.logger.i('Role updated successfully: $roleId');
      return true;
    } catch (e) {
      AppConfig.logger.e('Error updating role: $e');
      return false;
    }
  }

  /// Asigna permisos a un rol
  static Future<bool> assignPermissionsToRole({
    required int roleId,
    required List<int> permissionIds,
  }) async {
    try {
      if (!kIsWeb) return false;
      
      AppConfig.logger.i('Assigning ${permissionIds.length} permissions to role: $roleId');
      
      // Primero, eliminar permisos existentes
      await Supabase.instance.client
          .from(_rolePermissionsTable)
          .delete()
          .eq('role_id', roleId);

      // Luego, insertar nuevos permisos
      if (permissionIds.isNotEmpty) {
        final data = permissionIds
            .map((permId) => {'role_id': roleId, 'permission_id': permId})
            .toList();
        
        await Supabase.instance.client
            .from(_rolePermissionsTable)
            .insert(data);
      }

      AppConfig.logger.i('Permissions assigned successfully to role: $roleId');
      return true;
    } catch (e) {
      AppConfig.logger.e('Error assigning permissions: $e');
      return false;
    }
  }

  /// Elimina un rol
  static Future<bool> deleteRole(int roleId) async {
    try {
      if (!kIsWeb) return false;
      
      AppConfig.logger.i('Deleting role: $roleId');
      
      await Supabase.instance.client
          .from(_rolesTable)
          .delete()
          .eq('id', roleId);

      AppConfig.logger.i('Role deleted successfully: $roleId');
      return true;
    } catch (e) {
      AppConfig.logger.e('Error deleting role: $e');
      return false;
    }
  }

  /// Asigna un rol a un usuario
  static Future<bool> assignRoleToUser({
    required int userId,
    required int roleId,
  }) async {
    try {
      if (!kIsWeb) return false;
      
      AppConfig.logger.i('Assigning role: $roleId to user: $userId');
      
      await Supabase.instance.client
          .from(_userRolesTable)
          .insert({
            'user_id': userId,
            'role_id': roleId,
          });

      AppConfig.logger.i('Role assigned successfully to user: $userId');
      return true;
    } catch (e) {
      AppConfig.logger.e('Error assigning role to user: $e');
      return false;
    }
  }

  /// Remueve un rol de un usuario
  static Future<bool> removeRoleFromUser({
    required int userId,
    required int roleId,
  }) async {
    try {
      if (!kIsWeb) return false;
      
      AppConfig.logger.i('Removing role: $roleId from user: $userId');
      
      await Supabase.instance.client
          .from(_userRolesTable)
          .delete()
          .eq('user_id', userId)
          .eq('role_id', roleId);

      AppConfig.logger.i('Role removed successfully from user: $userId');
      return true;
    } catch (e) {
      AppConfig.logger.e('Error removing role from user: $e');
      return false;
    }
  }

  /// Obtiene los roles de un usuario
  static Future<List<RoleModel>> getUserRoles(int userId, {String sistema = 'repuestos'}) async {
    try {
      if (!kIsWeb) return [];
      
      final response = await Supabase.instance.client
          .from(_userRolesTable)
          .select('$_rolesTable(*)')
          .eq('user_id', userId);

      final roles = (response as List)
          .map((r) => RoleModel.fromJson((r['roles_repuestos'] as Map<String, dynamic>)))
          .where((role) => role.sistema == sistema)
          .toList();

      AppConfig.logger.i('Loaded ${roles.length} roles for user: $userId');
      return roles;
    } catch (e) {
      AppConfig.logger.e('Error loading user roles: $e');
      return [];
    }
  }

  /// Verifica si un usuario tiene un permiso específico
  static Future<bool> userHasPermission({
    required int userId,
    required String permissionName,
    String sistema = 'repuestos',
  }) async {
    try {
      if (!kIsWeb) return true; // En modo no-web, asumir que tiene permisos
      
      final response = await Supabase.instance.client.rpc(
        'check_user_permission',
        params: {
          'p_user_id': userId,
          'p_permission_name': permissionName,
          'p_system': sistema,
        },
      );

      return response as bool;
    } catch (e) {
      AppConfig.logger.w('Error checking permission: $e');
      return false;
    }
  }

  /// Obtiene todos los permisos de un usuario
  static Future<List<String>> getUserPermissions({
    required int userId,
    String sistema = 'repuestos',
  }) async {
    try {
      if (!kIsWeb) return [];
      
      // Obtener roles del usuario
      final userRoles = await getUserRoles(userId, sistema: sistema);
      if (userRoles.isEmpty) return [];

      final roleIds = userRoles.map((r) => r.id).toList();
      
      // Obtener permisos de esos roles
      final response = await Supabase.instance.client
          .from(_rolePermissionsTable)
          .select('$_permissionsTable(nombre)')
          .inFilter('role_id', roleIds);

      final permissions = <String>{};
      for (var item in response as List) {
        final permName = (item['permissions_repuestos'] as Map<String, dynamic>)['nombre'];
        if (permName != null) {
          permissions.add(permName as String);
        }
      }

      AppConfig.logger.i('User $userId has ${permissions.length} permissions');
      return permissions.toList();
    } catch (e) {
      AppConfig.logger.e('Error loading user permissions: $e');
      return [];
    }
  }
}
