// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'negocio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Negocio _$NegocioFromJson(Map<String, dynamic> json) => Negocio(
  id: (json['id'] as num?)?.toInt(),
  nombre: json['nombre'] as String,
  tipo: $enumDecode(_$TipoNegocioEnumMap, json['tipo']),
  descripcion: json['descripcion'] as String?,
  propietarioId: (json['propietario_id'] as num?)?.toInt(),
  activo: json['activo'] as bool? ?? true,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$NegocioToJson(Negocio instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'tipo': _$TipoNegocioEnumMap[instance.tipo]!,
  'descripcion': instance.descripcion,
  'propietario_id': instance.propietarioId,
  'activo': instance.activo,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$TipoNegocioEnumMap = {
  TipoNegocio.repuestos: 'repuestos',
  TipoNegocio.prestamos: 'prestamos',
  TipoNegocio.electrodomesticos: 'electrodomesticos',
};
