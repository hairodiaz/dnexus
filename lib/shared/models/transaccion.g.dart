// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaccion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaccion _$TransaccionFromJson(Map<String, dynamic> json) => Transaccion(
  id: (json['id'] as num?)?.toInt(),
  negocioId: (json['negocio_id'] as num).toInt(),
  usuarioId: (json['usuario_id'] as num?)?.toInt(),
  concepto: json['concepto'] as String,
  monto: (json['monto'] as num).toDouble(),
  tipo: $enumDecode(_$TipoTransaccionEnumMap, json['tipo']),
  categoria: json['categoria'] as String?,
  fecha: DateTime.parse(json['fecha'] as String),
  notas: json['notas'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$TransaccionToJson(Transaccion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'negocio_id': instance.negocioId,
      'usuario_id': instance.usuarioId,
      'concepto': instance.concepto,
      'monto': instance.monto,
      'tipo': _$TipoTransaccionEnumMap[instance.tipo]!,
      'categoria': instance.categoria,
      'fecha': instance.fecha.toIso8601String(),
      'notas': instance.notas,
      'metadata': instance.metadata,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$TipoTransaccionEnumMap = {
  TipoTransaccion.ingreso: 'ingreso',
  TipoTransaccion.egreso: 'egreso',
};
