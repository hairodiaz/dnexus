// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario_negocio_permiso.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsuarioNegocioPermiso _$UsuarioNegocioPermisoFromJson(
  Map<String, dynamic> json,
) => UsuarioNegocioPermiso(
  id: (json['id'] as num?)?.toInt(),
  usuarioId: (json['usuario_id'] as num).toInt(),
  negocioId: (json['negocio_id'] as num).toInt(),
  rol: $enumDecode(_$RolNegocioEnumMap, json['rol']),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$UsuarioNegocioPermisoToJson(
  UsuarioNegocioPermiso instance,
) => <String, dynamic>{
  'id': instance.id,
  'usuario_id': instance.usuarioId,
  'negocio_id': instance.negocioId,
  'rol': _$RolNegocioEnumMap[instance.rol]!,
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$RolNegocioEnumMap = {
  RolNegocio.propietario: 'propietario',
  RolNegocio.admin: 'admin',
  RolNegocio.editor: 'editor',
  RolNegocio.viewer: 'viewer',
  RolNegocio.contador: 'contador',
};
