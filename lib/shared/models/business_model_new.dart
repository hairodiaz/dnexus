import 'contact_model.dart';
import 'address_model.dart';

/// Modelo para representar un negocio con sus contactos y direcciones
class BusinessModel {
  final int id;
  final String nombre;
  final String? nit;
  final DateTime? fechaRegistro;
  final bool estado;
  final int createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String sistema; // 'Repuesto', 'Prestamo', 'Inmuebles'

  List<ContactModel> contactos;
  List<AddressModel> direcciones;

  BusinessModel({
    required this.id,
    required this.nombre,
    this.nit,
    this.fechaRegistro,
    required this.estado,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.sistema = 'Repuesto',
    this.contactos = const [],
    this.direcciones = const [],
  });

  /// Obtener teléfono principal
  String? get telefonoPrincipal {
    try {
      return contactos
          .firstWhere((c) => c.tipo == 'telefono' && c.principal)
          .valor;
    } catch (_) {
      return null;
    }
  }

  /// Obtener email principal
  String? get emailPrincipal {
    try {
      return contactos.firstWhere((c) => c.tipo == 'email' && c.principal).valor;
    } catch (_) {
      return null;
    }
  }

  /// Obtener dirección principal
  AddressModel? get direccionPrincipal {
    try {
      return direcciones.firstWhere((d) => d.principal);
    } catch (_) {
      return null;
    }
  }

  /// Convertir desde JSON (Supabase)
  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      nit: json['nit'] as String?,
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.parse(json['fecha_registro'] as String)
          : null,
      estado: json['estado'] as bool? ?? true,
      createdBy: json['created_by'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      sistema: json['sistema'] as String? ?? 'Repuesto',
      contactos: (json['contactos'] as List<dynamic>?)
              ?.map((c) => ContactModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      direcciones: (json['direcciones'] as List<dynamic>?)
              ?.map((d) => AddressModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convertir desde Map (Supabase row)
  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel.fromJson(map);
  }

  /// Convertir a Map para Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'nit': nit,
      'fecha_registro': fechaRegistro?.toIso8601String().split('T').first,
      'estado': estado,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sistema': sistema,
    };
  }

  /// Copiar con cambios
  BusinessModel copyWith({
    int? id,
    String? nombre,
    String? nit,
    DateTime? fechaRegistro,
    bool? estado,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sistema,
    List<ContactModel>? contactos,
    List<AddressModel>? direcciones,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nit: nit ?? this.nit,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      estado: estado ?? this.estado,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sistema: sistema ?? this.sistema,
      contactos: contactos ?? this.contactos,
      direcciones: direcciones ?? this.direcciones,
    );
  }

  @override
  String toString() =>
      'BusinessModel(id: $id, nombre: $nombre, nit: $nit, estado: $estado, sistema: $sistema)';
}
