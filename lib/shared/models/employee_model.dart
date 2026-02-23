import 'role_model.dart';

/// Modelo para representar un empleado de un negocio
class EmployeeModel {
  final int id;
  final int negocioId;
  final String nombre;
  final String? numeroDocumento;
  final String? email;
  final String? telefono;
  final String? cargo;
  final bool estado;
  final DateTime createdAt;
  final DateTime? updatedAt;

  List<RoleModel> roles;
  bool? tieneUsuarioSistema; // Si tiene credenciales de login
  int? usuarioId; // ID del usuario del sistema (si existe)

  EmployeeModel({
    required this.id,
    required this.negocioId,
    required this.nombre,
    this.numeroDocumento,
    this.email,
    this.telefono,
    this.cargo,
    required this.estado,
    required this.createdAt,
    this.updatedAt,
    this.roles = const [],
    this.tieneUsuarioSistema = false,
    this.usuarioId,
  });

  /// Convertir desde JSON (Supabase)
  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as int,
      negocioId: json['negocio_id'] as int,
      nombre: json['nombre'] as String,
      numeroDocumento: json['numero_documento'] as String?,
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      cargo: json['cargo'] as String?,
      estado: json['estado'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((r) => RoleModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      tieneUsuarioSistema: json['tiene_usuario_sistema'] as bool? ?? false,
      usuarioId: json['usuario_id'] as int?,
    );
  }

  /// Convertir desde Map
  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel.fromJson(map);
  }

  /// Convertir a Map para Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'negocio_id': negocioId,
      'nombre': nombre,
      'numero_documento': numeroDocumento,
      'email': email,
      'telefono': telefono,
      'cargo': cargo,
      'estado': estado,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Obtener lista de IDs de roles
  List<int> get roleIds => roles.map((r) => r.id).toList();

  /// Obtener todos los módulos permitidos (unión de todos los roles)
  List<int> get moduloIdsPermitidos {
    final Set<int> modulos = {};
    for (var role in roles) {
      modulos.addAll(role.moduloIds);
    }
    return modulos.toList();
  }

  /// Copiar con cambios
  EmployeeModel copyWith({
    int? id,
    int? negocioId,
    String? nombre,
    String? numeroDocumento,
    String? email,
    String? telefono,
    String? cargo,
    bool? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RoleModel>? roles,
    bool? tieneUsuarioSistema,
    int? usuarioId,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      negocioId: negocioId ?? this.negocioId,
      nombre: nombre ?? this.nombre,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      cargo: cargo ?? this.cargo,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roles: roles ?? this.roles,
      tieneUsuarioSistema: tieneUsuarioSistema ?? this.tieneUsuarioSistema,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }

  @override
  String toString() =>
      'EmployeeModel(id: $id, nombre: $nombre, negocioId: $negocioId, estado: $estado)';
}