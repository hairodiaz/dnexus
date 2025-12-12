import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/user_extensions.dart';
import '../../core/utils/platform_detector.dart';
import 'supabase_http_client.dart';

/// Servicio para gestión de inventario con permisos por rol
class InventoryService {
  static final List<ProductModel> _products = [];
  static final List<InventoryMovement> _movements = [];
  static int _nextProductId = 1;
  static int _nextMovementId = 1;
  static bool _isInitialized = false;

  /// Inicializa el servicio con productos de ejemplo
  static void _initializeIfNeeded() {
    if (_isInitialized) return;
    // Clean system mode - no sample products
    _isInitialized = true;
  }

  /// Obtiene todos los productos de un negocio
  static Future<List<ProductModel>> getProducts(int businessId) async {
    _initializeIfNeeded();
    await Future.delayed(const Duration(milliseconds: 300));
    return _products.where((p) => p.businessId == businessId).toList();
  }

  /// Obtiene todos los productos (asincrónico, usa Supabase en web)
  static Future<List<ProductModel>> getProductsAsync(String negocioId) async {
    // En web, usar Supabase
    if (PlatformDetector.isWeb) {
      try {
        final SupabaseHttpClient supabaseClient = SupabaseHttpClient();
        final data = await supabaseClient.getProductsByBusiness(negocioId);
        return data.map((json) {
          return ProductModel(
            id: int.tryParse(json['id'].toString()) ?? 0,
            code: json['codigo'] ?? '',
            name: json['nombre'] ?? '',
            description: json['descripcion'] ?? '',
            category: '',
            purchasePrice: double.tryParse(json['precio'].toString()) ?? 0,
            salePrice: double.tryParse(json['precio'].toString()) ?? 0,
            currentStock: int.tryParse(json['stock'].toString()) ?? 0,
            minStock: 5,
            maxStock: 100,
            unit: 'unidad',
            isActive: json['activo'] ?? true,
            businessId: int.tryParse(negocioId) ?? 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
      } catch (e) {
        return [];
      }
    }

    // En nativo, usar lista en memoria
    return getProducts(int.tryParse(negocioId) ?? 0);
  }

  /// Busca productos por nombre, código o categoría
  static Future<List<ProductModel>> searchProducts(
    int businessId,
    String query,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final lowercaseQuery = query.toLowerCase();
    return _products.where((product) =>
      product.businessId == businessId &&
      (product.name.toLowerCase().contains(lowercaseQuery) ||
       product.code.toLowerCase().contains(lowercaseQuery) ||
       product.category.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  /// Busca productos de forma asincrónica (usa Supabase en web)
  static Future<List<ProductModel>> searchProductsAsync(
    String negocioId,
    String query,
  ) async {
    // En web, usar Supabase
    if (PlatformDetector.isWeb) {
      try {
        final SupabaseHttpClient supabaseClient = SupabaseHttpClient();
        final data = await supabaseClient.searchProducts(query);
        
        // Filtrar por negocio si es necesario
        return data.where((json) => json['negocio_id'].toString() == negocioId).map((json) {
          return ProductModel(
            id: int.tryParse(json['id'].toString()) ?? 0,
            code: json['codigo'] ?? '',
            name: json['nombre'] ?? '',
            description: json['descripcion'] ?? '',
            category: '',
            purchasePrice: double.tryParse(json['precio'].toString()) ?? 0,
            salePrice: double.tryParse(json['precio'].toString()) ?? 0,
            currentStock: int.tryParse(json['stock'].toString()) ?? 0,
            minStock: 5,
            maxStock: 100,
            unit: 'unidad',
            isActive: json['activo'] ?? true,
            businessId: int.tryParse(negocioId) ?? 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
      } catch (e) {
        return [];
      }
    }

    // En nativo, usar búsqueda local
    return searchProducts(int.tryParse(negocioId) ?? 0, query);
  }

  /// Obtiene productos por categoría
  static Future<List<ProductModel>> getProductsByCategory(
    int businessId,
    String category,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _products
        .where((p) => p.businessId == businessId && p.category == category)
        .toList();
  }

  /// Obtiene productos con stock bajo
  static Future<List<ProductModel>> getLowStockProducts(int businessId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _products
        .where((p) => p.businessId == businessId && p.isLowStock)
        .toList();
  }

  /// Obtiene productos agotados
  static Future<List<ProductModel>> getOutOfStockProducts(int businessId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _products
        .where((p) => p.businessId == businessId && p.isOutOfStock)
        .toList();
  }

  /// Obtiene todas las categorías de un negocio
  static Future<List<String>> getCategories(int businessId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _products
        .where((p) => p.businessId == businessId)
        .map((p) => p.category)
        .toSet()
        .toList();
  }

  /// Registra un nuevo producto (requiere permisos de Admin o Caja)
  static Future<ProductModel> createProduct(
    ProductModel product,
    UserModel user,
  ) async {
    if (!_canManageInventory(user)) {
      throw Exception('No tienes permisos para crear productos');
    }

    await Future.delayed(const Duration(milliseconds: 400));

    // Verificar que el código sea único
    final existingProduct = _products.firstWhere(
      (p) => p.code == product.code && p.businessId == product.businessId,
      orElse: () => ProductModel(
        id: 0,
        code: '',
        name: '',
        description: '',
        category: '',
        purchasePrice: 0,
        salePrice: 0,
        currentStock: 0,
        minStock: 0,
        maxStock: 0,
        unit: '',
        isActive: true,
        businessId: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (existingProduct.id != 0) {
      throw Exception('Ya existe un producto con el código ${product.code}');
    }

    final now = DateTime.now();
    final newProduct = product.copyWith(
      id: _nextProductId++,
      createdAt: now,
      updatedAt: now,
    );

    _products.add(newProduct);

    // Registrar movimiento inicial si hay stock
    if (newProduct.currentStock > 0) {
      await _recordMovement(
        productId: newProduct.id,
        type: MovementType.entry,
        quantity: newProduct.currentStock,
        unitPrice: newProduct.purchasePrice,
        reason: 'Stock inicial del producto',
        userId: user.id,
        reference: 'INICIAL-${newProduct.code}',
      );
    }

    return newProduct;
  }

  /// Registra un nuevo producto de forma asincrónica (usa Supabase en web)
  static Future<bool> createProductAsync(
    String nombre,
    String descripcion,
    String codigo,
    double precio,
    int stock,
    String negocioId,
  ) async {
    // En web, usar Supabase
    if (PlatformDetector.isWeb) {
      try {
        final SupabaseHttpClient supabaseClient = SupabaseHttpClient();
        return await supabaseClient.createProduct({
          'nombre': nombre,
          'descripcion': descripcion,
          'codigo': codigo,
          'precio': precio,
          'stock': stock,
          'negocio_id': negocioId,
          'activo': true,
        });
      } catch (e) {
        return false;
      }
    }

    // En nativo, requiere permisos y crear ProductModel local
    return false; // Versión nativa requiere UserModel y manejo más completo
  }

  /// Actualiza un producto existente
  static Future<ProductModel> updateProduct(
    ProductModel product,
    UserModel user,
  ) async {
    if (!_canManageInventory(user)) {
      throw Exception('No tienes permisos para editar productos');
    }

    await Future.delayed(const Duration(milliseconds: 300));

    final index = _products.indexWhere((p) => p.id == product.id);
    if (index == -1) {
      throw Exception('Producto no encontrado');
    }

    final updatedProduct = product.copyWith(updatedAt: DateTime.now());
    _products[index] = updatedProduct;

    return updatedProduct;
  }

  /// Elimina un producto (solo Admin)
  static Future<void> deleteProduct(int productId, UserModel user) async {
    if (!user.isAdmin) {
      throw Exception('Solo los administradores pueden eliminar productos');
    }

    await Future.delayed(const Duration(milliseconds: 200));

    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) {
      throw Exception('Producto no encontrado');
    }

    _products.removeAt(index);
    
    // Limpiar movimientos del producto eliminado
    _movements.removeWhere((m) => m.productId == productId);
  }

  /// Actualiza stock de un producto (Admin y Caja)
  static Future<ProductModel> updateStock(
    int productId,
    int newStock,
    String reason,
    UserModel user, {
    String? reference,
  }) async {
    if (!_canReceiveInventory(user)) {
      throw Exception('No tienes permisos para actualizar stock');
    }

    await Future.delayed(const Duration(milliseconds: 300));

    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) {
      throw Exception('Producto no encontrado');
    }

    final product = _products[index];
    final oldStock = product.currentStock;
    final difference = newStock - oldStock;

    final updatedProduct = product.copyWith(
      currentStock: newStock,
      updatedAt: DateTime.now(),
    );
    _products[index] = updatedProduct;

    // Registrar movimiento
    if (difference != 0) {
      await _recordMovement(
        productId: productId,
        type: difference > 0 ? MovementType.entry : MovementType.exit,
        quantity: difference.abs(),
        unitPrice: product.purchasePrice,
        reason: reason,
        userId: user.id,
        reference: reference,
      );
    }

    return updatedProduct;
  }

  /// Recibe mercancía (entrada de stock)
  static Future<ProductModel> receiveStock(
    int productId,
    int quantity,
    double unitPrice,
    String reason,
    UserModel user, {
    String? reference,
  }) async {
    if (!_canReceiveInventory(user)) {
      throw Exception('No tienes permisos para recibir mercancía');
    }

    await Future.delayed(const Duration(milliseconds: 300));

    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) {
      throw Exception('Producto no encontrado');
    }

    final product = _products[index];
    final newStock = product.currentStock + quantity;

    final updatedProduct = product.copyWith(
      currentStock: newStock,
      updatedAt: DateTime.now(),
    );
    _products[index] = updatedProduct;

    // Registrar movimiento
    await _recordMovement(
      productId: productId,
      type: MovementType.entry,
      quantity: quantity,
      unitPrice: unitPrice,
      reason: reason,
      userId: user.id,
      reference: reference,
    );

    return updatedProduct;
  }

  /// Registra salida de stock (venta)
  static Future<ProductModel> registerSale(
    int productId,
    int quantity,
    double unitPrice,
    UserModel user, {
    String? reference,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) {
      throw Exception('Producto no encontrado');
    }

    final product = _products[index];
    
    if (product.currentStock < quantity) {
      throw Exception('Stock insuficiente. Stock actual: ${product.currentStock}');
    }

    final newStock = product.currentStock - quantity;
    final updatedProduct = product.copyWith(
      currentStock: newStock,
      updatedAt: DateTime.now(),
    );
    _products[index] = updatedProduct;

    // Registrar movimiento
    await _recordMovement(
      productId: productId,
      type: MovementType.exit,
      quantity: quantity,
      unitPrice: unitPrice,
      reason: 'Venta',
      userId: user.id,
      reference: reference,
    );

    return updatedProduct;
  }

  /// Obtiene el historial de movimientos de un producto
  static Future<List<InventoryMovement>> getProductMovements(int productId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _movements
        .where((m) => m.productId == productId)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Obtiene todos los movimientos de inventario
  static Future<List<InventoryMovement>> getAllMovements(int businessId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Filtrar por productos del negocio
    final businessProductIds = _products
        .where((p) => p.businessId == businessId)
        .map((p) => p.id)
        .toSet();
    
    return _movements
        .where((m) => businessProductIds.contains(m.productId))
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Registra un movimiento de inventario
  static Future<void> _recordMovement({
    required int productId,
    required MovementType type,
    required int quantity,
    required double unitPrice,
    required String reason,
    required int userId,
    String? reference,
  }) async {
    final movement = InventoryMovement(
      id: _nextMovementId++,
      productId: productId,
      type: type,
      quantity: quantity,
      unitPrice: unitPrice,
      reason: reason,
      userId: userId,
      reference: reference,
      createdAt: DateTime.now(),
    );

    _movements.add(movement);
  }

  /// Obtiene estadísticas del inventario
  static Future<InventoryStats> getInventoryStats(int businessId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final products = _products.where((p) => p.businessId == businessId);
    
    return InventoryStats(
      totalProducts: products.length,
      lowStockProducts: products.where((p) => p.isLowStock).length,
      outOfStockProducts: products.where((p) => p.isOutOfStock).length,
      totalInventoryValue: products.fold(0.0, (sum, p) => sum + p.totalInventoryValue),
      totalSaleValue: products.fold(0.0, (sum, p) => sum + p.totalSaleValue),
    );
  }

  /// Inicializa con productos de ejemplo
  static void initializeWithSampleData(int businessId) {
    // Sample data initialization disabled - clean system mode
    return;
  }

  // Métodos auxiliares para verificar permisos
  static bool _canManageInventory(UserModel user) {
    return user.role == 'admin' || user.role == 'caja' || user.role == 'super_admin';
  }

  static bool _canReceiveInventory(UserModel user) {
    return user.role == 'admin' || user.role == 'caja' || user.role == 'super_admin';
  }
}

/// Estadísticas del inventario
class InventoryStats {
  final int totalProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final double totalInventoryValue;
  final double totalSaleValue;

  const InventoryStats({
    required this.totalProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.totalInventoryValue,
    required this.totalSaleValue,
  });

  double get potentialProfit => totalSaleValue - totalInventoryValue;
  double get profitMargin => totalInventoryValue > 0 
      ? (potentialProfit / totalInventoryValue) * 100 
      : 0;
}