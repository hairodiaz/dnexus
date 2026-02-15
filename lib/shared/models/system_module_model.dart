/// Modelo para representar módulos del sistema
class SystemModule {
  final String id;
  final String nombre;
  final String descripcion;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SystemModule({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory para crear desde Map (Supabase)
  factory SystemModule.fromJson(Map<String, dynamic> json) {
    return SystemModule(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      activo: json['activo'] ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convertir a Map para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// CopyWith para actualizar propiedades
  SystemModule copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SystemModule(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Modelo para Audit Logs
class AuditLog {
  final String id;
  final String usuarioId;
  final String nombreUsuario;
  final String tipo; // 'crear_usuario', 'crear_negocio', 'crear_empleado', etc.
  final String descripcion;
  final String? detalles; // JSON con detalles de la operación
  final String estado; // 'exitoso', 'error'
  final String? motivo; // Razón si falló
  final DateTime fechaHora;

  const AuditLog({
    required this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.tipo,
    required this.descripcion,
    this.detalles,
    required this.estado,
    this.motivo,
    required this.fechaHora,
  });

  /// Factory para crear desde Map (Supabase)
  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id']?.toString() ?? '',
      usuarioId: json['usuario_id']?.toString() ?? '',
      nombreUsuario: json['nombre_usuario'] ?? '',
      tipo: json['tipo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      detalles: json['detalles'],
      estado: json['estado'] ?? 'exitoso',
      motivo: json['motivo'],
      fechaHora: DateTime.tryParse(json['fecha_hora'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convertir a Map para Supabase
  Map<String, dynamic> toJson() {
    return {
      'usuario_id': usuarioId,
      'nombre_usuario': nombreUsuario,
      'tipo': tipo,
      'descripcion': descripcion,
      'detalles': detalles,
      'estado': estado,
      'motivo': motivo,
      'fecha_hora': fechaHora.toIso8601String(),
    };
  }
}
