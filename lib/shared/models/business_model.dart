/// Modelo para representar un negocio en D-Nexus
class BusinessModel {
  final int id;
  final String nombre;
  final String tipo;
  final String? descripcion;
  final int? propietarioId;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    this.propietarioId,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory para crear desde Map (resultado de DB)
  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      tipo: map['tipo'] as String,
      descripcion: map['descripcion'] as String?,
      propietarioId: map['propietario_id'] as int?,
      activo: map['activo'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convertir a Map para base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'propietario_id': propietarioId,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crear copia con cambios
  BusinessModel copyWith({
    int? id,
    String? nombre,
    String? tipo,
    String? descripcion,
    int? propietarioId,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessModel(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BusinessModel(id: $id, nombre: $nombre, tipo: $tipo, activo: $activo)';
  }

  /// Validar datos del negocio
  bool get isValid {
    return nombre.trim().isNotEmpty && 
           tipo.trim().isNotEmpty &&
           ['repuestos', 'prestamos', 'electrodomesticos'].contains(tipo);
  }

  /// Nombre formateado para display
  String get displayName {
    switch (tipo) {
      case 'repuestos':
        return '🔧 $nombre';
      case 'prestamos':
        return '💰 $nombre';
      case 'electrodomesticos':
        return '🏠 $nombre';
      default:
        return '🏢 $nombre';
    }
  }
}