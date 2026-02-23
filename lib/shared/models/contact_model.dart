/// Modelo para representar un contacto de negocio (teléfono o email)
class ContactModel {
  final int id;
  final int negocioId;
  final String tipo; // 'telefono' | 'email'
  final String valor;
  final bool principal;

  ContactModel({
    required this.id,
    required this.negocioId,
    required this.tipo,
    required this.valor,
    required this.principal,
  });

  /// Convertir desde JSON
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as int,
      negocioId: json['negocio_id'] as int,
      tipo: json['tipo'] as String,
      valor: json['valor'] as String,
      principal: json['principal'] as bool? ?? false,
    );
  }

  /// Convertir a Map para insertar/actualizar
  Map<String, dynamic> toMap() {
    return {
      'negocio_id': negocioId,
      'tipo': tipo,
      'valor': valor,
      'principal': principal,
    };
  }

  /// Copiar con cambios
  ContactModel copyWith({
    int? id,
    int? negocioId,
    String? tipo,
    String? valor,
    bool? principal,
  }) {
    return ContactModel(
      id: id ?? this.id,
      negocioId: negocioId ?? this.negocioId,
      tipo: tipo ?? this.tipo,
      valor: valor ?? this.valor,
      principal: principal ?? this.principal,
    );
  }

  @override
  String toString() =>
      'ContactModel(id: $id, tipo: $tipo, valor: $valor, principal: $principal)';
}
