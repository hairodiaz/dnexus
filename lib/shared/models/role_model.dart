import 'package:json_annotation/json_annotation.dart';

part 'role_model.g.dart';

/// Modelo que representa un Rol en el sistema
@JsonSerializable()
class RoleModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final String sistema;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Permisos asociados a este rol (cargados dinámicamente)
  final List<String> permissionNames;

  RoleModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.sistema,
    this.createdAt,
    this.updatedAt,
    this.permissionNames = const [],
  });

  /// Crea una copia del modelo con campos modificados
  RoleModel copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? sistema,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? permissionNames,
  }) {
    return RoleModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      sistema: sistema ?? this.sistema,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      permissionNames: permissionNames ?? this.permissionNames,
    );
  }

  factory RoleModel.fromJson(Map<String, dynamic> json) => _$RoleModelFromJson(json);
  Map<String, dynamic> toJson() => _$RoleModelToJson(this);

  @override
  String toString() => 'RoleModel(id: $id, nombre: $nombre, sistema: $sistema)';
}
