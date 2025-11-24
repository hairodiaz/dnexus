import 'package:equatable/equatable.dart';

/// Estado de la caja registradora
enum CashRegisterStatus {
  opened('opened', 'Abierta'),
  closed('closed', 'Cerrada');

  const CashRegisterStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static CashRegisterStatus fromValue(String value) {
    return values.firstWhere((status) => status.value == value);
  }
}

/// Modelo para el manejo de la caja registradora
class CashRegisterModel extends Equatable {
  final int id;
  final int businessId;
  final int userId;
  final String userName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double initialAmount;
  final double? finalAmount;
  final double? expectedAmount;
  final double? difference;
  final CashRegisterStatus status;
  final String? notes;
  final double totalSales;
  final int transactionCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CashRegisterModel({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.userName,
    required this.openedAt,
    this.closedAt,
    required this.initialAmount,
    this.finalAmount,
    this.expectedAmount,
    this.difference,
    required this.status,
    this.notes,
    this.totalSales = 0.0,
    this.transactionCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        userId,
        userName,
        openedAt,
        closedAt,
        initialAmount,
        finalAmount,
        expectedAmount,
        difference,
        status,
        notes,
        totalSales,
        transactionCount,
        createdAt,
        updatedAt,
      ];

  /// Verifica si la caja está abierta
  bool get isOpen => status == CashRegisterStatus.opened;

  /// Verifica si la caja está cerrada
  bool get isClosed => status == CashRegisterStatus.closed;

  /// Calcula el monto esperado basado en el inicial + ventas
  double get calculatedExpectedAmount => initialAmount + totalSales;

  /// Verifica si hay diferencia en el cierre
  bool get hasDifference => difference != null && difference != 0.0;

  /// Duración de la jornada (solo si está cerrada)
  Duration? get workDuration {
    if (closedAt == null) return null;
    return closedAt!.difference(openedAt);
  }

  /// Crea una copia del modelo con nuevos valores
  CashRegisterModel copyWith({
    int? id,
    int? businessId,
    int? userId,
    String? userName,
    DateTime? openedAt,
    DateTime? closedAt,
    double? initialAmount,
    double? finalAmount,
    double? expectedAmount,
    double? difference,
    CashRegisterStatus? status,
    String? notes,
    double? totalSales,
    int? transactionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CashRegisterModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      initialAmount: initialAmount ?? this.initialAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      difference: difference ?? this.difference,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      totalSales: totalSales ?? this.totalSales,
      transactionCount: transactionCount ?? this.transactionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'user_id': userId,
      'user_name': userName,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'initial_amount': initialAmount,
      'final_amount': finalAmount,
      'expected_amount': expectedAmount,
      'difference': difference,
      'status': status.value,
      'notes': notes,
      'total_sales': totalSales,
      'transaction_count': transactionCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crea una instancia desde JSON
  factory CashRegisterModel.fromJson(Map<String, dynamic> json) {
    return CashRegisterModel(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      openedAt: DateTime.parse(json['opened_at'] as String),
      closedAt: json['closed_at'] != null 
          ? DateTime.parse(json['closed_at'] as String) 
          : null,
      initialAmount: (json['initial_amount'] as num).toDouble(),
      finalAmount: json['final_amount'] != null 
          ? (json['final_amount'] as num).toDouble() 
          : null,
      expectedAmount: json['expected_amount'] != null 
          ? (json['expected_amount'] as num).toDouble() 
          : null,
      difference: json['difference'] != null 
          ? (json['difference'] as num).toDouble() 
          : null,
      status: CashRegisterStatus.fromValue(json['status'] as String),
      notes: json['notes'] as String?,
      totalSales: (json['total_sales'] as num? ?? 0).toDouble(),
      transactionCount: json['transaction_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Crea una nueva caja registradora
  factory CashRegisterModel.create({
    required int businessId,
    required int userId,
    required String userName,
    required double initialAmount,
    String? notes,
  }) {
    final now = DateTime.now();
    return CashRegisterModel(
      id: DateTime.now().millisecondsSinceEpoch,
      businessId: businessId,
      userId: userId,
      userName: userName,
      openedAt: now,
      initialAmount: initialAmount,
      status: CashRegisterStatus.opened,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  String toString() {
    return 'CashRegisterModel(id: $id, user: $userName, status: ${status.displayName}, '
           'initial: \$${initialAmount.toStringAsFixed(2)}, '
           'total_sales: \$${totalSales.toStringAsFixed(2)})';
  }
}