import 'package:json_annotation/json_annotation.dart';

part 'permission_model.g.dart';

/// Modelo que representa un Permiso en el sistema
@JsonSerializable()
class PermissionModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? modulo;
  final String sistema;
  final DateTime? createdAt;

  PermissionModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.modulo,
    required this.sistema,
    this.createdAt,
  });

  /// Crea una copia del modelo con campos modificados
  PermissionModel copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? modulo,
    String? sistema,
    DateTime? createdAt,
  }) {
    return PermissionModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      modulo: modulo ?? this.modulo,
      sistema: sistema ?? this.sistema,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory PermissionModel.fromJson(Map<String, dynamic> json) => _$PermissionModelFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionModelToJson(this);

  @override
  String toString() => 'PermissionModel(id: $id, nombre: $nombre, modulo: $modulo)';
}
