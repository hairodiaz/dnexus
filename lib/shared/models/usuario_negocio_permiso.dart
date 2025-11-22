import 'package:json_annotation/json_annotation.dart';

part 'usuario_negocio_permiso.g.dart';

/// Enum para roles en negocio
enum RolNegocio {
  @JsonValue('propietario')
  propietario,
  @JsonValue('admin')
  admin,
  @JsonValue('editor')
  editor,
  @JsonValue('viewer')
  viewer,
  @JsonValue('contador')
  contador,
}

/// Modelo de permisos de usuario por negocio
@JsonSerializable()
class UsuarioNegocioPermiso {
  final int? id;
  @JsonKey(name: 'usuario_id')
  final int usuarioId;
  @JsonKey(name: 'negocio_id')
  final int negocioId;
  final RolNegocio rol;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const UsuarioNegocioPermiso({
    this.id,
    required this.usuarioId,
    required this.negocioId,
    required this.rol,
    this.createdAt,
  });

  /// Factory constructor para crear desde JSON
  factory UsuarioNegocioPermiso.fromJson(Map<String, dynamic> json) => 
      _$UsuarioNegocioPermisoFromJson(json);

  /// Convertir a JSON
  Map<String, dynamic> toJson() => _$UsuarioNegocioPermisoToJson(this);

  /// Crear copia con campos modificados
  UsuarioNegocioPermiso copyWith({
    int? id,
    int? usuarioId,
    int? negocioId,
    RolNegocio? rol,
    DateTime? createdAt,
  }) {
    return UsuarioNegocioPermiso(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      negocioId: negocioId ?? this.negocioId,
      rol: rol ?? this.rol,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Obtener nombre del rol
  String get rolNombre {
    switch (rol) {
      case RolNegocio.propietario:
        return 'Propietario';
      case RolNegocio.admin:
        return 'Administrador';
      case RolNegocio.editor:
        return 'Editor';
      case RolNegocio.viewer:
        return 'Solo lectura';
      case RolNegocio.contador:
        return 'Contador';
    }
  }

  /// Verificar si puede crear/editar
  bool get puedeEditar => [RolNegocio.propietario, RolNegocio.admin, RolNegocio.editor].contains(rol);

  /// Verificar si puede eliminar
  bool get puedeEliminar => [RolNegocio.propietario, RolNegocio.admin].contains(rol);

  /// Verificar si puede gestionar usuarios
  bool get puedeGestionarUsuarios => [RolNegocio.propietario, RolNegocio.admin].contains(rol);

  @override
  String toString() => 'UsuarioNegocioPermiso(usuarioId: $usuarioId, negocioId: $negocioId, rol: $rol)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsuarioNegocioPermiso && 
           other.usuarioId == usuarioId && 
           other.negocioId == negocioId;
  }

  @override
  int get hashCode => Object.hash(usuarioId, negocioId);
}