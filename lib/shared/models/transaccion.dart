import 'package:json_annotation/json_annotation.dart';

part 'transaccion.g.dart';

/// Enum para tipos de transacción
enum TipoTransaccion {
  @JsonValue('ingreso')
  ingreso,
  @JsonValue('egreso')
  egreso,
}

/// Modelo de Transacción para D-Nexus
@JsonSerializable()
class Transaccion {
  final int? id;
  @JsonKey(name: 'negocio_id')
  final int negocioId;
  @JsonKey(name: 'usuario_id')
  final int? usuarioId;
  final String concepto;
  final double monto;
  final TipoTransaccion tipo;
  final String? categoria;
  final DateTime fecha;
  final String? notas;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Transaccion({
    this.id,
    required this.negocioId,
    this.usuarioId,
    required this.concepto,
    required this.monto,
    required this.tipo,
    this.categoria,
    required this.fecha,
    this.notas,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor para crear desde JSON
  factory Transaccion.fromJson(Map<String, dynamic> json) => _$TransaccionFromJson(json);

  /// Convertir a JSON
  Map<String, dynamic> toJson() => _$TransaccionToJson(this);

  /// Crear copia con campos modificados
  Transaccion copyWith({
    int? id,
    int? negocioId,
    int? usuarioId,
    String? concepto,
    double? monto,
    TipoTransaccion? tipo,
    String? categoria,
    DateTime? fecha,
    String? notas,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaccion(
      id: id ?? this.id,
      negocioId: negocioId ?? this.negocioId,
      usuarioId: usuarioId ?? this.usuarioId,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      fecha: fecha ?? this.fecha,
      notas: notas ?? this.notas,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verificar si es ingreso
  bool get esIngreso => tipo == TipoTransaccion.ingreso;

  /// Verificar si es egreso
  bool get esEgreso => tipo == TipoTransaccion.egreso;

  /// Obtener monto con signo (positivo para ingresos, negativo para egresos)
  double get montoConSigno => esIngreso ? monto : -monto;

  /// Obtener texto del tipo
  String get tipoTexto => esIngreso ? 'Ingreso' : 'Egreso';

  /// Obtener color para UI según el tipo
  String get colorTipo => esIngreso ? '#4CAF50' : '#F44336';

  @override
  String toString() => 'Transaccion(id: $id, concepto: $concepto, monto: $monto, tipo: $tipo)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaccion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}