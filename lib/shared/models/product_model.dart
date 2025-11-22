/// Modelo de producto para el sistema de inventario
class ProductModel {
  final int id;
  final String code;
  final String name;
  final String description;
  final String category;
  final double purchasePrice;
  final double salePrice;
  final int currentStock;
  final int minStock;
  final int maxStock;
  final String unit; // unidad, piezas, litros, etc.
  final String? imageUrl;
  final bool isActive;
  final int businessId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? supplier;
  final String? location; // ubicación en almacén
  final double? weight;
  final String? dimensions;
  
  // Campos para unidades múltiples
  final int? conversionFactor; // cuántas unidades base hay en un empaque
  final String? packageName; // nombre del empaque (caja, sixpack, etc.)
  final double? packagePrice; // precio del empaque completo
  final bool canSellByUnit; // ¿se puede vender por unidad?
  final bool canSellByPackage; // ¿se puede vender por empaque?

  const ProductModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.purchasePrice,
    required this.salePrice,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.unit,
    this.imageUrl,
    required this.isActive,
    required this.businessId,
    required this.createdAt,
    required this.updatedAt,
    this.supplier,
    this.location,
    this.weight,
    this.dimensions,
    // Campos para unidades múltiples
    this.conversionFactor,
    this.packageName,
    this.packagePrice,
    this.canSellByUnit = true,
    this.canSellByPackage = false,
  });

  /// Constructor para crear producto desde Map
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      salePrice: (map['sale_price'] as num).toDouble(),
      currentStock: map['current_stock'] as int,
      minStock: map['min_stock'] as int,
      maxStock: map['max_stock'] as int,
      unit: map['unit'] as String,
      imageUrl: map['image_url'] as String?,
      isActive: map['is_active'] as bool,
      businessId: map['business_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      supplier: map['supplier'] as String?,
      location: map['location'] as String?,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      dimensions: map['dimensions'] as String?,
      // Campos para unidades múltiples
      conversionFactor: map['conversion_factor'] as int?,
      packageName: map['package_name'] as String?,
      packagePrice: map['package_price'] != null ? (map['package_price'] as num).toDouble() : null,
      canSellByUnit: map['can_sell_by_unit'] as bool? ?? true,
      canSellByPackage: map['can_sell_by_package'] as bool? ?? false,
    );
  }

  /// Convierte el producto a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'category': category,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'current_stock': currentStock,
      'min_stock': minStock,
      'max_stock': maxStock,
      'unit': unit,
      'image_url': imageUrl,
      'is_active': isActive,
      'business_id': businessId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'supplier': supplier,
      'location': location,
      'weight': weight,
      'dimensions': dimensions,
      // Campos para unidades múltiples
      'conversion_factor': conversionFactor,
      'package_name': packageName,
      'package_price': packagePrice,
      'can_sell_by_unit': canSellByUnit,
      'can_sell_by_package': canSellByPackage,
    };
  }

  /// Crea una copia del producto con campos modificados
  ProductModel copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    String? category,
    double? purchasePrice,
    double? salePrice,
    int? currentStock,
    int? minStock,
    int? maxStock,
    String? unit,
    String? imageUrl,
    bool? isActive,
    int? businessId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? supplier,
    String? location,
    double? weight,
    String? dimensions,
    // Campos para unidades múltiples
    int? conversionFactor,
    String? packageName,
    double? packagePrice,
    bool? canSellByUnit,
    bool? canSellByPackage,
  }) {
    return ProductModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      // Campos para unidades múltiples
      conversionFactor: conversionFactor ?? this.conversionFactor,
      packageName: packageName ?? this.packageName,
      packagePrice: packagePrice ?? this.packagePrice,
      canSellByUnit: canSellByUnit ?? this.canSellByUnit,
      canSellByPackage: canSellByPackage ?? this.canSellByPackage,
    );
  }

  /// Calcula el margen de ganancia en porcentaje
  double get profitMargin {
    if (purchasePrice <= 0) return 0;
    return ((salePrice - purchasePrice) / purchasePrice) * 100;
  }

  /// Verifica si el stock está bajo
  bool get isLowStock => currentStock <= minStock;

  /// Verifica si está agotado
  bool get isOutOfStock => currentStock <= 0;

  /// Verifica si hay exceso de stock
  bool get hasExcessStock => currentStock > maxStock;

  /// Estado del stock
  StockStatus get stockStatus {
    if (isOutOfStock) return StockStatus.outOfStock;
    if (isLowStock) return StockStatus.lowStock;
    if (hasExcessStock) return StockStatus.excessStock;
    return StockStatus.normal;
  }

  /// Valor total del inventario de este producto
  double get totalInventoryValue => currentStock * purchasePrice;

  /// Valor potencial de venta
  double get totalSaleValue => currentStock * salePrice;

  // ===== MÉTODOS PARA UNIDADES MÚLTIPLES =====
  
  /// ¿Es un producto con unidades múltiples?
  bool get hasMultipleUnits => conversionFactor != null && conversionFactor! > 1;
  
  /// Número de paquetes completos disponibles
  int get fullPackages => hasMultipleUnits ? currentStock ~/ conversionFactor! : 0;
  
  /// Número de unidades sueltas (sin empaquetar)
  int get looseUnits => hasMultipleUnits ? currentStock % conversionFactor! : currentStock;
  
  /// Descripción del stock para mostrar al usuario
  String get stockDisplay {
    if (!hasMultipleUnits) {
      return '$currentStock $unit';
    }
    
    final packages = fullPackages;
    final loose = looseUnits;
    
    if (packages > 0 && loose > 0) {
      return '$packages ${packageName ?? 'paquetes'} + $loose $unit';
    } else if (packages > 0) {
      return '$packages ${packageName ?? 'paquetes'}';
    } else {
      return '$loose $unit';
    }
  }
  
  /// ¿Se puede vender un paquete completo?
  bool get canSellFullPackage => hasMultipleUnits && canSellByPackage && fullPackages > 0;
  
  /// Precio unitario calculado del paquete
  double get calculatedUnitPrice {
    if (packagePrice != null && conversionFactor != null && conversionFactor! > 0) {
      return packagePrice! / conversionFactor!;
    }
    return salePrice;
  }

  @override
  String toString() {
    return 'ProductModel{id: $id, code: $code, name: $name, stock: $currentStock}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id && other.code == code;
  }

  @override
  int get hashCode => id.hashCode ^ code.hashCode;
}

/// Enumeración para el estado del stock
enum StockStatus {
  outOfStock('Agotado', 0xFFE57373),
  lowStock('Stock Bajo', 0xFFFFB74D),
  normal('Normal', 0xFF81C784),
  excessStock('Exceso', 0xFF64B5F6);

  const StockStatus(this.displayName, this.colorValue);
  
  final String displayName;
  final int colorValue;
}

/// Modelo para movimientos de inventario
class InventoryMovement {
  final int id;
  final int productId;
  final MovementType type;
  final int quantity;
  final double unitPrice;
  final String reason;
  final int userId;
  final String? reference; // número de factura, orden de compra, etc.
  final DateTime createdAt;

  const InventoryMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.reason,
    required this.userId,
    this.reference,
    required this.createdAt,
  });

  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      type: MovementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MovementType.adjustment,
      ),
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      reason: map['reason'] as String,
      userId: map['user_id'] as int,
      reference: map['reference'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'type': type.name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'reason': reason,
      'user_id': userId,
      'reference': reference,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Valor total del movimiento
  double get totalValue => quantity * unitPrice;
}

/// Tipos de movimiento de inventario
enum MovementType {
  entry('Entrada', 0xFF4CAF50, true),
  exit('Salida', 0xFFF44336, false),
  adjustment('Ajuste', 0xFF2196F3, null),
  transfer('Transferencia', 0xFF9C27B0, null);

  const MovementType(this.displayName, this.colorValue, this.isPositive);
  
  final String displayName;
  final int colorValue;
  final bool? isPositive; // true = suma, false = resta, null = puede ser ambos
}