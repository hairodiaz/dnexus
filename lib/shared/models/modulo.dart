import 'package:json_annotation/json_annotation.dart';

part 'modulo.g.dart';

/// Modelo de Módulo para D-Nexus
@JsonSerializable()
class Modulo {
  final int? id;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final String? icono;
  final bool activo;
  final String version;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const Modulo({
    this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    this.icono,
    this.activo = true,
    this.version = '1.0',
    this.createdAt,
  });

  /// Factory constructor para crear desde JSON
  factory Modulo.fromJson(Map<String, dynamic> json) => _$ModuloFromJson(json);

  /// Convertir a JSON
  Map<String, dynamic> toJson() => _$ModuloToJson(this);

  /// Crear copia con campos modificados
  Modulo copyWith({
    int? id,
    String? nombre,
    String? codigo,
    String? descripcion,
    String? icono,
    bool? activo,
    String? version,
    DateTime? createdAt,
  }) {
    return Modulo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      icono: icono ?? this.icono,
      activo: activo ?? this.activo,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Modulo(id: $id, codigo: $codigo, nombre: $nombre)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Modulo && other.codigo == codigo;
  }

  @override
  int get hashCode => codigo.hashCode;
}