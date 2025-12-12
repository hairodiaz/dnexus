import '../models/employee_model.dart';
import '../models/user_role.dart';

/// Servicio para gestionar empleados del sistema multi-negocio
class EmployeeService {
  static List<EmployeeModel> _employees = [];
  static bool _initialized = false;

  /// Inicializa el servicio con datos de muestra
  static void initialize() {
    if (_initialized) return;
    
    _employees = _generateSampleEmployees();
    _initialized = true;
  }

  /// Obtiene todos los empleados
  static List<EmployeeModel> getAllEmployees() {
    initialize();
    return List.from(_employees);
  }

  /// Obtiene empleados por negocio
  static List<EmployeeModel> getEmployeesByBusiness(String businessId) {
    initialize();
    return _employees.where((e) => e.businessId == businessId).toList();
  }

  /// Obtiene empleados activos
  static List<EmployeeModel> getActiveEmployees([String? businessId]) {
    initialize();
    var employees = _employees.where((e) => e.isActive);
    if (businessId != null) {
      employees = employees.where((e) => e.businessId == businessId);
    }
    return employees.toList();
  }

  /// Obtiene empleados por rol
  static List<EmployeeModel> getEmployeesByRole(UserRole role, [String? businessId]) {
    initialize();
    var employees = _employees.where((e) => e.role == role);
    if (businessId != null) {
      employees = employees.where((e) => e.businessId == businessId);
    }
    return employees.toList();
  }

  /// Buscar empleados por nombre o cédula
  static List<EmployeeModel> searchEmployees(String query, [String? businessId]) {
    initialize();
    if (query.isEmpty) {
      return businessId != null 
          ? getEmployeesByBusiness(businessId)
          : getAllEmployees();
    }

    final lowerQuery = query.toLowerCase();
    var results = _employees.where((employee) {
      return employee.fullName.toLowerCase().contains(lowerQuery) ||
             employee.cedula.contains(query);
    });

    if (businessId != null) {
      results = results.where((e) => e.businessId == businessId);
    }

    return results.toList();
  }

  /// Filtrar empleados
  static List<EmployeeModel> filterEmployees({
    EmployeeFilter filter = EmployeeFilter.all,
    UserRole? filterRole,
    String? businessId,
  }) {
    initialize();
    var employees = businessId != null 
        ? getEmployeesByBusiness(businessId)
        : getAllEmployees();

    switch (filter) {
      case EmployeeFilter.active:
        employees = employees.where((e) => e.isActive).toList();
        break;
      case EmployeeFilter.inactive:
        employees = employees.where((e) => !e.isActive).toList();
        break;
      case EmployeeFilter.byRole:
        if (filterRole != null) {
          employees = employees.where((e) => e.role == filterRole).toList();
        }
        break;
      case EmployeeFilter.all:
        break;
    }

    return employees;
  }

  /// Ordenar empleados
  static List<EmployeeModel> sortEmployees(
    List<EmployeeModel> employees, 
    EmployeeSortBy sortBy, {
    bool ascending = true,
  }) {
    final sorted = List<EmployeeModel>.from(employees);

    switch (sortBy) {
      case EmployeeSortBy.name:
        sorted.sort((a, b) => ascending 
            ? a.fullName.compareTo(b.fullName)
            : b.fullName.compareTo(a.fullName));
        break;
      case EmployeeSortBy.hireDate:
        sorted.sort((a, b) => ascending 
            ? a.hireDate.compareTo(b.hireDate)
            : b.hireDate.compareTo(a.hireDate));
        break;
      case EmployeeSortBy.salary:
        sorted.sort((a, b) => ascending 
            ? a.baseSalary.compareTo(b.baseSalary)
            : b.baseSalary.compareTo(a.baseSalary));
        break;
      case EmployeeSortBy.role:
        sorted.sort((a, b) => ascending 
            ? a.roleDisplayName.compareTo(b.roleDisplayName)
            : b.roleDisplayName.compareTo(a.roleDisplayName));
        break;
    }

    return sorted;
  }

  /// Agregar empleado
  static EmployeeModel addEmployee({
    required String fullName,
    required String cedula,
    String? phone,
    String? email,
    required UserRole role,
    DateTime? hireDate,
    required double baseSalary,
    required String businessId,
    String? notes,
  }) {
    final now = DateTime.now();
    final employee = EmployeeModel(
      id: 'emp_${now.millisecondsSinceEpoch}',
      fullName: fullName,
      cedula: cedula,
      phone: phone,
      email: email,
      role: role,
      hireDate: hireDate ?? now,
      baseSalary: baseSalary,
      businessId: businessId,
      createdAt: now,
      updatedAt: now,
      notes: notes,
    );

    _employees.add(employee);
    return employee;
  }

  /// Actualizar empleado
  static EmployeeModel? updateEmployee(
    String employeeId,
    EmployeeModel updatedEmployee,
  ) {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index != -1) {
      _employees[index] = updatedEmployee.copyWith(
        updatedAt: DateTime.now(),
      );
      return _employees[index];
    }
    return null;
  }

  /// Cambiar estado del empleado (activar/desactivar)
  static bool toggleEmployeeStatus(String employeeId) {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index != -1) {
      _employees[index] = _employees[index].copyWith(
        isActive: !_employees[index].isActive,
        updatedAt: DateTime.now(),
      );
      return true;
    }
    return false;
  }

  /// Eliminar empleado (solo SuperAdmin)
  static bool deleteEmployee(String employeeId) {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index != -1) {
      _employees.removeAt(index);
      return true;
    }
    return false;
  }

  /// Obtener empleado por ID
  static EmployeeModel? getEmployeeById(String id) {
    initialize();
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Verificar si cédula ya existe
  static bool cedulaExists(String cedula, [String? excludeEmployeeId]) {
    initialize();
    return _employees.any((e) => 
        e.cedula == cedula && e.id != excludeEmployeeId);
  }

  /// Obtener estadísticas de empleados
  static Map<String, dynamic> getEmployeeStats([String? businessId]) {
    initialize();
    final employees = businessId != null 
        ? getEmployeesByBusiness(businessId)
        : getAllEmployees();

    final active = employees.where((e) => e.isActive).length;
    final inactive = employees.length - active;
    
    final roleStats = <UserRole, int>{};
    for (final role in UserRole.values) {
      roleStats[role] = employees.where((e) => e.role == role).length;
    }

    final totalSalaries = employees
        .where((e) => e.isActive)
        .fold<double>(0, (sum, e) => sum + e.baseSalary);

    return {
      'total': employees.length,
      'active': active,
      'inactive': inactive,
      'byRole': roleStats,
      'totalPayroll': totalSalaries,
      'averageSalary': employees.isNotEmpty ? totalSalaries / active : 0,
    };
  }

  /// Generar datos de muestra para desarrollo
  static List<EmployeeModel> _generateSampleEmployees() {
    // Clean system mode - no sample employees
    return [];
  }
}