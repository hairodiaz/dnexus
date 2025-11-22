/// Modelo para el Plan de Cuentas
class ChartOfAccountsModel {
  final int id;
  final int businessId;
  final String codigo;
  final String nombre;
  final String tipo; // ACTIVO, PASIVO, PATRIMONIO, INGRESO, GASTO
  final String subtipo; // CIRCULANTE, FIJO, CORRIENTE, NO_CORRIENTE, etc.
  final int? cuentaPadreId;
  final int nivel; // 1-5 (niveles de profundidad)
  final bool aceptaMovimiento; // true si acepta asientos directos
  final bool activa;
  final String? descripcion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChartOfAccountsModel({
    required this.id,
    required this.businessId,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    required this.subtipo,
    this.cuentaPadreId,
    required this.nivel,
    required this.aceptaMovimiento,
    this.activa = true,
    this.descripcion,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crea una instancia desde un Map (JSON/Database)
  factory ChartOfAccountsModel.fromMap(Map<String, dynamic> map) {
    return ChartOfAccountsModel(
      id: map['id'] as int,
      businessId: map['business_id'] as int,
      codigo: map['codigo'] as String,
      nombre: map['nombre'] as String,
      tipo: map['tipo'] as String,
      subtipo: map['subtipo'] as String,
      cuentaPadreId: map['cuenta_padre_id'] as int?,
      nivel: map['nivel'] as int,
      aceptaMovimiento: map['acepta_movimiento'] as bool,
      activa: map['activa'] as bool? ?? true,
      descripcion: map['descripcion'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convierte la instancia a Map para JSON/Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'codigo': codigo,
      'nombre': nombre,
      'tipo': tipo,
      'subtipo': subtipo,
      'cuenta_padre_id': cuentaPadreId,
      'nivel': nivel,
      'acepta_movimiento': aceptaMovimiento,
      'activa': activa,
      'descripcion': descripcion,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Devuelve el nombre completo de la cuenta (código + nombre)
  String get fullName => '$codigo - $nombre';

  /// Indica si es una cuenta de balance (ACTIVO, PASIVO, PATRIMONIO)
  bool get isBalanceAccount => ['ACTIVO', 'PASIVO', 'PATRIMONIO'].contains(tipo);

  /// Indica si es una cuenta de resultado (INGRESO, GASTO)
  bool get isProfitLossAccount => ['INGRESO', 'GASTO'].contains(tipo);

  /// Copia la instancia con nuevos valores
  ChartOfAccountsModel copyWith({
    int? id,
    int? businessId,
    String? codigo,
    String? nombre,
    String? tipo,
    String? subtipo,
    int? cuentaPadreId,
    int? nivel,
    bool? aceptaMovimiento,
    bool? activa,
    String? descripcion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChartOfAccountsModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      subtipo: subtipo ?? this.subtipo,
      cuentaPadreId: cuentaPadreId ?? this.cuentaPadreId,
      nivel: nivel ?? this.nivel,
      aceptaMovimiento: aceptaMovimiento ?? this.aceptaMovimiento,
      activa: activa ?? this.activa,
      descripcion: descripcion ?? this.descripcion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ChartOfAccountsModel(id: $id, codigo: $codigo, nombre: $nombre, tipo: $tipo)';
  }
}