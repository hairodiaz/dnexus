import 'package:json_annotation/json_annotation.dart';

part 'role_model.g.dart';

/// Modelo que representa un Rol en el sistema
@JsonSerializable()
class RoleModel {
  final int id;
  final int negocioId;
  final String nombre;
  final String? descripcion;
  final bool estado;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Módulos asociados a este rol (cargados dinámicamente)
  final List<int> moduloIds;

  RoleModel({
    required this.id,
    required this.negocioId,
    required this.nombre,
    this.descripcion,
    required this.estado,
    required this.createdAt,
    this.updatedAt,
    this.moduloIds = const [],
  });

  /// Crea una copia del modelo con campos modificados
  RoleModel copyWith({
    int? id,
    int? negocioId,
    String? nombre,
    String? descripcion,
    bool? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<int>? moduloIds,
  }) {
    return RoleModel(
      id: id ?? this.id,
      negocioId: negocioId ?? this.negocioId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moduloIds: moduloIds ?? this.moduloIds,
    );
  }

  factory RoleModel.fromJson(Map<String, dynamic> json) => _$RoleModelFromJson(json);
  Map<String, dynamic> toJson() => _$RoleModelToJson(this);

  @override
  String toString() => 'RoleModel(id: $id, nombre: $nombre, negocioId: $negocioId)';
}
