import '../models/user_role.dart';

/// Modelo para empleados del sistema multi-negocio
class EmployeeModel {
  final String id;
  final String fullName;
  final String cedula;
  final String? phone;
  final String? email;
  final UserRole role; // Cargo en el sistema
  final DateTime hireDate;
  final double baseSalary;
  final bool isActive;
  final String businessId; // ID del negocio al que pertenece
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes; // Notas adicionales

  EmployeeModel({
    required this.id,
    required this.fullName,
    required this.cedula,
    this.phone,
    this.email,
    required this.role,
    required this.hireDate,
    required this.baseSalary,
    this.isActive = true,
    required this.businessId,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  /// Obtiene el nombre del cargo/rol para mostrar
  String get roleDisplayName {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Administrador';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.caja:
        return 'Cajero';
      case UserRole.facturador:
        return 'Facturador';
      case UserRole.vendedor:
        return 'Vendedor';
    }
  }

  /// Color del rol para UI
  int get roleColor {
    switch (role) {
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

  /// Años de trabajo calculados desde fecha de ingreso
  int get yearsOfWork {
    final now = DateTime.now();
    final difference = now.difference(hireDate);
    return (difference.inDays / 365).floor();
  }

  /// Meses de trabajo calculados
  int get monthsOfWork {
    final now = DateTime.now();
    final years = yearsOfWork;
    final remainingDays = now.difference(hireDate).inDays - (years * 365);
    return (remainingDays / 30).floor();
  }

  /// Tiempo de trabajo formateado
  String get workTimeFormatted {
    final years = yearsOfWork;
    final months = monthsOfWork;
    
    if (years > 0 && months > 0) {
      return '$years años, $months meses';
    } else if (years > 0) {
      return '$years año${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      return '$months mes${months > 1 ? 'es' : ''}';
    } else {
      final days = DateTime.now().difference(hireDate).inDays;
      return '$days día${days > 1 ? 's' : ''}';
    }
  }

  /// Estado formateado para mostrar en UI
  String get statusDisplay => isActive ? 'Activo' : 'Inactivo';

  /// Salario formateado para mostrar
  String get salaryFormatted {
    return '\$${baseSalary.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  /// Crea una copia del empleado con campos actualizados
  EmployeeModel copyWith({
    String? id,
    String? fullName,
    String? cedula,
    String? phone,
    String? email,
    UserRole? role,
    DateTime? hireDate,
    double? baseSalary,
    bool? isActive,
    String? businessId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      cedula: cedula ?? this.cedula,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      hireDate: hireDate ?? this.hireDate,
      baseSalary: baseSalary ?? this.baseSalary,
      isActive: isActive ?? this.isActive,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  /// Convierte el modelo a Map para almacenamiento
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'cedula': cedula,
      'phone': phone,
      'email': email,
      'role': role.toString(),
      'hireDate': hireDate.toIso8601String(),
      'baseSalary': baseSalary,
      'isActive': isActive,
      'businessId': businessId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
    };
  }

  /// Crea un modelo desde Map
  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'],
      fullName: json['fullName'],
      cedula: json['cedula'],
      phone: json['phone'],
      email: json['email'],
      role: UserRole.values.firstWhere(
        (role) => role.toString() == json['role'],
      ),
      hireDate: DateTime.parse(json['hireDate']),
      baseSalary: json['baseSalary'].toDouble(),
      isActive: json['isActive'],
      businessId: json['businessId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      notes: json['notes'],
    );
  }

  @override
  String toString() {
    return 'EmployeeModel{id: $id, fullName: $fullName, cedula: $cedula, role: $role, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmployeeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Filtros para búsqueda de empleados
enum EmployeeFilter {
  all,
  active,
  inactive,
  byRole,
}

/// Ordenamiento de empleados
enum EmployeeSortBy {
  name,
  hireDate,
  salary,
  role,
}