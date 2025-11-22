import 'package:json_annotation/json_annotation.dart';

part 'usuario.g.dart';

/// Enum para roles del sistema
enum RolSistema {
  @JsonValue('super_admin')
  superAdmin,
  @JsonValue('admin_negocio')
  adminNegocio,
  @JsonValue('usuario')
  usuario,
}

/// Modelo de Usuario para D-Nexus
@JsonSerializable()
class Usuario {
  final int? id;
  final String username;
  final String email;
  @JsonKey(name: 'password_hash')
  final String passwordHash;
  @JsonKey(name: 'nombre_completo')
  final String nombreCompleto;
  @JsonKey(name: 'rol_sistema')
  final RolSistema rolSistema;
  final bool activo;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Usuario({
    this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.nombreCompleto,
    this.rolSistema = RolSistema.usuario,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor para crear desde JSON
  factory Usuario.fromJson(Map<String, dynamic> json) => _$UsuarioFromJson(json);

  /// Convertir a JSON
  Map<String, dynamic> toJson() => _$UsuarioToJson(this);

  /// Crear copia con campos modificados
  Usuario copyWith({
    int? id,
    String? username,
    String? email,
    String? passwordHash,
    String? nombreCompleto,
    RolSistema? rolSistema,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Usuario(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      rolSistema: rolSistema ?? this.rolSistema,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verificar si es super administrador
  bool get isSuperAdmin => rolSistema == RolSistema.superAdmin;

  /// Verificar si es administrador de negocio
  bool get isAdminNegocio => rolSistema == RolSistema.adminNegocio;

  @override
  String toString() => 'Usuario(id: $id, username: $username, nombreCompleto: $nombreCompleto)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Usuario && other.id == id && other.username == username;
  }

  @override
  int get hashCode => Object.hash(id, username);
}