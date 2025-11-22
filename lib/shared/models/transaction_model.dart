/// Modelo para representar una transacción en D-Nexus
class TransactionModel {
  final int id;
  final String tipo; // 'ingreso' o 'egreso'
  final double monto;
  final String concepto;
  final String categoria;
  final String metodoPago; // 'efectivo', 'banco', 'tarjeta'
  final String? cliente; // Para préstamos especialmente
  final DateTime fecha;
  final int negocioId;
  final String? observaciones;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.concepto,
    required this.categoria,
    required this.metodoPago,
    this.cliente,
    required this.fecha,
    required this.negocioId,
    this.observaciones,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory para crear desde Map (resultado de DB)
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int,
      tipo: map['tipo'] as String,
      monto: (map['monto'] as num).toDouble(),
      concepto: map['concepto'] as String,
      categoria: map['categoria'] as String,
      metodoPago: map['metodo_pago'] as String,
      cliente: map['cliente'] as String?,
      fecha: DateTime.parse(map['fecha'] as String),
      negocioId: map['negocio_id'] as int,
      observaciones: map['observaciones'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convertir a Map para base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'monto': monto,
      'concepto': concepto,
      'categoria': categoria,
      'metodo_pago': metodoPago,
      'cliente': cliente,
      'fecha': fecha.toIso8601String(),
      'negocio_id': negocioId,
      'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crear copia con cambios
  TransactionModel copyWith({
    int? id,
    String? tipo,
    double? monto,
    String? concepto,
    String? categoria,
    String? metodoPago,
    String? cliente,
    DateTime? fecha,
    int? negocioId,
    String? observaciones,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      concepto: concepto ?? this.concepto,
      categoria: categoria ?? this.categoria,
      metodoPago: metodoPago ?? this.metodoPago,
      cliente: cliente ?? this.cliente,
      fecha: fecha ?? this.fecha,
      negocioId: negocioId ?? this.negocioId,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransactionModel(id: $id, tipo: $tipo, monto: $monto, concepto: $concepto)';
  }

  /// Validar datos de la transacción
  bool get isValid {
    return monto > 0 && 
           concepto.trim().isNotEmpty &&
           categoria.trim().isNotEmpty &&
           ['ingreso', 'egreso'].contains(tipo) &&
           ['efectivo', 'banco', 'tarjeta'].contains(metodoPago);
  }

  /// Icono según el tipo de transacción
  String get iconEmoji {
    return tipo == 'ingreso' ? '💰' : '💸';
  }

  /// Color según el tipo
  String get colorType {
    return tipo == 'ingreso' ? 'green' : 'red';
  }

  /// Monto formateado con signo
  String get montoFormateado {
    final sign = tipo == 'ingreso' ? '+' : '-';
    return '$sign\$${monto.toStringAsFixed(2)}';
  }

  /// Categorías por tipo de negocio
  static List<String> getCategoriasPorTipo(String tipoNegocio, String tipoTransaccion) {
    switch (tipoNegocio) {
      case 'prestamos':
        return tipoTransaccion == 'ingreso' 
          ? ['Pago de Capital', 'Pago de Intereses', 'Multas por Mora', 'Otros Ingresos']
          : ['Préstamo Otorgado', 'Gastos Operativos', 'Comisiones', 'Otros Gastos'];
      
      case 'repuestos':
        return tipoTransaccion == 'ingreso'
          ? ['Venta de Repuestos', 'Servicios', 'Instalaciones', 'Otros Ingresos']
          : ['Compra de Inventario', 'Gastos Operativos', 'Herramientas', 'Otros Gastos'];
      
      case 'electrodomesticos':
        return tipoTransaccion == 'ingreso'
          ? ['Venta de Productos', 'Servicios Técnicos', 'Garantías', 'Otros Ingresos']
          : ['Compra de Inventario', 'Gastos Operativos', 'Reparaciones', 'Otros Gastos'];
      
      default:
        return tipoTransaccion == 'ingreso'
          ? ['Ventas', 'Servicios', 'Otros Ingresos']
          : ['Compras', 'Gastos Operativos', 'Otros Gastos'];
    }
  }

  /// Métodos de pago disponibles
  static List<String> get metodosPago {
    return ['efectivo', 'banco', 'tarjeta'];
  }

  /// Descripción del método de pago
  String get metodoPagoDescripcion {
    switch (metodoPago) {
      case 'efectivo':
        return '💵 Efectivo';
      case 'banco':
        return '🏦 Banco';
      case 'tarjeta':
        return '💳 Tarjeta';
      default:
        return metodoPago;
    }
  }
}