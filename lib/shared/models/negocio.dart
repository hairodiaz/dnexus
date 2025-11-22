import 'package:json_annotation/json_annotation.dart';

part 'negocio.g.dart';

/// Enum para tipos de negocio
enum TipoNegocio {
  @JsonValue('repuestos')
  repuestos,
  @JsonValue('prestamos')
  prestamos,
  @JsonValue('electrodomesticos')
  electrodomesticos,
}

/// Modelo de Negocio para D-Nexus
@JsonSerializable()
class Negocio {
  final int? id;
  final String nombre;
  final TipoNegocio tipo;
  final String? descripcion;
  @JsonKey(name: 'propietario_id')
  final int? propietarioId;
  final bool activo;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Negocio({
    this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    this.propietarioId,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor para crear desde JSON
  factory Negocio.fromJson(Map<String, dynamic> json) => _$NegocioFromJson(json);

  /// Convertir a JSON
  Map<String, dynamic> toJson() => _$NegocioToJson(this);

  /// Crear copia con campos modificados
  Negocio copyWith({
    int? id,
    String? nombre,
    TipoNegocio? tipo,
    String? descripcion,
    int? propietarioId,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Negocio(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      propietarioId: propietarioId ?? this.propietarioId,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Obtener nombre del tipo de negocio
  String get tipoNombre {
    switch (tipo) {
      case TipoNegocio.repuestos:
        return 'Repuestos';
      case TipoNegocio.prestamos:
        return 'Préstamos';
      case TipoNegocio.electrodomesticos:
        return 'Electrodomésticos';
    }
  }

  /// Obtener icono del tipo de negocio
  String get tipoIcono {
    switch (tipo) {
      case TipoNegocio.repuestos:
        return 'build';
      case TipoNegocio.prestamos:
        return 'account_balance';
      case TipoNegocio.electrodomesticos:
        return 'home';
    }
  }

  @override
  String toString() => 'Negocio(id: $id, nombre: $nombre, tipo: $tipo)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Negocio && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}