import '../models/transaction_model.dart';
import '../models/transaction_audit_model.dart';
import '../enums/transaction_filter_enum.dart';
import 'transaction_audit_service.dart';
import '../../core/utils/platform_detector.dart';
import 'supabase_http_client.dart';

/// Servicio para manejar transacciones
class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  // Lista en memoria para desarrollo
  final List<TransactionModel> _transactions = [];
  final List<TransactionModel> _deletedTransactions = []; // Transacciones eliminadas
  final TransactionAuditService _auditService = TransactionAuditService();
  int _nextId = 1;

  /// Obtener transacciones por negocio
  Future<List<TransactionModel>> getTransactionsByBusiness(int businessId) async {
    return _transactions
        .where((transaction) => transaction.negocioId == businessId)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha)); // Más recientes primero
  }

  /// Obtener transacciones por negocio (asincrónico, usa Supabase en web)
  Future<List<TransactionModel>> getTransactionsByBusinessAsync(String negocioId) async {
    // En web, usar Supabase
    if (PlatformDetector.isWeb) {
      try {
        final SupabaseHttpClient supabaseClient = SupabaseHttpClient();
        final data = await supabaseClient.getTransactionsByBusiness(negocioId);
        return data.map((json) {
          return TransactionModel(
            id: int.tryParse(json['id'].toString()) ?? 0,
            tipo: json['tipo'] ?? 'ingreso',
            monto: double.tryParse(json['monto'].toString()) ?? 0,
            concepto: json['concepto'] ?? '',
            categoria: json['categoria'] ?? '',
            metodoPago: json['metodo_pago'] ?? 'efectivo',
            cliente: json['cliente_id'] != null ? json['cliente_id'].toString() : null,
            negocioId: int.tryParse(negocioId) ?? 0,
            fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
            observaciones: json['observaciones'] ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha)); // Más recientes primero
      } catch (e) {
        return [];
      }
    }

    // En nativo, usar lista en memoria
    return getTransactionsByBusiness(int.tryParse(negocioId) ?? 0);
  }

  /// Obtener transacciones filtradas por período, tipo y método de pago
  Future<List<TransactionModel>> getFilteredTransactions(
    int businessId, {
    TransactionPeriodFilter periodFilter = TransactionPeriodFilter.today,
    TransactionTypeFilter typeFilter = TransactionTypeFilter.all,
    TransactionPaymentFilter paymentFilter = TransactionPaymentFilter.all,
  }) async {
    final dateRange = periodFilter.getDateRange();
    
    return _transactions
        .where((transaction) {
          // Filtrar por negocio
          if (transaction.negocioId != businessId) return false;
          
          // Filtrar por fecha
          if (!dateRange.contains(transaction.fecha)) return false;
          
          // Filtrar por tipo
          if (typeFilter != TransactionTypeFilter.all && 
              transaction.tipo != typeFilter.name) {
            return false;
          }
          
          // Filtrar por método de pago
          if (paymentFilter != TransactionPaymentFilter.all && 
              transaction.metodoPago != paymentFilter.name) {
            return false;
          }
          
          return true;
        })
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha)); // Más recientes primero
  }

  /// Obtener transacciones eliminadas por negocio
  Future<List<TransactionModel>> getDeletedTransactionsByBusiness(int businessId) async {
    return _deletedTransactions
        .where((transaction) => transaction.negocioId == businessId)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  /// Crear nueva transacción
  Future<TransactionModel> createTransaction({
    required String tipo,
    required double monto,
    required String concepto,
    required String categoria,
    required String metodoPago,
    String? cliente,
    required DateTime fecha,
    required int negocioId,
    String? observaciones,
  }) async {
    final now = DateTime.now();
    
    final transaction = TransactionModel(
      id: _nextId++,
      tipo: tipo,
      monto: monto,
      concepto: concepto,
      categoria: categoria,
      metodoPago: metodoPago,
      cliente: cliente,
      fecha: fecha,
      negocioId: negocioId,
      observaciones: observaciones,
      createdAt: now,
      updatedAt: now,
    );

    if (!transaction.isValid) {
      throw Exception('Datos de transacción inválidos');
    }

    _transactions.add(transaction);
    
    // Registrar en auditoría
    await _auditService.logCreated(transaction, 1, userFullName: 'Usuario Sistema');
    
    return transaction;
  }

  /// Crear transacción de forma asincrónica (usa Supabase en web)
  Future<bool> createTransactionAsync({
    required String tipo,
    required double monto,
    required String concepto,
    required String categoria,
    required String metodoPago,
    String? cliente,
    required DateTime fecha,
    required String negocioId,
    String? observaciones,
  }) async {
    // En web, usar Supabase
    if (PlatformDetector.isWeb) {
      try {
        final SupabaseHttpClient supabaseClient = SupabaseHttpClient();
        return await supabaseClient.createTransaction({
          'tipo': tipo,
          'monto': monto,
          'concepto': concepto,
          'categoria': categoria,
          'metodo_pago': metodoPago,
          'cliente_id': cliente,
          'fecha': fecha.toIso8601String(),
          'negocio_id': negocioId,
          'observaciones': observaciones,
          'activo': true,
        });
      } catch (e) {
        return false;
      }
    }

    // En nativo, usar método local
    try {
      await createTransaction(
        tipo: tipo,
        monto: monto,
        concepto: concepto,
        categoria: categoria,
        metodoPago: metodoPago,
        cliente: cliente,
        fecha: fecha,
        negocioId: int.tryParse(negocioId) ?? 0,
        observaciones: observaciones,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar transacción existente con auditoría
  Future<TransactionModel> updateTransaction(
    int id,
    Map<String, dynamic> updates,
    int userId,
    String reason, {
    String? userFullName,
  }) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw Exception('Transacción no encontrada');
    }

    final oldTransaction = _transactions[index];
    final updatedTransaction = oldTransaction.copyWith(
      tipo: updates['tipo'] ?? oldTransaction.tipo,
      monto: updates['monto'] ?? oldTransaction.monto,
      concepto: updates['concepto'] ?? oldTransaction.concepto,
      categoria: updates['categoria'] ?? oldTransaction.categoria,
      metodoPago: updates['metodoPago'] ?? oldTransaction.metodoPago,
      cliente: updates['cliente'] ?? oldTransaction.cliente,
      fecha: updates['fecha'] ?? oldTransaction.fecha,
      observaciones: updates['observaciones'] ?? oldTransaction.observaciones,
      updatedAt: DateTime.now(),
    );

    if (!updatedTransaction.isValid) {
      throw Exception('Datos de transacción inválidos');
    }

    // Verificar si hay cambios reales
    final changes = _auditService.compareTransactions(oldTransaction, updatedTransaction);
    if (changes.isEmpty) {
      throw Exception('No se detectaron cambios en la transacción');
    }

    _transactions[index] = updatedTransaction;
    
    // Registrar en auditoría
    await _auditService.logUpdated(oldTransaction, updatedTransaction, userId, reason, userFullName: userFullName);
    
    return updatedTransaction;
  }

  /// Eliminar transacción (soft delete) con auditoría
  Future<bool> deleteTransaction(
    int id, 
    int userId, 
    String reason, {
    String? userFullName,
  }) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) {
      return false;
    }

    final transaction = _transactions[index];
    
    // Registrar en auditoría antes de eliminar
    await _auditService.logDeleted(transaction, userId, reason, userFullName: userFullName);
    
    // Soft delete - mover a lista de eliminadas
    _transactions.removeAt(index);
    _deletedTransactions.add(transaction);
    
    return true;
  }

  /// Obtener estadísticas de transacciones por negocio
  Future<Map<String, dynamic>> getTransactionStats(int businessId) async {
    final transactions = await getTransactionsByBusiness(businessId);
    
    double totalIngresos = 0;
    double totalEgresos = 0;
    int cantidadIngresos = 0;
    int cantidadEgresos = 0;

    for (final transaction in transactions) {
      if (transaction.tipo == 'ingreso') {
        totalIngresos += transaction.monto;
        cantidadIngresos++;
      } else {
        totalEgresos += transaction.monto;
        cantidadEgresos++;
      }
    }

    return {
      'totalIngresos': totalIngresos,
      'totalEgresos': totalEgresos,
      'balance': totalIngresos - totalEgresos,
      'cantidadIngresos': cantidadIngresos,
      'cantidadEgresos': cantidadEgresos,
      'totalTransacciones': transactions.length,
    };
  }

  /// Obtener estadísticas filtradas por período, tipo y método de pago
  Future<Map<String, dynamic>> getFilteredTransactionStats(
    int businessId, {
    TransactionPeriodFilter periodFilter = TransactionPeriodFilter.today,
    TransactionTypeFilter typeFilter = TransactionTypeFilter.all,
    TransactionPaymentFilter paymentFilter = TransactionPaymentFilter.all,
  }) async {
    final transactions = await getFilteredTransactions(
      businessId,
      periodFilter: periodFilter,
      typeFilter: typeFilter,
      paymentFilter: paymentFilter,
    );
    
    double totalIngresos = 0;
    double totalEgresos = 0;
    int cantidadIngresos = 0;
    int cantidadEgresos = 0;

    for (final transaction in transactions) {
      if (transaction.tipo == 'ingreso') {
        totalIngresos += transaction.monto;
        cantidadIngresos++;
      } else {
        totalEgresos += transaction.monto;
        cantidadEgresos++;
      }
    }

    return {
      'totalIngresos': totalIngresos,
      'totalEgresos': totalEgresos,
      'balance': totalIngresos - totalEgresos,
      'cantidadIngresos': cantidadIngresos,
      'cantidadEgresos': cantidadEgresos,
      'totalTransacciones': transactions.length,
      'periodFilter': periodFilter,
      'typeFilter': typeFilter,
      'paymentFilter': paymentFilter,
    };
  }

  /// Obtener transacciones por rango de fechas
  Future<List<TransactionModel>> getTransactionsByDateRange(
    int businessId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final transactions = await getTransactionsByBusiness(businessId);
    
    return transactions.where((transaction) {
      return transaction.fecha.isAfter(startDate.subtract(const Duration(days: 1))) &&
             transaction.fecha.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Obtener transacciones por tipo
  Future<List<TransactionModel>> getTransactionsByType(
    int businessId,
    String tipo,
  ) async {
    final transactions = await getTransactionsByBusiness(businessId);
    return transactions.where((t) => t.tipo == tipo).toList();
  }

  /// Obtener transacciones por categoría
  Future<List<TransactionModel>> getTransactionsByCategory(
    int businessId,
    String categoria,
  ) async {
    final transactions = await getTransactionsByBusiness(businessId);
    return transactions.where((t) => t.categoria == categoria).toList();
  }

  /// Obtener transacciones por método de pago
  Future<List<TransactionModel>> getTransactionsByPaymentMethod(
    int businessId,
    String metodoPago,
  ) async {
    final transactions = await getTransactionsByBusiness(businessId);
    return transactions.where((t) => t.metodoPago == metodoPago).toList();
  }

  /// Inicializar datos de ejemplo para desarrollo según tipo de negocio
  Future<void> initializeSampleData(int businessId, String tipoNegocio) async {
    // Sample data disabled - clean system mode
    return;

    final now = DateTime.now();
    
    // Datos de ejemplo según tipo de negocio
    List<Map<String, dynamic>> sampleTransactions;
    
    switch (tipoNegocio) {
      case 'prestamos':
        sampleTransactions = [
          // Transacciones de hoy
          {
            'tipo': 'ingreso',
            'monto': 450.0,
            'concepto': 'Pago de préstamo - María García',
            'categoria': 'Pago de Capital',
            'metodoPago': 'efectivo',
            'cliente': 'María García',
            'fecha': now,
          },
          {
            'tipo': 'ingreso',
            'monto': 300.0,
            'concepto': 'Intereses del día',
            'categoria': 'Pago de Intereses',
            'metodoPago': 'banco',
            'cliente': 'Juan Pérez',
            'fecha': now,
          },
          // Transacciones de ayer
          {
            'tipo': 'egreso',
            'monto': 800.0,
            'concepto': 'Préstamo otorgado - Carlos López',
            'categoria': 'Préstamo Otorgado',
            'metodoPago': 'efectivo',
            'cliente': 'Carlos López',
            'fecha': now.subtract(const Duration(days: 1)),
          },
          {
            'tipo': 'ingreso',
            'monto': 200.0,
            'concepto': 'Pago cuota - Ana Rodríguez',
            'categoria': 'Pago de Capital',
            'metodoPago': 'tarjeta',
            'cliente': 'Ana Rodríguez',
            'fecha': now.subtract(const Duration(days: 1)),
          },
          // Transacciones de hace una semana
          {
            'tipo': 'egreso',
            'monto': 45.0,
            'concepto': 'Gastos de oficina',
            'categoria': 'Gastos Operativos',
            'metodoPago': 'efectivo',
            'fecha': now.subtract(const Duration(days: 7)),
          },
          {
            'tipo': 'ingreso',
            'monto': 150.0,
            'concepto': 'Pago semanal',
            'categoria': 'Pago de Intereses',
            'metodoPago': 'banco',
            'cliente': 'Roberto Silva',
            'fecha': now.subtract(const Duration(days: 8)),
          },
          // Transacciones del mes pasado
          {
            'tipo': 'egreso',
            'monto': 1200.0,
            'concepto': 'Préstamo grande - Luis Herrera',
            'categoria': 'Préstamo Otorgado',
            'metodoPago': 'banco',
            'cliente': 'Luis Herrera',
            'fecha': now.subtract(const Duration(days: 35)),
          },
        ];
        break;
        
      case 'repuestos':
        sampleTransactions = [
          // Transacciones de hoy
          {
            'tipo': 'ingreso',
            'monto': 250.0,
            'concepto': 'Venta repuesto amortiguador',
            'categoria': 'Venta de Repuestos',
            'metodoPago': 'efectivo',
            'cliente': 'Taller El Rápido',
            'fecha': now,
          },
          {
            'tipo': 'ingreso',
            'monto': 85.0,
            'concepto': 'Venta filtro aire',
            'categoria': 'Venta de Repuestos',
            'metodoPago': 'tarjeta',
            'cliente': 'Mecánica José',
            'fecha': now,
          },
          // Transacciones de ayer
          {
            'tipo': 'egreso',
            'monto': 180.0,
            'concepto': 'Compra de filtros de aceite',
            'categoria': 'Compra de Inventario',
            'metodoPago': 'banco',
            'fecha': now.subtract(const Duration(days: 1)),
          },
          {
            'tipo': 'ingreso',
            'monto': 150.0,
            'concepto': 'Instalación de frenos',
            'categoria': 'Servicios',
            'metodoPago': 'tarjeta',
            'cliente': 'Pedro Martínez',
            'fecha': now.subtract(const Duration(days: 1)),
          },
          // Transacciones de la semana pasada
          {
            'tipo': 'egreso',
            'monto': 320.0,
            'concepto': 'Compra llantas mayoreo',
            'categoria': 'Compra de Inventario',
            'metodoPago': 'banco',
            'fecha': now.subtract(const Duration(days: 8)),
          },
          {
            'tipo': 'ingreso',
            'monto': 95.0,
            'concepto': 'Venta batería',
            'categoria': 'Venta de Repuestos',
            'metodoPago': 'efectivo',
            'cliente': 'Carlos Auto',
            'fecha': now.subtract(const Duration(days: 9)),
          },
          // Transacciones del mes pasado
          {
            'tipo': 'egreso',
            'monto': 1500.0,
            'concepto': 'Inventario inicial',
            'categoria': 'Compra de Inventario',
            'metodoPago': 'banco',
            'fecha': now.subtract(const Duration(days: 32)),
          },
        ];
        break;
        
      case 'electrodomesticos':
        sampleTransactions = [
          // Transacciones de hoy
          {
            'tipo': 'ingreso',
            'monto': 850.0,
            'concepto': 'Venta refrigeradora LG',
            'categoria': 'Venta de Productos',
            'metodoPago': 'tarjeta',
            'cliente': 'Familia Jiménez',
            'fecha': now,
          },
          {
            'tipo': 'ingreso',
            'monto': 120.0,
            'concepto': 'Reparación microondas',
            'categoria': 'Servicios Técnicos',
            'metodoPago': 'efectivo',
            'cliente': 'Luis Herrera',
            'fecha': now,
          },
          // Transacciones de ayer
          {
            'tipo': 'egreso',
            'monto': 600.0,
            'concepto': 'Compra lavadoras',
            'categoria': 'Compra de Inventario',
            'metodoPago': 'banco',
            'fecha': now.subtract(const Duration(days: 1)),
          },
          {
            'tipo': 'ingreso',
            'monto': 450.0,
            'concepto': 'Venta televisor Samsung',
            'categoria': 'Venta de Productos',
            'metodoPago': 'banco',
            'cliente': 'Casa Martínez',
            'fecha': now.subtract(const Duration(days: 1)),
          },
          // Transacciones de hace una semana
          {
            'tipo': 'egreso',
            'monto': 280.0,
            'concepto': 'Compra licuadoras',
            'categoria': 'Compra de Inventario',
            'metodoPago': 'efectivo',
            'fecha': now.subtract(const Duration(days: 7)),
          },
          {
            'tipo': 'ingreso',
            'monto': 95.0,
            'concepto': 'Instalación aire acondicionado',
            'categoria': 'Servicios Técnicos',
            'metodoPago': 'tarjeta',
            'cliente': 'Oficina Central',
            'fecha': now.subtract(const Duration(days: 9)),
          },
          // Transacciones del mes pasado
          {
            'tipo': 'egreso',
            'monto': 2200.0,
            'concepto': 'Inventario mensual',
            'categoria': 'Compra de Inventario',
            'metodoPago': 'banco',
            'fecha': now.subtract(const Duration(days: 31)),
          },
        ];
        break;
        
      default:
        sampleTransactions = [
          // Transacciones de hoy
          {
            'tipo': 'ingreso',
            'monto': 150.0,
            'concepto': 'Venta de producto',
            'categoria': 'Ventas',
            'metodoPago': 'efectivo',
            'fecha': now,
          },
          {
            'tipo': 'ingreso',
            'monto': 300.0,
            'concepto': 'Servicio técnico',
            'categoria': 'Servicios',
            'metodoPago': 'tarjeta',
            'cliente': 'Juan Pérez',
            'fecha': now,
          },
          // Transacciones de ayer
          {
            'tipo': 'egreso',
            'monto': 75.0,
            'concepto': 'Compra de insumos',
            'categoria': 'Compras',
            'metodoPago': 'banco',
            'fecha': now.subtract(const Duration(days: 1)),
          },
          {
            'tipo': 'ingreso',
            'monto': 200.0,
            'concepto': 'Consultoría',
            'categoria': 'Servicios',
            'metodoPago': 'banco',
            'cliente': 'Empresa ABC',
            'fecha': now.subtract(const Duration(days: 1)),
          },
          // Transacciones de la semana pasada
          {
            'tipo': 'egreso',
            'monto': 120.0,
            'concepto': 'Material oficina',
            'categoria': 'Gastos Operativos',
            'metodoPago': 'efectivo',
            'fecha': now.subtract(const Duration(days: 8)),
          },
          // Transacciones del mes pasado
          {
            'tipo': 'egreso',
            'monto': 500.0,
            'concepto': 'Inversión inicial',
            'categoria': 'Inversiones',
            'metodoPago': 'banco',
            'fecha': now.subtract(const Duration(days: 30)),
          },
        ];
    }

    for (final sample in sampleTransactions) {
      await createTransaction(
        tipo: sample['tipo'] as String,
        monto: sample['monto'] as double,
        concepto: sample['concepto'] as String,
        categoria: sample['categoria'] as String,
        metodoPago: sample['metodoPago'] as String,
        cliente: sample['cliente'] as String?,
        fecha: sample['fecha'] as DateTime,
        negocioId: businessId,
      );
    }
  }

  /// Obtener historial de auditoría de una transacción
  Future<List<TransactionAuditModel>> getTransactionHistory(int transactionId) async {
    return await _auditService.getTransactionHistory(transactionId);
  }

  /// Obtener estadísticas de auditoría
  Future<Map<String, dynamic>> getAuditStats(int businessId) async {
    final businessTransactions = await getTransactionsByBusiness(businessId);
    return await _auditService.getAuditStats(businessId, businessTransactions);
  }

  /// Verificar si una transacción ha sido modificada
  Future<bool> hasBeenModified(int transactionId) async {
    return await _auditService.hasBeenModified(transactionId);
  }

  /// Restaurar transacción eliminada
  Future<void> restoreTransaction(
    TransactionModel transaction,
    int userId, {
    String? userFullName,
  }) async {
    // Restaurar de la lista de eliminadas
    _deletedTransactions.removeWhere((t) => t.id == transaction.id);
    
    // Agregar de vuelta a transacciones activas
    _transactions.add(transaction);
    
    // Registrar en auditoría
    await _auditService.logRestored(
      transaction,
      userId,
      userFullName: userFullName,
    );
  }

  /// Limpiar todas las transacciones (para testing)
  Future<void> clearAllTransactions() async {
    _transactions.clear();
    _deletedTransactions.clear();
    await _auditService.clearAuditHistory();
    _nextId = 1;
  }
}