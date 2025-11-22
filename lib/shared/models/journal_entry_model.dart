/// Modelo para los Asientos Contables
class JournalEntryModel {
  final int id;
  final int businessId;
  final String numero;
  final String concepto;
  final DateTime fecha;
  final String estado; // BORRADOR, CONTABILIZADO, ANULADO
  final String? referencia;
  final double totalDebe;
  final double totalHaber;
  final int creadoPorUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<JournalEntryDetailModel>? detalles;

  const JournalEntryModel({
    required this.id,
    required this.businessId,
    required this.numero,
    required this.concepto,
    required this.fecha,
    required this.estado,
    this.referencia,
    required this.totalDebe,
    required this.totalHaber,
    required this.creadoPorUserId,
    required this.createdAt,
    required this.updatedAt,
    this.detalles,
  });

  /// Crea una instancia desde un Map (JSON/Database)
  factory JournalEntryModel.fromMap(Map<String, dynamic> map) {
    return JournalEntryModel(
      id: map['id'] as int,
      businessId: map['business_id'] as int,
      numero: map['numero'] as String,
      concepto: map['concepto'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      estado: map['estado'] as String,
      referencia: map['referencia'] as String?,
      totalDebe: (map['total_debe'] as num).toDouble(),
      totalHaber: (map['total_haber'] as num).toDouble(),
      creadoPorUserId: map['creado_por_user_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convierte la instancia a Map para JSON/Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'numero': numero,
      'concepto': concepto,
      'fecha': fecha.toIso8601String().split('T').first,
      'estado': estado,
      'referencia': referencia,
      'total_debe': totalDebe,
      'total_haber': totalHaber,
      'creado_por_user_id': creadoPorUserId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Indica si el asiento está balanceado (debe = haber)
  bool get isBalanced => totalDebe == totalHaber;

  /// Indica si el asiento puede ser modificado
  bool get canBeModified => estado == 'BORRADOR';

  /// Indica si el asiento está contabilizado
  bool get isPosted => estado == 'CONTABILIZADO';

  /// Copia la instancia con nuevos valores
  JournalEntryModel copyWith({
    int? id,
    int? businessId,
    String? numero,
    String? concepto,
    DateTime? fecha,
    String? estado,
    String? referencia,
    double? totalDebe,
    double? totalHaber,
    int? creadoPorUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<JournalEntryDetailModel>? detalles,
  }) {
    return JournalEntryModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      numero: numero ?? this.numero,
      concepto: concepto ?? this.concepto,
      fecha: fecha ?? this.fecha,
      estado: estado ?? this.estado,
      referencia: referencia ?? this.referencia,
      totalDebe: totalDebe ?? this.totalDebe,
      totalHaber: totalHaber ?? this.totalHaber,
      creadoPorUserId: creadoPorUserId ?? this.creadoPorUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      detalles: detalles ?? this.detalles,
    );
  }

  @override
  String toString() {
    return 'JournalEntryModel(id: $id, numero: $numero, concepto: $concepto, estado: $estado)';
  }
}

/// Modelo para los Detalles de Asientos Contables
class JournalEntryDetailModel {
  final int id;
  final int journalEntryId;
  final int chartOfAccountsId;
  final String? descripcion;
  final double debe;
  final double haber;
  final String? referencia;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntryDetailModel({
    required this.id,
    required this.journalEntryId,
    required this.chartOfAccountsId,
    this.descripcion,
    required this.debe,
    required this.haber,
    this.referencia,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crea una instancia desde un Map (JSON/Database)
  factory JournalEntryDetailModel.fromMap(Map<String, dynamic> map) {
    return JournalEntryDetailModel(
      id: map['id'] as int,
      journalEntryId: map['journal_entry_id'] as int,
      chartOfAccountsId: map['chart_of_accounts_id'] as int,
      descripcion: map['descripcion'] as String?,
      debe: (map['debe'] as num).toDouble(),
      haber: (map['haber'] as num).toDouble(),
      referencia: map['referencia'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convierte la instancia a Map para JSON/Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'journal_entry_id': journalEntryId,
      'chart_of_accounts_id': chartOfAccountsId,
      'descripcion': descripcion,
      'debe': debe,
      'haber': haber,
      'referencia': referencia,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Indica si es un movimiento al debe
  bool get isDebit => debe > 0;

  /// Indica si es un movimiento al haber
  bool get isCredit => haber > 0;

  /// Obtiene el monto del movimiento
  double get amount => debe > 0 ? debe : haber;

  /// Copia la instancia con nuevos valores
  JournalEntryDetailModel copyWith({
    int? id,
    int? journalEntryId,
    int? chartOfAccountsId,
    String? descripcion,
    double? debe,
    double? haber,
    String? referencia,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntryDetailModel(
      id: id ?? this.id,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      chartOfAccountsId: chartOfAccountsId ?? this.chartOfAccountsId,
      descripcion: descripcion ?? this.descripcion,
      debe: debe ?? this.debe,
      haber: haber ?? this.haber,
      referencia: referencia ?? this.referencia,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'JournalEntryDetailModel(id: $id, chartOfAccountsId: $chartOfAccountsId, debe: $debe, haber: $haber)';
  }
}