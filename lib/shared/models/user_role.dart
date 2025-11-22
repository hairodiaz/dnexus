/// Enumeración de roles del sistema
enum UserRole {
  admin('admin', 'Administrador'),
  caja('caja', 'Cajero'),
  facturador('facturador', 'Facturador'),
  vendedor('vendedor', 'Vendedor'),
  superAdmin('super_admin', 'Super Administrador');

  const UserRole(this.value, this.displayName);
  
  final String value;
  final String displayName;

  /// Obtiene el rol desde string
  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (r) => r.value == role,
      orElse: () => UserRole.vendedor,
    );
  }

  /// Verifica si el rol tiene permisos de administrador
  bool get isAdmin => this == UserRole.admin || this == UserRole.superAdmin;

  /// Verifica si el rol puede manejar dinero
  bool get canHandleMoney => this == UserRole.admin || 
                             this == UserRole.caja || 
                             this == UserRole.superAdmin;

  /// Verifica si el rol puede facturar
  bool get canInvoice => this == UserRole.admin || 
                         this == UserRole.caja || 
                         this == UserRole.facturador || 
                         this == UserRole.superAdmin;

  /// Verifica si el rol puede gestionar inventario
  bool get canManageInventory => this == UserRole.admin || 
                                 this == UserRole.caja || 
                                 this == UserRole.superAdmin;

  /// Verifica si el rol puede recibir mercancía
  bool get canReceiveInventory => this == UserRole.admin || 
                                  this == UserRole.caja || 
                                  this == UserRole.superAdmin;

  /// Verifica si el rol puede ver reportes
  bool get canViewReports => this == UserRole.admin || 
                             this == UserRole.superAdmin;

  /// Verifica si el rol puede gestionar empleados
  bool get canManageEmployees => this == UserRole.admin || 
                                 this == UserRole.superAdmin;

  /// Verifica si el rol puede gestionar clientes
  bool get canManageClients => this != UserRole.vendedor;

  /// Verifica si el rol puede acceder a configuración
  bool get canAccessSettings => isAdmin;

  /// Obtiene el color asociado al rol
  int get colorValue {
    switch (this) {
      case UserRole.superAdmin:
        return 0xFF9C27B0; // Purple
      case UserRole.admin:
        return 0xFF2196F3; // Blue
      case UserRole.caja:
        return 0xFF4CAF50; // Green
      case UserRole.facturador:
        return 0xFFFF9800; // Orange
      case UserRole.vendedor:
        return 0xFF607D8B; // Blue Grey
    }
  }

  /// Obtiene el ícono asociado al rol
  int get iconCodePoint {
    switch (this) {
      case UserRole.superAdmin:
        return 0xe1af; // Icons.admin_panel_settings
      case UserRole.admin:
        return 0xe1af; // Icons.admin_panel_settings
      case UserRole.caja:
        return 0xe227; // Icons.point_of_sale
      case UserRole.facturador:
        return 0xe19c; // Icons.receipt_long
      case UserRole.vendedor:
        return 0xe7fd; // Icons.person
    }
  }
}

/// Modelo de permisos específicos
class Permission {
  final String id;
  final String name;
  final String description;
  final String module;

  const Permission({
    required this.id,
    required this.name,
    required this.description,
    required this.module,
  });

  static const List<Permission> allPermissions = [
    // Módulo de Transacciones
    Permission(
      id: 'transactions_view',
      name: 'Ver Transacciones',
      description: 'Puede ver la lista de transacciones',
      module: 'transactions',
    ),
    Permission(
      id: 'transactions_create',
      name: 'Crear Transacciones',
      description: 'Puede registrar nuevas transacciones',
      module: 'transactions',
    ),
    Permission(
      id: 'transactions_edit',
      name: 'Editar Transacciones',
      description: 'Puede modificar transacciones existentes',
      module: 'transactions',
    ),
    Permission(
      id: 'transactions_delete',
      name: 'Eliminar Transacciones',
      description: 'Puede eliminar transacciones',
      module: 'transactions',
    ),

    // Módulo de Clientes
    Permission(
      id: 'clients_view',
      name: 'Ver Clientes',
      description: 'Puede ver la lista de clientes',
      module: 'clients',
    ),
    Permission(
      id: 'clients_create',
      name: 'Crear Clientes',
      description: 'Puede registrar nuevos clientes',
      module: 'clients',
    ),
    Permission(
      id: 'clients_edit',
      name: 'Editar Clientes',
      description: 'Puede modificar información de clientes',
      module: 'clients',
    ),

    // Módulo de Inventario
    Permission(
      id: 'inventory_view',
      name: 'Ver Inventario',
      description: 'Puede consultar el inventario',
      module: 'inventory',
    ),
    Permission(
      id: 'inventory_create',
      name: 'Agregar Productos',
      description: 'Puede agregar nuevos productos',
      module: 'inventory',
    ),
    Permission(
      id: 'inventory_edit',
      name: 'Editar Productos',
      description: 'Puede modificar productos existentes',
      module: 'inventory',
    ),
    Permission(
      id: 'inventory_receive',
      name: 'Recibir Mercancía',
      description: 'Puede recibir y actualizar stock',
      module: 'inventory',
    ),

    // Módulo de Facturación
    Permission(
      id: 'invoicing_create',
      name: 'Crear Facturas',
      description: 'Puede crear facturas de venta',
      module: 'invoicing',
    ),
    Permission(
      id: 'invoicing_process',
      name: 'Procesar Pagos',
      description: 'Puede procesar pagos y completar ventas',
      module: 'invoicing',
    ),
    Permission(
      id: 'invoicing_cancel',
      name: 'Cancelar Facturas',
      description: 'Puede cancelar facturas',
      module: 'invoicing',
    ),

    // Módulo de Empleados
    Permission(
      id: 'employees_view',
      name: 'Ver Empleados',
      description: 'Puede ver la lista de empleados',
      module: 'employees',
    ),
    Permission(
      id: 'employees_create',
      name: 'Crear Empleados',
      description: 'Puede registrar nuevos empleados',
      module: 'employees',
    ),
    Permission(
      id: 'employees_edit',
      name: 'Editar Empleados',
      description: 'Puede modificar información de empleados',
      module: 'employees',
    ),

    // Módulo de Reportes
    Permission(
      id: 'reports_view',
      name: 'Ver Reportes',
      description: 'Puede acceder a los reportes',
      module: 'reports',
    ),
    Permission(
      id: 'reports_consolidated',
      name: 'Reportes Consolidados',
      description: 'Puede ver reportes de todos los negocios',
      module: 'reports',
    ),

    // Módulo de Configuración
    Permission(
      id: 'settings_view',
      name: 'Ver Configuración',
      description: 'Puede acceder a la configuración',
      module: 'settings',
    ),
    Permission(
      id: 'settings_edit',
      name: 'Editar Configuración',
      description: 'Puede modificar configuraciones del sistema',
      module: 'settings',
    ),
  ];

  /// Obtiene permisos por módulo
  static List<Permission> getPermissionsByModule(String module) {
    return allPermissions.where((p) => p.module == module).toList();
  }

  /// Obtiene todos los módulos únicos
  static List<String> getAllModules() {
    return allPermissions.map((p) => p.module).toSet().toList();
  }
}

/// Clase para manejar permisos por rol
class RolePermissions {
  static const Map<UserRole, List<String>> _rolePermissions = {
    UserRole.superAdmin: [
      // Acceso completo a todo
      'transactions_view', 'transactions_create', 'transactions_edit', 'transactions_delete',
      'clients_view', 'clients_create', 'clients_edit',
      'inventory_view', 'inventory_create', 'inventory_edit', 'inventory_receive',
      'invoicing_create', 'invoicing_process', 'invoicing_cancel',
      'employees_view', 'employees_create', 'employees_edit',
      'reports_view', 'reports_consolidated',
      'settings_view', 'settings_edit',
    ],

    UserRole.admin: [
      // Control total del negocio específico
      'transactions_view', 'transactions_create', 'transactions_edit', 'transactions_delete',
      'clients_view', 'clients_create', 'clients_edit',
      'inventory_view', 'inventory_create', 'inventory_edit', 'inventory_receive',
      'invoicing_create', 'invoicing_process', 'invoicing_cancel',
      'employees_view', 'employees_create', 'employees_edit',
      'reports_view',
      'settings_view', 'settings_edit',
    ],

    UserRole.caja: [
      // Facturación completa + inventario
      'transactions_view', 'transactions_create', // Solo transacciones propias
      'clients_view', 'clients_create', 'clients_edit',
      'inventory_view', 'inventory_receive', // Puede recibir mercancía
      'invoicing_create', 'invoicing_process', 'invoicing_cancel',
    ],

    UserRole.facturador: [
      // Solo facturación, no puede cobrar
      'clients_view', 'clients_create', 'clients_edit',
      'inventory_view', // Solo consulta de stock
      'invoicing_create', // Puede crear pero no procesar pagos
    ],

    UserRole.vendedor: [
      // Consulta básica
      'clients_view',
      'inventory_view',
    ],
  };

  /// Verifica si un rol tiene un permiso específico
  static bool hasPermission(UserRole role, String permission) {
    final permissions = _rolePermissions[role] ?? [];
    return permissions.contains(permission);
  }

  /// Obtiene todos los permisos de un rol
  static List<String> getPermissions(UserRole role) {
    return _rolePermissions[role] ?? [];
  }

  /// Verifica si un rol puede acceder a un módulo
  static bool canAccessModule(UserRole role, String module) {
    final permissions = getPermissions(role);
    final modulePermissions = Permission.getPermissionsByModule(module);
    
    return modulePermissions.any((perm) => permissions.contains(perm.id));
  }

  /// Obtiene los módulos accesibles para un rol
  static List<String> getAccessibleModules(UserRole role) {
    final modules = Permission.getAllModules();
    return modules.where((module) => canAccessModule(role, module)).toList();
  }
}

/// Clase de utilidades para verificación de permisos
class PermissionChecker {
  static bool canViewTransactions(UserRole role) =>
      RolePermissions.hasPermission(role, 'transactions_view');

  static bool canCreateTransactions(UserRole role) =>
      RolePermissions.hasPermission(role, 'transactions_create');

  static bool canEditTransactions(UserRole role) =>
      RolePermissions.hasPermission(role, 'transactions_edit');

  static bool canDeleteTransactions(UserRole role) =>
      RolePermissions.hasPermission(role, 'transactions_delete');

  static bool canManageClients(UserRole role) =>
      RolePermissions.hasPermission(role, 'clients_create') ||
      RolePermissions.hasPermission(role, 'clients_edit');

  static bool canManageInventory(UserRole role) =>
      RolePermissions.hasPermission(role, 'inventory_create') ||
      RolePermissions.hasPermission(role, 'inventory_edit');

  static bool canReceiveInventory(UserRole role) =>
      RolePermissions.hasPermission(role, 'inventory_receive');

  static bool canCreateInvoices(UserRole role) =>
      RolePermissions.hasPermission(role, 'invoicing_create');

  static bool canProcessPayments(UserRole role) =>
      RolePermissions.hasPermission(role, 'invoicing_process');

  static bool canManageEmployees(UserRole role) =>
      RolePermissions.hasPermission(role, 'employees_create') ||
      RolePermissions.hasPermission(role, 'employees_edit');

  static bool canViewReports(UserRole role) =>
      RolePermissions.hasPermission(role, 'reports_view');

  static bool canViewConsolidatedReports(UserRole role) =>
      RolePermissions.hasPermission(role, 'reports_consolidated');

  static bool canAccessSettings(UserRole role) =>
      RolePermissions.hasPermission(role, 'settings_view');
}