/// Modelo para representar una dirección de negocio
class AddressModel {
  final int id;
  final int negocioId;
  final String tipo; // 'principal' | 'sucursal' | 'otro'
  final String calle;
  final String? ciudad;
  final String? departamento;
  final String? codigoPostal;
  final bool principal;

  AddressModel({
    required this.id,
    required this.negocioId,
    required this.tipo,
    required this.calle,
    this.ciudad,
    this.departamento,
    this.codigoPostal,
    required this.principal,
  });

  /// Obtener dirección formateada
  String get direccionFormato {
    final partes = [
      calle,
      if (ciudad != null) ciudad,
      if (departamento != null) departamento,
    ];
    return partes.join(', ');
  }

  /// Convertir desde JSON
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as int,
      negocioId: json['negocio_id'] as int,
      tipo: json['tipo'] as String,
      calle: json['calle'] as String,
      ciudad: json['ciudad'] as String?,
      departamento: json['departamento'] as String?,
      codigoPostal: json['codigo_postal'] as String?,
      principal: json['principal'] as bool? ?? false,
    );
  }

  /// Convertir a Map para insertar/actualizar
  Map<String, dynamic> toMap() {
    return {
      'negocio_id': negocioId,
      'tipo': tipo,
      'calle': calle,
      'ciudad': ciudad,
      'departamento': departamento,
      'codigo_postal': codigoPostal,
      'principal': principal,
    };
  }

  /// Copiar con cambios
  AddressModel copyWith({
    int? id,
    int? negocioId,
    String? tipo,
    String? calle,
    String? ciudad,
    String? departamento,
    String? codigoPostal,
    bool? principal,
  }) {
    return AddressModel(
      id: id ?? this.id,
      negocioId: negocioId ?? this.negocioId,
      tipo: tipo ?? this.tipo,
      calle: calle ?? this.calle,
      ciudad: ciudad ?? this.ciudad,
      departamento: departamento ?? this.departamento,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      principal: principal ?? this.principal,
    );
  }

  @override
  String toString() =>
      'AddressModel(id: $id, tipo: $tipo, calle: $calle, principal: $principal)';
}
