// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoleModel _$RoleModelFromJson(Map<String, dynamic> json) => RoleModel(
  id: json['id'] as int,
  negocioId: json['negocio_id'] as int,
  nombre: json['nombre'] as String,
  descripcion: json['descripcion'] as String?,
  estado: json['estado'] as bool? ?? true,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  moduloIds: (json['modulo_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ??
      const [],
);

Map<String, dynamic> _$RoleModelToJson(RoleModel instance) => <String, dynamic>{
  'id': instance.id,
  'negocio_id': instance.negocioId,
  'nombre': instance.nombre,
  'descripcion': instance.descripcion,
  'estado': instance.estado,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'modulo_ids': instance.moduloIds,
};
