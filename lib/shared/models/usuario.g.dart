// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Usuario _$UsuarioFromJson(Map<String, dynamic> json) => Usuario(
  id: (json['id'] as num?)?.toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  passwordHash: json['password_hash'] as String,
  nombreCompleto: json['nombre_completo'] as String,
  rolSistema:
      $enumDecodeNullable(_$RolSistemaEnumMap, json['rol_sistema']) ??
      RolSistema.usuario,
  activo: json['activo'] as bool? ?? true,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UsuarioToJson(Usuario instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'password_hash': instance.passwordHash,
  'nombre_completo': instance.nombreCompleto,
  'rol_sistema': _$RolSistemaEnumMap[instance.rolSistema]!,
  'activo': instance.activo,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$RolSistemaEnumMap = {
  RolSistema.superAdmin: 'super_admin',
  RolSistema.adminNegocio: 'admin_negocio',
  RolSistema.usuario: 'usuario',
};
