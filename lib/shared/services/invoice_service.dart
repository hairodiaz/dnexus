import '../models/invoice_model.dart';
import 'inventory_service.dart';
import 'client_service.dart';
import 'cash_register_service.dart';

/// Servicio para gestionar facturas con workflow completo
class InvoiceService {
  static List<InvoiceModel> _invoices = [];
  static int _nextNumber = 1;
  static bool _initialized = false;

  /// Inicializa el servicio sin datos de muestra
  static void initialize() {
    if (_initialized) return;
    
    _invoices = []; // Sin datos de muestra - crear desde cero
    _nextNumber = 1;
    _initialized = true;
  }

  /// Crear nueva factura
  static Future<InvoiceModel> createInvoice({
    required String businessId,
    required String createdBy,
    String? customerId,
    String? customerName,
    String? customerCedula,
    String? customerPhone,
    String? customerEmail,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    initialize();

    final invoice = InvoiceModel.createFromItems(
      id: 'invoice_${DateTime.now().millisecondsSinceEpoch}',
      number: _nextNumber.toString(),
      date: DateTime.now(),
      businessId: businessId,
      customerId: customerId,
      customerName: customerName,
      customerCedula: customerCedula,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      items: [],
      createdBy: createdBy,
      notes: notes,
    );

    _invoices.add(invoice);
    _nextNumber++;

    return invoice;
  }

  /// Agregar item a factura
  static Future<InvoiceModel> addItemToInvoice({
    required String invoiceId,
    required String productId,
    required double quantity,
    String unit = 'unidad',
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    initialize();

    final invoiceIndex = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (invoiceIndex == -1) {
      throw Exception('Factura no encontrada');
    }

    final invoice = _invoices[invoiceIndex];
    if (invoice.status != InvoiceStatus.draft) {
      throw Exception('No se pueden agregar items a una factura ${invoice.status.displayName}');
    }

    // Obtener producto del inventario
    final products = await InventoryService.getProducts(1);
    final product = products.firstWhere(
      (p) => p.id.toString() == productId.toString(),
      orElse: () => throw Exception('Producto no encontrado'),
    );

    // Verificar stock disponible
    if (product.currentStock < quantity) {
      throw Exception('Stock insuficiente. Disponible: ${product.currentStock} ${product.unit}');
    }

    // Crear item de factura
    final item = InvoiceItemModel(
      productId: product.id.toString(),
      productName: product.name,
      productCode: product.code,
      unitPrice: product.salePrice,
      quantity: quantity,
      unit: unit,
      tax: 0.0, // IVA se puede configurar después
    );

    // Verificar si ya existe el producto en la factura
    final existingItemIndex = invoice.items.indexWhere(
      (item) => item.productId == productId && item.unit == unit,
    );

    List<InvoiceItemModel> newItems;
    if (existingItemIndex != -1) {
      // Actualizar cantidad si ya existe
      newItems = List.from(invoice.items);
      final existingItem = newItems[existingItemIndex];
      newItems[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      // Agregar nuevo item
      newItems = [...invoice.items, item];
    }

    // Recalcular totales
    final updatedInvoice = _recalculateInvoiceTotals(invoice.copyWith(items: newItems));
    _invoices[invoiceIndex] = updatedInvoice;

    return updatedInvoice;
  }

  /// Remover item de factura
  static Future<InvoiceModel> removeItemFromInvoice({
    required String invoiceId,
    required String productId,
    required String unit,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    initialize();

    final invoiceIndex = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (invoiceIndex == -1) {
      throw Exception('Factura no encontrada');
    }

    final invoice = _invoices[invoiceIndex];
    if (invoice.status != InvoiceStatus.draft) {
      throw Exception('No se pueden remover items de una factura ${invoice.status.displayName}');
    }

    final newItems = invoice.items.where(
      (item) => !(item.productId == productId && item.unit == unit),
    ).toList();

    final updatedInvoice = _recalculateInvoiceTotals(invoice.copyWith(items: newItems));
    _invoices[invoiceIndex] = updatedInvoice;

    return updatedInvoice;
  }

  /// Actualizar cantidad de item
  static Future<InvoiceModel> updateItemQuantity({
    required String invoiceId,
    required String productId,
    required String unit,
    required double newQuantity,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    initialize();

    if (newQuantity <= 0) {
      return removeItemFromInvoice(
        invoiceId: invoiceId,
        productId: productId,
        unit: unit,
      );
    }

    final invoiceIndex = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (invoiceIndex == -1) {
      throw Exception('Factura no encontrada');
    }

    final invoice = _invoices[invoiceIndex];
    if (invoice.status != InvoiceStatus.draft) {
      throw Exception('No se puede modificar una factura ${invoice.status.displayName}');
    }

    // Verificar stock
    final products = await InventoryService.getProducts(1);
    final product = products.firstWhere(
      (p) => p.id.toString() == productId.toString(),
      orElse: () => throw Exception('Producto no encontrado'),
    );

    if (product.currentStock < newQuantity) {
      throw Exception('Stock insuficiente. Disponible: ${product.currentStock} ${product.unit}');
    }

    final itemIndex = invoice.items.indexWhere(
      (item) => item.productId == productId && item.unit == unit,
    );

    if (itemIndex == -1) {
      throw Exception('Item no encontrado en la factura');
    }

    final newItems = List<InvoiceItemModel>.from(invoice.items);
    newItems[itemIndex] = newItems[itemIndex].copyWith(quantity: newQuantity);

    final updatedInvoice = _recalculateInvoiceTotals(invoice.copyWith(items: newItems));
    _invoices[invoiceIndex] = updatedInvoice;

    return updatedInvoice;
  }

  /// Enviar factura a caja (Facturador → Caja)
  static Future<InvoiceModel> sendToCashier(String invoiceId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    initialize();

    final invoiceIndex = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (invoiceIndex == -1) {
      throw Exception('Factura no encontrada');
    }

    final invoice = _invoices[invoiceIndex];
    if (invoice.status != InvoiceStatus.created) {
      throw Exception('Solo se pueden enviar a caja facturas en estado Creada');
    }

    if (invoice.items.isEmpty) {
      throw Exception('No se puede enviar una factura sin productos');
    }

    final updatedInvoice = invoice.copyWith(status: InvoiceStatus.inCashier);
    _invoices[invoiceIndex] = updatedInvoice;

    return updatedInvoice;
  }

  /// Procesar pago (Caja → Pagada)
  static Future<InvoiceModel> processPayment({
    required String invoiceId,
    required String processedBy,
    required PaymentMethod paymentMethod,
    required double paidAmount,
    int? userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    initialize();

    // Validar que el usuario tenga caja abierta (si se proporciona userId)
    if (userId != null) {
      final canProcess = CashRegisterService.canProcessPayments(userId);
      if (!canProcess) {
        throw Exception('No puedes procesar pagos sin tener una caja registradora abierta. Abre tu caja primero.');
      }
    }

    final invoiceIndex = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (invoiceIndex == -1) {
      throw Exception('Factura no encontrada');
    }

    final invoice = _invoices[invoiceIndex];
    if (invoice.status != InvoiceStatus.inCashier) {
      throw Exception('Solo se pueden procesar pagos de facturas en Caja');
    }

    if (paidAmount < invoice.total) {
      throw Exception('El monto pagado es insuficiente');
    }

    final changeAmount = paidAmount - invoice.total;
    final now = DateTime.now();

    final updatedInvoice = invoice.copyWith(
      status: InvoiceStatus.paid,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      processedBy: processedBy,
      paidAt: now,
    );

    _invoices[invoiceIndex] = updatedInvoice;

    return updatedInvoice;
  }

  /// Completar factura (descontar inventario y crear transacción)
  static Future<InvoiceModel> completeInvoice(String invoiceId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    initialize();

    final invoiceIndex = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (invoiceIndex == -1) {
      throw Exception('Factura no encontrada');
    }

    final invoice = _invoices[invoiceIndex];
    if (invoice.status != InvoiceStatus.paid) {
      throw Exception('Solo se pueden completar facturas pagadas');
    }

    // Descontar stock del inventario
    for (final item in invoice.items) {
      try {
        final products = await InventoryService.getProducts(1);
        final product = products.firstWhere((p) => p.id.toString() == item.productId);
        // TODO: Implementar cuando tengamos objeto UserModel del createdBy
        // await InventoryService.updateStock(
        //   int.parse(item.productId),
        //   (product.currentStock - item.quantity).round(),
        //   'Venta - Factura ${invoice.formattedNumber}',
        //   userObject,
        // );
      } catch (e) {
        throw Exception('Error actualizando inventario: $e');
      }
    }

    // TODO: Crear transacción automática cuando esté disponible
    // try {
    //   await TransactionService.createFromInvoice(invoice);
    // } catch (e) {
    //   print('Warning: No se pudo crear la transacción automática: $e');
    // }

    // Actualizar cliente si existe
    if (invoice.customerId != null) {
      try {
        await ClientService.updateClientPurchase(
          invoice.customerId!,
          invoice.total,
          invoice.date,
        );
      } catch (e) {
        print('Warning: No se pudo actualizar cliente: $e');
      }
    }

    final updatedInvoice = invoice.copyWith(
      status: InvoiceStatus.completed,
      completedAt: DateTime.now(),
    );

    _invoices[invoiceIndex] = updatedInvoice;

    return updatedInvoice;
  }

  /// Cancelar factura
  static Future<InvoiceModel> cancelInvoice(String invoiceId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 300));
    initialize();

    final invoiceIndex = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (invoiceIndex == -1) {
      throw Exception('Factura no encontrada');
    }

    final invoice = _invoices[invoiceIndex];
    if (invoice.status == InvoiceStatus.completed) {
      throw Exception('No se pueden cancelar facturas completadas');
    }

    final updatedInvoice = invoice.copyWith(
      status: InvoiceStatus.cancelled,
      notes: '${invoice.notes ?? ''}\nCANCELADA: $reason',
    );

    _invoices[invoiceIndex] = updatedInvoice;

    return updatedInvoice;
  }

  /// Obtener todas las facturas
  static List<InvoiceModel> getAllInvoices() {
    initialize();
    return List.from(_invoices);
  }

  /// Obtener facturas por negocio
  static List<InvoiceModel> getInvoicesByBusiness(String businessId) {
    initialize();
    return _invoices.where((inv) => inv.businessId == businessId).toList();
  }

  /// Obtener facturas por estado
  static List<InvoiceModel> getInvoicesByStatus(InvoiceStatus status, [String? businessId]) {
    initialize();
    var invoices = _invoices.where((inv) => inv.status == status);
    if (businessId != null) {
      invoices = invoices.where((inv) => inv.businessId == businessId);
    }
    return invoices.toList();
  }

  /// Obtener facturas del día
  static List<InvoiceModel> getTodayInvoices([String? businessId]) {
    initialize();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    var invoices = _invoices.where((inv) => 
      inv.date.isAfter(startOfDay) && inv.date.isBefore(endOfDay));
    
    if (businessId != null) {
      invoices = invoices.where((inv) => inv.businessId == businessId);
    }
    
    return invoices.toList();
  }

  /// Obtener estadísticas de facturación
  static Map<String, dynamic> getInvoiceStats([String? businessId]) {
    initialize();
    
    var invoices = _invoices.asMap().values;
    if (businessId != null) {
      invoices = invoices.where((inv) => inv.businessId == businessId);
    }

    final today = getTodayInvoices(businessId);
    final completed = invoices.where((inv) => inv.status == InvoiceStatus.completed);
    final pending = invoices.where((inv) => 
      inv.status == InvoiceStatus.created || inv.status == InvoiceStatus.inCashier);

    return {
      'total': invoices.length,
      'today': today.length,
      'completed': completed.length,
      'pending': pending.length,
      'todaySales': today.fold(0.0, (sum, inv) => sum + inv.total),
      'totalSales': completed.fold(0.0, (sum, inv) => sum + inv.total),
      'averageTicket': completed.isNotEmpty 
          ? completed.fold(0.0, (sum, inv) => sum + inv.total) / completed.length
          : 0.0,
    };
  }

  /// Obtener factura por ID
  static InvoiceModel? getInvoiceById(String invoiceId) {
    initialize();
    try {
      return _invoices.firstWhere((inv) => inv.id == invoiceId);
    } catch (e) {
      return null;
    }
  }

  /// Buscar facturas por número o cliente
  static List<InvoiceModel> searchInvoices(String query, [String? businessId]) {
    initialize();
    if (query.isEmpty) return getInvoicesByBusiness(businessId ?? '');

    final lowerQuery = query.toLowerCase();
    var results = _invoices.where((invoice) {
      return invoice.number.contains(lowerQuery) ||
             invoice.formattedNumber.toLowerCase().contains(lowerQuery) ||
             (invoice.customerName?.toLowerCase().contains(lowerQuery) ?? false) ||
             (invoice.customerCedula?.contains(query) ?? false);
    });

    if (businessId != null) {
      results = results.where((inv) => inv.businessId == businessId);
    }

    return results.toList();
  }

  /// Crear borrador (estado draft)
  static Future<InvoiceModel> createDraft({
    required String businessId,
    required String createdBy,
  }) async {
    final invoice = await createInvoice(
      businessId: businessId,
      createdBy: createdBy,
    );
    return invoice; // Ya se crea en estado draft
  }

  /// Confirmar borrador (draft → created)
  static Future<InvoiceModel> confirmDraft(String invoiceId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    initialize();

    final invoiceIndex = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (invoiceIndex == -1) {
      throw Exception('Factura no encontrada');
    }

    final invoice = _invoices[invoiceIndex];
    if (invoice.status != InvoiceStatus.draft) {
      throw Exception('Solo se pueden confirmar facturas en borrador');
    }

    if (invoice.items.isEmpty) {
      throw Exception('No se puede confirmar una factura sin productos');
    }

    final updatedInvoice = invoice.copyWith(status: InvoiceStatus.created);
    _invoices[invoiceIndex] = updatedInvoice;

    return updatedInvoice;
  }

  /// Recalcular totales de una factura
  static InvoiceModel _recalculateInvoiceTotals(InvoiceModel invoice) {
    final subtotal = invoice.items.fold(0.0, (sum, item) => sum + item.subtotal);
    final totalDiscount = invoice.items.fold(0.0, (sum, item) => sum + item.discountAmount);
    final totalTax = invoice.items.fold(0.0, (sum, item) => sum + item.taxAmount);
    final total = invoice.items.fold(0.0, (sum, item) => sum + item.total);

    return invoice.copyWith(
      subtotal: subtotal,
      totalDiscount: totalDiscount,
      totalTax: totalTax,
      total: total,
    );
  }

  /// Generar facturas de muestra
  static List<InvoiceModel> _generateSampleInvoices() {
    final now = DateTime.now();
    
    return [
      // Factura completada
      InvoiceModel(
        id: 'invoice_1',
        number: '1',
        date: now.subtract(const Duration(hours: 2)),
        status: InvoiceStatus.completed,
        businessId: 'ferreteria_1',
        customerId: 'client_1',
        customerName: 'Carlos Rodriguez',
        customerCedula: '12345678',
        items: [
          InvoiceItemModel(
            productId: 'prod_1',
            productName: 'Aceite de Motor 20W-50',
            productCode: 'ACE001',
            unitPrice: 45000,
            quantity: 2,
            unit: 'unidad',
          ),
        ],
        subtotal: 90000,
        totalDiscount: 0,
        totalTax: 0,
        total: 90000,
        paymentMethod: PaymentMethod.cash,
        paidAmount: 100000,
        changeAmount: 10000,
        createdBy: 'emp_1',
        processedBy: 'emp_2',
        createdAt: now.subtract(const Duration(hours: 2)),
        paidAt: now.subtract(const Duration(hours: 1, minutes: 55)),
        completedAt: now.subtract(const Duration(hours: 1, minutes: 50)),
      ),

      // Factura en caja
      InvoiceModel(
        id: 'invoice_2',
        number: '2',
        date: now.subtract(const Duration(minutes: 30)),
        status: InvoiceStatus.inCashier,
        businessId: 'ferreteria_1',
        customerName: 'María González',
        items: [
          InvoiceItemModel(
            productId: 'prod_2',
            productName: 'Destornillador Phillips',
            productCode: 'DEST001',
            unitPrice: 15000,
            quantity: 1,
            unit: 'unidad',
          ),
        ],
        subtotal: 15000,
        totalDiscount: 0,
        totalTax: 0,
        total: 15000,
        createdBy: 'emp_3',
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),

      // Factura creada (lista para enviar a caja)
      InvoiceModel(
        id: 'invoice_3',
        number: '3',
        date: now.subtract(const Duration(minutes: 10)),
        status: InvoiceStatus.created,
        businessId: 'ferreteria_1',
        items: [
          InvoiceItemModel(
            productId: 'prod_3',
            productName: 'Martillo',
            productCode: 'MART001',
            unitPrice: 25000,
            quantity: 1,
            unit: 'unidad',
          ),
        ],
        subtotal: 25000,
        totalDiscount: 0,
        totalTax: 0,
        total: 25000,
        createdBy: 'emp_3',
        createdAt: now.subtract(const Duration(minutes: 10)),
      ),
    ];
  }
}