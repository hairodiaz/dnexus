import 'user_model.dart';
import 'user_role.dart';

/// Extensión del UserModel para integrar el sistema de roles
extension UserRoleExtension on UserModel {
  /// Obtiene el rol del usuario como enum
  UserRole get userRole => UserRole.fromString(role);

  /// Verifica si el usuario tiene un permiso específico
  bool hasPermission(String permission) {
    return RolePermissions.hasPermission(userRole, permission);
  }

  /// Verifica si el usuario puede acceder a un módulo
  bool canAccessModule(String module) {
    return RolePermissions.canAccessModule(userRole, module);
  }

  /// Obtiene todos los módulos accesibles para el usuario
  List<String> get accessibleModules {
    return RolePermissions.getAccessibleModules(userRole);
  }

  /// Verifica si es administrador
  bool get isAdmin => userRole.isAdmin;

  /// Verifica si puede manejar dinero
  bool get canHandleMoney => userRole.canHandleMoney;

  /// Verifica si puede facturar
  bool get canInvoice => userRole.canInvoice;

  /// Verifica si puede gestionar inventario
  bool get canManageInventory => userRole.canManageInventory;

  /// Verifica si puede recibir mercancía
  bool get canReceiveInventory => userRole.canReceiveInventory;

  /// Verifica si puede ver reportes
  bool get canViewReports => userRole.canViewReports;

  /// Verifica si puede gestionar empleados
  bool get canManageEmployees => userRole.canManageEmployees;

  /// Verifica si puede gestionar clientes
  bool get canManageClients => userRole.canManageClients;

  /// Verifica si puede acceder a configuración
  bool get canAccessSettings => userRole.canAccessSettings;

  /// Obtiene el color del rol
  int get roleColor => userRole.colorValue;

  /// Obtiene el ícono del rol
  int get roleIcon => userRole.iconCodePoint;

  /// Obtiene el nombre display del rol
  String get roleDisplayName => userRole.displayName;
}

/// Utilidades para verificaciones rápidas de permisos
class UserPermissionUtils {
  /// Verifica múltiples permisos a la vez
  static bool hasAllPermissions(UserModel user, List<String> permissions) {
    return permissions.every((permission) => user.hasPermission(permission));
  }

  /// Verifica si tiene al menos uno de los permisos
  static bool hasAnyPermission(UserModel user, List<String> permissions) {
    return permissions.any((permission) => user.hasPermission(permission));
  }

  /// Verifica si puede realizar una acción específica
  static bool canPerformAction(UserModel user, String action) {
    switch (action) {
      case 'create_transaction':
        return PermissionChecker.canCreateTransactions(user.userRole);
      case 'edit_transaction':
        return PermissionChecker.canEditTransactions(user.userRole);
      case 'delete_transaction':
        return PermissionChecker.canDeleteTransactions(user.userRole);
      case 'manage_clients':
        return PermissionChecker.canManageClients(user.userRole);
      case 'manage_inventory':
        return PermissionChecker.canManageInventory(user.userRole);
      case 'receive_inventory':
        return PermissionChecker.canReceiveInventory(user.userRole);
      case 'create_invoices':
        return PermissionChecker.canCreateInvoices(user.userRole);
      case 'process_payments':
        return PermissionChecker.canProcessPayments(user.userRole);
      case 'manage_employees':
        return PermissionChecker.canManageEmployees(user.userRole);
      case 'view_reports':
        return PermissionChecker.canViewReports(user.userRole);
      case 'view_consolidated_reports':
        return PermissionChecker.canViewConsolidatedReports(user.userRole);
      case 'access_settings':
        return PermissionChecker.canAccessSettings(user.userRole);
      default:
        return false;
    }
  }

  /// Obtiene las acciones disponibles para un usuario
  static List<String> getAvailableActions(UserModel user) {
    final actions = <String>[];
    
    if (user.hasPermission('transactions_create')) actions.add('create_transaction');
    if (user.hasPermission('transactions_edit')) actions.add('edit_transaction');
    if (user.hasPermission('transactions_delete')) actions.add('delete_transaction');
    if (user.hasPermission('clients_create')) actions.add('manage_clients');
    if (user.hasPermission('inventory_create')) actions.add('manage_inventory');
    if (user.hasPermission('inventory_receive')) actions.add('receive_inventory');
    if (user.hasPermission('invoicing_create')) actions.add('create_invoices');
    if (user.hasPermission('invoicing_process')) actions.add('process_payments');
    if (user.hasPermission('employees_create')) actions.add('manage_employees');
    if (user.hasPermission('reports_view')) actions.add('view_reports');
    if (user.hasPermission('reports_consolidated')) actions.add('view_consolidated_reports');
    if (user.hasPermission('settings_view')) actions.add('access_settings');
    
    return actions;
  }
}