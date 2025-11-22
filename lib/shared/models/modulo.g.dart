// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modulo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Modulo _$ModuloFromJson(Map<String, dynamic> json) => Modulo(
  id: (json['id'] as num?)?.toInt(),
  nombre: json['nombre'] as String,
  codigo: json['codigo'] as String,
  descripcion: json['descripcion'] as String?,
  icono: json['icono'] as String?,
  activo: json['activo'] as bool? ?? true,
  version: json['version'] as String? ?? '1.0',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ModuloToJson(Modulo instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'codigo': instance.codigo,
  'descripcion': instance.descripcion,
  'icono': instance.icono,
  'activo': instance.activo,
  'version': instance.version,
  'created_at': instance.createdAt?.toIso8601String(),
};
