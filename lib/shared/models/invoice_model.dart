/// Estados de la factura en el workflow
enum InvoiceStatus {
  draft('draft', 'Borrador'),
  created('created', 'Creada'),
  inCashier('in_cashier', 'En Caja'),
  paid('paid', 'Pagada'),
  completed('completed', 'Completada'),
  cancelled('cancelled', 'Cancelada');

  const InvoiceStatus(this.value, this.displayName);
  
  final String value;
  final String displayName;

  static InvoiceStatus fromString(String status) {
    return InvoiceStatus.values.firstWhere(
      (s) => s.value == status,
      orElse: () => InvoiceStatus.draft,
    );
  }

  /// Color asociado al estado
  int get colorValue {
    switch (this) {
      case InvoiceStatus.draft:
        return 0xFF9E9E9E; // Grey
      case InvoiceStatus.created:
        return 0xFF2196F3; // Blue
      case InvoiceStatus.inCashier:
        return 0xFFFF9800; // Orange
      case InvoiceStatus.paid:
        return 0xFF4CAF50; // Green
      case InvoiceStatus.completed:
        return 0xFF8BC34A; // Light Green
      case InvoiceStatus.cancelled:
        return 0xFFF44336; // Red
    }
  }

  /// Icono asociado al estado
  int get iconCodePoint {
    switch (this) {
      case InvoiceStatus.draft:
        return 0xe1b7; // Icons.edit
      case InvoiceStatus.created:
        return 0xe19c; // Icons.receipt_long
      case InvoiceStatus.inCashier:
        return 0xe227; // Icons.point_of_sale
      case InvoiceStatus.paid:
        return 0xe156; // Icons.payment
      case InvoiceStatus.completed:
        return 0xe86c; // Icons.check_circle
      case InvoiceStatus.cancelled:
        return 0xe5c9; // Icons.cancel
    }
  }

  /// Verifica si se puede cambiar a otro estado
  bool canChangeTo(InvoiceStatus newStatus) {
    switch (this) {
      case InvoiceStatus.draft:
        return [InvoiceStatus.created, InvoiceStatus.cancelled].contains(newStatus);
      case InvoiceStatus.created:
        return [InvoiceStatus.inCashier, InvoiceStatus.cancelled].contains(newStatus);
      case InvoiceStatus.inCashier:
        return [InvoiceStatus.paid, InvoiceStatus.cancelled].contains(newStatus);
      case InvoiceStatus.paid:
        return [InvoiceStatus.completed].contains(newStatus);
      case InvoiceStatus.completed:
      case InvoiceStatus.cancelled:
        return false; // Estados finales
    }
  }
}

/// Métodos de pago disponibles
enum PaymentMethod {
  cash('cash', 'Efectivo'),
  card('card', 'Tarjeta'),
  bankTransfer('bank_transfer', 'Transferencia'),
  mixed('mixed', 'Mixto');

  const PaymentMethod(this.value, this.displayName);
  
  final String value;
  final String displayName;

  static PaymentMethod fromString(String method) {
    return PaymentMethod.values.firstWhere(
      (m) => m.value == method,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Item de factura
class InvoiceItemModel {
  final String productId;
  final String productName;
  final String productCode;
  final double unitPrice;
  final double quantity;
  final String unit;
  final double discount;
  final double tax;

  InvoiceItemModel({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.unitPrice,
    required this.quantity,
    this.unit = 'unidad',
    this.discount = 0.0,
    this.tax = 0.0,
  });

  /// Subtotal sin descuento ni impuestos
  double get subtotal => unitPrice * quantity;

  /// Total con descuento aplicado
  double get subtotalWithDiscount => subtotal - discountAmount;

  /// Monto del descuento
  double get discountAmount => subtotal * (discount / 100);

  /// Monto del impuesto
  double get taxAmount => subtotalWithDiscount * (tax / 100);

  /// Total final del item
  double get total => subtotalWithDiscount + taxAmount;

  InvoiceItemModel copyWith({
    String? productId,
    String? productName,
    String? productCode,
    double? unitPrice,
    double? quantity,
    String? unit,
    double? discount,
    double? tax,
  }) {
    return InvoiceItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productCode': productCode,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'unit': unit,
      'discount': discount,
      'tax': tax,
    };
  }

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      productId: json['productId'],
      productName: json['productName'],
      productCode: json['productCode'],
      unitPrice: json['unitPrice'].toDouble(),
      quantity: json['quantity'].toDouble(),
      unit: json['unit'] ?? 'unidad',
      discount: json['discount']?.toDouble() ?? 0.0,
      tax: json['tax']?.toDouble() ?? 0.0,
    );
  }
}

/// Modelo principal de factura
class InvoiceModel {
  final String id;
  final String number;
  final DateTime date;
  final InvoiceStatus status;
  final String businessId;
  final String? customerId;
  final String? customerName;
  final String? customerCedula;
  final String? customerPhone;
  final String? customerEmail;
  final List<InvoiceItemModel> items;
  final double subtotal;
  final double totalDiscount;
  final double totalTax;
  final double total;
  final PaymentMethod? paymentMethod;
  final double? paidAmount;
  final double? changeAmount;
  final String createdBy; // ID del empleado que creó
  final String? processedBy; // ID del empleado que procesó el pago
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? completedAt;
  final String? notes;

  InvoiceModel({
    required this.id,
    required this.number,
    required this.date,
    required this.status,
    required this.businessId,
    this.customerId,
    this.customerName,
    this.customerCedula,
    this.customerPhone,
    this.customerEmail,
    required this.items,
    required this.subtotal,
    required this.totalDiscount,
    required this.totalTax,
    required this.total,
    this.paymentMethod,
    this.paidAmount,
    this.changeAmount,
    required this.createdBy,
    this.processedBy,
    required this.createdAt,
    this.paidAt,
    this.completedAt,
    this.notes,
  });

  /// Calcula automáticamente los totales basado en los items
  factory InvoiceModel.createFromItems({
    required String id,
    required String number,
    required DateTime date,
    required String businessId,
    String? customerId,
    String? customerName,
    String? customerCedula,
    String? customerPhone,
    String? customerEmail,
    required List<InvoiceItemModel> items,
    required String createdBy,
    String? notes,
  }) {
    final subtotal = items.fold(0.0, (sum, item) => sum + item.subtotal);
    final totalDiscount = items.fold(0.0, (sum, item) => sum + item.discountAmount);
    final totalTax = items.fold(0.0, (sum, item) => sum + item.taxAmount);
    final total = items.fold(0.0, (sum, item) => sum + item.total);

    return InvoiceModel(
      id: id,
      number: number,
      date: date,
      status: InvoiceStatus.draft,
      businessId: businessId,
      customerId: customerId,
      customerName: customerName,
      customerCedula: customerCedula,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      items: items,
      subtotal: subtotal,
      totalDiscount: totalDiscount,
      totalTax: totalTax,
      total: total,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      notes: notes,
    );
  }

  /// Verifica si el usuario puede editar la factura
  bool canEdit(String userId) {
    return status == InvoiceStatus.draft && createdBy == userId;
  }

  /// Verifica si se puede enviar a caja
  bool get canSendToCashier {
    return status == InvoiceStatus.created && items.isNotEmpty;
  }

  /// Verifica si se puede procesar pago
  bool get canProcessPayment {
    return status == InvoiceStatus.inCashier;
  }

  /// Verifica si está completada
  bool get isCompleted {
    return status == InvoiceStatus.completed;
  }

  /// Verifica si está cancelada
  bool get isCancelled {
    return status == InvoiceStatus.cancelled;
  }

  /// Obtiene el color del estado
  int get statusColor => status.colorValue;

  /// Obtiene el ícono del estado
  int get statusIcon => status.iconCodePoint;

  /// Número de items en la factura
  int get itemCount => items.length;

  /// Cantidad total de productos
  double get totalQuantity => items.fold(0.0, (sum, item) => sum + item.quantity);

  /// Formateo del número de factura
  String get formattedNumber => 'F-${number.padLeft(6, '0')}';

  /// Formateo de fecha
  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formateo de totales en moneda
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}';
  String get formattedTotal => '\$${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}';
  String get formattedTotalDiscount => '\$${totalDiscount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}';
  String get formattedTotalTax => '\$${totalTax.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}';

  InvoiceModel copyWith({
    String? id,
    String? number,
    DateTime? date,
    InvoiceStatus? status,
    String? businessId,
    String? customerId,
    String? customerName,
    String? customerCedula,
    String? customerPhone,
    String? customerEmail,
    List<InvoiceItemModel>? items,
    double? subtotal,
    double? totalDiscount,
    double? totalTax,
    double? total,
    PaymentMethod? paymentMethod,
    double? paidAmount,
    double? changeAmount,
    String? createdBy,
    String? processedBy,
    DateTime? createdAt,
    DateTime? paidAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      number: number ?? this.number,
      date: date ?? this.date,
      status: status ?? this.status,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerCedula: customerCedula ?? this.customerCedula,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      totalTax: totalTax ?? this.totalTax,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      createdBy: createdBy ?? this.createdBy,
      processedBy: processedBy ?? this.processedBy,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'date': date.toIso8601String(),
      'status': status.value,
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'customerCedula': customerCedula,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'totalDiscount': totalDiscount,
      'totalTax': totalTax,
      'total': total,
      'paymentMethod': paymentMethod?.value,
      'paidAmount': paidAmount,
      'changeAmount': changeAmount,
      'createdBy': createdBy,
      'processedBy': processedBy,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      number: json['number'],
      date: DateTime.parse(json['date']),
      status: InvoiceStatus.fromString(json['status']),
      businessId: json['businessId'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerCedula: json['customerCedula'],
      customerPhone: json['customerPhone'],
      customerEmail: json['customerEmail'],
      items: (json['items'] as List)
          .map((item) => InvoiceItemModel.fromJson(item))
          .toList(),
      subtotal: json['subtotal'].toDouble(),
      totalDiscount: json['totalDiscount'].toDouble(),
      totalTax: json['totalTax'].toDouble(),
      total: json['total'].toDouble(),
      paymentMethod: json['paymentMethod'] != null 
          ? PaymentMethod.fromString(json['paymentMethod']) 
          : null,
      paidAmount: json['paidAmount']?.toDouble(),
      changeAmount: json['changeAmount']?.toDouble(),
      createdBy: json['createdBy'],
      processedBy: json['processedBy'],
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      notes: json['notes'],
    );
  }
}