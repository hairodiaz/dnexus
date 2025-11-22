import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_extensions.dart';
import '../models/user_role.dart';

/// Widget condicional que se muestra basado en permisos del usuario
class PermissionWidget extends StatelessWidget {
  final UserModel user;
  final String? requiredPermission;
  final List<String>? requiredPermissions;
  final UserRole? requiredRole;
  final List<UserRole>? allowedRoles;
  final Widget child;
  final Widget? fallback;
  final bool requireAll; // Para requiredPermissions: true = AND, false = OR

  const PermissionWidget({
    Key? key,
    required this.user,
    this.requiredPermission,
    this.requiredPermissions,
    this.requiredRole,
    this.allowedRoles,
    required this.child,
    this.fallback,
    this.requireAll = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (_hasPermission()) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }

  bool _hasPermission() {
    // Verificar rol específico
    if (requiredRole != null) {
      return user.userRole == requiredRole;
    }

    // Verificar roles permitidos
    if (allowedRoles != null && allowedRoles!.isNotEmpty) {
      return allowedRoles!.contains(user.userRole);
    }

    // Verificar permiso único
    if (requiredPermission != null) {
      return user.hasPermission(requiredPermission!);
    }

    // Verificar múltiples permisos
    if (requiredPermissions != null && requiredPermissions!.isNotEmpty) {
      if (requireAll) {
        return UserPermissionUtils.hasAllPermissions(user, requiredPermissions!);
      } else {
        return UserPermissionUtils.hasAnyPermission(user, requiredPermissions!);
      }
    }

    return true; // Si no hay restricciones, mostrar siempre
  }
}

/// Widget para mostrar información del rol del usuario
class ProfileCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const ProfileCard({
    Key? key,
    required this.user,
    this.onTap,
  }) : super(key: key);

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.admin_panel_settings;
      case UserRole.admin:
        return Icons.manage_accounts;
      case UserRole.caja:
        return Icons.point_of_sale;
      case UserRole.facturador:
        return Icons.receipt_long;
      case UserRole.vendedor:
        return Icons.store;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          _getRoleIcon(user.userRole),
          color: Color(user.roleColor),
          size: 32,
        ),
        title: Text(
          user.fullName ?? user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.roleDisplayName,
              style: TextStyle(
                color: Color(user.roleColor),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: user.isActive
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.cancel, color: Colors.red),
        onTap: onTap,
      ),
    );
  }
}

/// Widget para mostrar permisos del usuario
class UserPermissionsView extends StatelessWidget {
  final UserModel user;

  const UserPermissionsView({
    Key? key,
    required this.user,
  }) : super(key: key);

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.admin_panel_settings;
      case UserRole.admin:
        return Icons.manage_accounts;
      case UserRole.caja:
        return Icons.point_of_sale;
      case UserRole.facturador:
        return Icons.receipt_long;
      case UserRole.vendedor:
        return Icons.store;
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = RolePermissions.getPermissions(user.userRole);
    final permissionObjects = Permission.allPermissions
        .where((p) => permissions.contains(p.id))
        .toList();

    // Agrupar por módulo
    final groupedPermissions = <String, List<Permission>>{};
    for (final permission in permissionObjects) {
      groupedPermissions.putIfAbsent(permission.module, () => []).add(permission);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con información del rol
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(user.roleColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(user.roleColor).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                _getRoleIcon(user.userRole),
                color: Color(user.roleColor),
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.roleDisplayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(user.roleColor),
                      ),
                    ),
                    Text(
                      '${permissions.length} permisos asignados',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Lista de permisos por módulo
        ...groupedPermissions.entries.map((entry) => 
          _buildModuleSection(context, entry.key, entry.value)
        ),
      ],
    );
  }

  Widget _buildModuleSection(BuildContext context, String module, List<Permission> permissions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getModuleDisplayName(module),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...permissions.map((permission) => 
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.check, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(permission.name),
                ),
              ],
            ),
          )
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getModuleDisplayName(String module) {
    switch (module) {
      case 'transactions': return 'Transacciones';
      case 'clients': return 'Clientes';
      case 'inventory': return 'Inventario';
      case 'invoicing': return 'Facturación';
      case 'employees': return 'Empleados';
      case 'reports': return 'Reportes';
      case 'settings': return 'Configuración';
      default: return module.toUpperCase();
    }
  }
}

/// Mixin para usar en páginas que requieren verificación de permisos
mixin PermissionMixin<T extends StatefulWidget> on State<T> {
  /// Verifica si el usuario actual tiene un permiso
  bool hasPermission(UserModel user, String permission) {
    return user.hasPermission(permission);
  }

  /// Muestra error de permisos
  void showPermissionError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No tienes permisos para realizar esta acción'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Verifica permisos antes de ejecutar acción
  bool checkPermissionOrError(BuildContext context, UserModel user, String permission) {
    if (user.hasPermission(permission)) {
      return true;
    }
    showPermissionError(context);
    return false;
  }
}