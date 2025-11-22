/// Modelo de Cliente Unificado
/// Compartido entre todos los negocios (Repuestos, Electrodomésticos, Préstamos)
class ClientModel {
  final String id;
  final String cedula; // Clave única para identificación
  final String nombreCompleto;
  final String telefono;
  final String? email;
  final String? direccion;
  final DateTime fechaRegistro;
  final bool activo;
  
  // Historial por negocio
  final List<String> negociosAsociados; // ['repuestos', 'electrodomesticos', 'prestamos']
  final DateTime? ultimaCompra;
  final double? totalCompras;

  const ClientModel({
    required this.id,
    required this.cedula,
    required this.nombreCompleto,
    required this.telefono,
    this.email,
    this.direccion,
    required this.fechaRegistro,
    this.activo = true,
    this.negociosAsociados = const [],
    this.ultimaCompra,
    this.totalCompras,
  });

  /// Crea una instancia desde JSON
  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] ?? '',
      cedula: json['cedula'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'],
      direccion: json['direccion'],
      fechaRegistro: json['fecha_registro'] != null 
        ? DateTime.parse(json['fecha_registro'])
        : DateTime.now(),
      activo: json['activo'] ?? true,
      negociosAsociados: List<String>.from(json['negocios_asociados'] ?? []),
      ultimaCompra: json['ultima_compra'] != null 
        ? DateTime.parse(json['ultima_compra'])
        : null,
      totalCompras: json['total_compras']?.toDouble(),
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cedula': cedula,
      'nombre_completo': nombreCompleto,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'activo': activo,
      'negocios_asociados': negociosAsociados,
      'ultima_compra': ultimaCompra?.toIso8601String(),
      'total_compras': totalCompras,
    };
  }

  /// Crea una copia con campos modificados
  ClientModel copyWith({
    String? id,
    String? cedula,
    String? nombreCompleto,
    String? telefono,
    String? email,
    String? direccion,
    DateTime? fechaRegistro,
    bool? activo,
    List<String>? negociosAsociados,
    DateTime? ultimaCompra,
    double? totalCompras,
  }) {
    return ClientModel(
      id: id ?? this.id,
      cedula: cedula ?? this.cedula,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      activo: activo ?? this.activo,
      negociosAsociados: negociosAsociados ?? this.negociosAsociados,
      ultimaCompra: ultimaCompra ?? this.ultimaCompra,
      totalCompras: totalCompras ?? this.totalCompras,
    );
  }

  /// Verifica si el cliente está asociado a un negocio específico
  bool estaEnNegocio(String negocio) {
    return negociosAsociados.contains(negocio);
  }

  /// Añade un negocio al historial del cliente
  ClientModel agregarNegocio(String negocio) {
    if (estaEnNegocio(negocio)) return this;
    
    return copyWith(
      negociosAsociados: [...negociosAsociados, negocio],
    );
  }

  /// Obtiene el nombre formateado para mostrar
  String get nombreFormateado {
    return nombreCompleto.trim();
  }

  /// Obtiene información resumida del cliente
  String get resumen {
    final negocios = negociosAsociados.isEmpty 
      ? 'Nuevo cliente' 
      : 'Cliente en: ${negociosAsociados.join(', ')}';
    return '$nombreCompleto - $cedula ($negocios)';
  }

  @override
  String toString() => 'ClientModel(cedula: $cedula, nombre: $nombreCompleto)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientModel && other.cedula == cedula;
  }

  @override
  int get hashCode => cedula.hashCode;
}