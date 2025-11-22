/// Modelo para el Libro Mayor (General Ledger)
class GeneralLedgerModel {
  final int id;
  final int businessId;
  final int chartOfAccountsId;
  final int journalEntryId;
  final int journalEntryDetailId;
  final DateTime fecha;
  final String numero;
  final String concepto;
  final double debe;
  final double haber;
  final double saldo;
  final DateTime createdAt;

  const GeneralLedgerModel({
    required this.id,
    required this.businessId,
    required this.chartOfAccountsId,
    required this.journalEntryId,
    required this.journalEntryDetailId,
    required this.fecha,
    required this.numero,
    required this.concepto,
    required this.debe,
    required this.haber,
    required this.saldo,
    required this.createdAt,
  });

  /// Crea una instancia desde un Map (JSON/Database)
  factory GeneralLedgerModel.fromMap(Map<String, dynamic> map) {
    return GeneralLedgerModel(
      id: map['id'] as int,
      businessId: map['business_id'] as int,
      chartOfAccountsId: map['chart_of_accounts_id'] as int,
      journalEntryId: map['journal_entry_id'] as int,
      journalEntryDetailId: map['journal_entry_detail_id'] as int,
      fecha: DateTime.parse(map['fecha'] as String),
      numero: map['numero'] as String,
      concepto: map['concepto'] as String,
      debe: (map['debe'] as num).toDouble(),
      haber: (map['haber'] as num).toDouble(),
      saldo: (map['saldo'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convierte la instancia a Map para JSON/Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'chart_of_accounts_id': chartOfAccountsId,
      'journal_entry_id': journalEntryId,
      'journal_entry_detail_id': journalEntryDetailId,
      'fecha': fecha.toIso8601String().split('T').first,
      'numero': numero,
      'concepto': concepto,
      'debe': debe,
      'haber': haber,
      'saldo': saldo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Indica si es un movimiento al debe
  bool get isDebit => debe > 0;

  /// Indica si es un movimiento al haber
  bool get isCredit => haber > 0;

  /// Obtiene el monto del movimiento
  double get amount => debe > 0 ? debe : haber;

  /// Copia la instancia con nuevos valores
  GeneralLedgerModel copyWith({
    int? id,
    int? businessId,
    int? chartOfAccountsId,
    int? journalEntryId,
    int? journalEntryDetailId,
    DateTime? fecha,
    String? numero,
    String? concepto,
    double? debe,
    double? haber,
    double? saldo,
    DateTime? createdAt,
  }) {
    return GeneralLedgerModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      chartOfAccountsId: chartOfAccountsId ?? this.chartOfAccountsId,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      journalEntryDetailId: journalEntryDetailId ?? this.journalEntryDetailId,
      fecha: fecha ?? this.fecha,
      numero: numero ?? this.numero,
      concepto: concepto ?? this.concepto,
      debe: debe ?? this.debe,
      haber: haber ?? this.haber,
      saldo: saldo ?? this.saldo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'GeneralLedgerModel(id: $id, fecha: $fecha, numero: $numero, debe: $debe, haber: $haber, saldo: $saldo)';
  }
}

/// Modelo para el Balance de Comprobación (Trial Balance)
class TrialBalanceModel {
  final int chartOfAccountsId;
  final String codigo;
  final String nombre;
  final String tipo;
  final double saldoAnterior;
  final double movimientosDebe;
  final double movimientosHaber;
  final double saldoFinal;

  const TrialBalanceModel({
    required this.chartOfAccountsId,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    required this.saldoAnterior,
    required this.movimientosDebe,
    required this.movimientosHaber,
    required this.saldoFinal,
  });

  /// Crea una instancia desde un Map (JSON/Database)
  factory TrialBalanceModel.fromMap(Map<String, dynamic> map) {
    return TrialBalanceModel(
      chartOfAccountsId: map['chart_of_accounts_id'] as int,
      codigo: map['codigo'] as String,
      nombre: map['nombre'] as String,
      tipo: map['tipo'] as String,
      saldoAnterior: (map['saldo_anterior'] as num?)?.toDouble() ?? 0.0,
      movimientosDebe: (map['movimientos_debe'] as num?)?.toDouble() ?? 0.0,
      movimientosHaber: (map['movimientos_haber'] as num?)?.toDouble() ?? 0.0,
      saldoFinal: (map['saldo_final'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convierte la instancia a Map para JSON/Database
  Map<String, dynamic> toMap() {
    return {
      'chart_of_accounts_id': chartOfAccountsId,
      'codigo': codigo,
      'nombre': nombre,
      'tipo': tipo,
      'saldo_anterior': saldoAnterior,
      'movimientos_debe': movimientosDebe,
      'movimientos_haber': movimientosHaber,
      'saldo_final': saldoFinal,
    };
  }

  /// Devuelve el nombre completo de la cuenta (código + nombre)
  String get fullName => '$codigo - $nombre';

  /// Indica si tiene movimiento en el período
  bool get hasMovement => movimientosDebe > 0 || movimientosHaber > 0;

  /// Indica si tiene saldo
  bool get hasBalance => saldoFinal != 0;

  /// Obtiene la naturaleza del saldo (DEUDOR/ACREEDOR)
  String get balanceNature {
    if (saldoFinal == 0) return 'SIN SALDO';
    
    // Para activos y gastos, saldo positivo es deudor
    if (['ACTIVO', 'GASTO'].contains(tipo)) {
      return saldoFinal > 0 ? 'DEUDOR' : 'ACREEDOR';
    }
    
    // Para pasivos, patrimonio e ingresos, saldo positivo es acreedor
    return saldoFinal > 0 ? 'ACREEDOR' : 'DEUDOR';
  }

  /// Copia la instancia con nuevos valores
  TrialBalanceModel copyWith({
    int? chartOfAccountsId,
    String? codigo,
    String? nombre,
    String? tipo,
    double? saldoAnterior,
    double? movimientosDebe,
    double? movimientosHaber,
    double? saldoFinal,
  }) {
    return TrialBalanceModel(
      chartOfAccountsId: chartOfAccountsId ?? this.chartOfAccountsId,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      saldoAnterior: saldoAnterior ?? this.saldoAnterior,
      movimientosDebe: movimientosDebe ?? this.movimientosDebe,
      movimientosHaber: movimientosHaber ?? this.movimientosHaber,
      saldoFinal: saldoFinal ?? this.saldoFinal,
    );
  }

  @override
  String toString() {
    return 'TrialBalanceModel(codigo: $codigo, nombre: $nombre, saldoFinal: $saldoFinal)';
  }
}