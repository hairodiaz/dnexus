import '../models/cash_register_model.dart';
import '../models/user_model.dart';
import '../models/invoice_model.dart';
import 'invoice_service.dart';

/// Servicio para manejar las operaciones de caja registradora
class CashRegisterService {
  static final List<CashRegisterModel> _cashRegisters = [];
  static int _nextId = 1;

  /// Obtiene todas las cajas registradoras
  static List<CashRegisterModel> getAllCashRegisters() {
    return List.from(_cashRegisters);
  }

  /// Obtiene las cajas registradoras por negocio
  static List<CashRegisterModel> getCashRegistersByBusiness(int businessId) {
    return _cashRegisters.where((register) => register.businessId == businessId).toList();
  }

  /// Obtiene la caja abierta actual para un usuario
  static CashRegisterModel? getCurrentOpenCashRegister(int userId) {
    try {
      return _cashRegisters.firstWhere(
        (register) => register.userId == userId && register.isOpen
      );
    } catch (e) {
      return null;
    }
  }

  /// Verifica si un usuario tiene una caja abierta
  static bool hasOpenCashRegister(int userId) {
    return getCurrentOpenCashRegister(userId) != null;
  }

  /// Abre una nueva caja registradora
  static CashRegisterModel openCashRegister({
    required int businessId,
    required UserModel user,
    required double initialAmount,
    String? notes,
  }) {
    // Verificar si ya tiene una caja abierta
    if (hasOpenCashRegister(user.id)) {
      throw Exception('Ya tienes una caja abierta. Debes cerrarla antes de abrir una nueva.');
    }

    // Verificar que el monto inicial sea válido
    if (initialAmount < 0) {
      throw Exception('El monto inicial no puede ser negativo.');
    }

    final cashRegister = CashRegisterModel.create(
      businessId: businessId,
      userId: user.id,
      userName: user.fullName ?? user.username,
      initialAmount: initialAmount,
      notes: notes,
    );

    _cashRegisters.add(cashRegister);
    return cashRegister;
  }

  /// Cierra una caja registradora
  static CashRegisterModel closeCashRegister({
    required int cashRegisterId,
    required double finalAmount,
    String? notes,
  }) {
    final index = _cashRegisters.indexWhere((register) => register.id == cashRegisterId);
    
    if (index == -1) {
      throw Exception('Caja registradora no encontrada.');
    }

    final cashRegister = _cashRegisters[index];

    if (cashRegister.isClosed) {
      throw Exception('La caja ya está cerrada.');
    }

    // Calcular ventas totales desde las facturas pagadas
    final totalSales = _calculateTotalSales(cashRegister);
    final transactionCount = _calculateTransactionCount(cashRegister);
    
    final expectedAmount = cashRegister.initialAmount + totalSales;
    final difference = finalAmount - expectedAmount;

    final closedRegister = cashRegister.copyWith(
      closedAt: DateTime.now(),
      finalAmount: finalAmount,
      expectedAmount: expectedAmount,
      difference: difference,
      status: CashRegisterStatus.closed,
      notes: notes,
      totalSales: totalSales,
      transactionCount: transactionCount,
      updatedAt: DateTime.now(),
    );

    _cashRegisters[index] = closedRegister;
    return closedRegister;
  }

  /// Actualiza las estadísticas de una caja abierta con las ventas del día
  static CashRegisterModel updateCashRegisterStats(int cashRegisterId) {
    final index = _cashRegisters.indexWhere((register) => register.id == cashRegisterId);
    
    if (index == -1) {
      throw Exception('Caja registradora no encontrada.');
    }

    final cashRegister = _cashRegisters[index];

    if (cashRegister.isClosed) {
      return cashRegister; // No actualizar si ya está cerrada
    }

    final totalSales = _calculateTotalSales(cashRegister);
    final transactionCount = _calculateTransactionCount(cashRegister);

    final updatedRegister = cashRegister.copyWith(
      totalSales: totalSales,
      transactionCount: transactionCount,
      updatedAt: DateTime.now(),
    );

    _cashRegisters[index] = updatedRegister;
    return updatedRegister;
  }

  /// Calcula el total de ventas para una caja específica
  static double _calculateTotalSales(CashRegisterModel cashRegister) {
    final startDate = cashRegister.openedAt;
    final endDate = cashRegister.closedAt ?? DateTime.now();

    final paidInvoices = InvoiceService.getAllInvoices()
        .where((invoice) =>
            invoice.status == InvoiceStatus.paid &&
            invoice.paidAt != null &&
            invoice.paidAt!.isAfter(startDate) &&
            invoice.paidAt!.isBefore(endDate.add(const Duration(seconds: 1))))
        .toList();

    return paidInvoices.fold(0.0, (sum, invoice) => sum + invoice.total);
  }

  /// Calcula el número de transacciones para una caja específica
  static int _calculateTransactionCount(CashRegisterModel cashRegister) {
    final startDate = cashRegister.openedAt;
    final endDate = cashRegister.closedAt ?? DateTime.now();

    return InvoiceService.getAllInvoices()
        .where((invoice) =>
            invoice.status == InvoiceStatus.paid &&
            invoice.paidAt != null &&
            invoice.paidAt!.isAfter(startDate) &&
            invoice.paidAt!.isBefore(endDate.add(const Duration(seconds: 1))))
        .length;
  }

  /// Obtiene la caja abierta de un usuario (si existe)
  static CashRegisterModel? getOpenCashRegister(int userId) {
    try {
      return _cashRegisters.firstWhere((register) => 
        register.userId == userId && register.isOpen);
    } catch (e) {
      return null;
    }
  }

  /// Verifica si un usuario puede cobrar facturas (tiene caja abierta)
  static bool canProcessPayments(int userId) {
    return hasOpenCashRegister(userId);
  }

  /// Obtiene el historial de cajas registradoras por usuario
  static List<CashRegisterModel> getCashRegisterHistory(int userId) {
    return _cashRegisters
        .where((register) => register.userId == userId)
        .toList()
        ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
  }

  /// Obtiene estadísticas de cajas registradoras por periodo
  static Map<String, dynamic> getCashRegisterStats({
    required int businessId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    final registers = _cashRegisters
        .where((register) =>
            register.businessId == businessId &&
            register.openedAt.isAfter(startDate!) &&
            register.openedAt.isBefore(endDate!.add(const Duration(days: 1))))
        .toList();

    final closedRegisters = registers.where((r) => r.isClosed).toList();

    double totalSales = 0.0;
    int totalTransactions = 0;
    double totalDifferences = 0.0;
    int registersWithDifferences = 0;

    for (final register in closedRegisters) {
      totalSales += register.totalSales;
      totalTransactions += register.transactionCount;
      
      if (register.hasDifference) {
        totalDifferences += register.difference!.abs();
        registersWithDifferences++;
      }
    }

    return {
      'total_registers': registers.length,
      'closed_registers': closedRegisters.length,
      'open_registers': registers.length - closedRegisters.length,
      'total_sales': totalSales,
      'total_transactions': totalTransactions,
      'average_sales_per_register': closedRegisters.isEmpty 
          ? 0.0 
          : totalSales / closedRegisters.length,
      'total_differences': totalDifferences,
      'registers_with_differences': registersWithDifferences,
      'accuracy_percentage': closedRegisters.isEmpty 
          ? 100.0 
          : ((closedRegisters.length - registersWithDifferences) / closedRegisters.length) * 100,
    };
  }

  /// Elimina una caja registradora (solo para pruebas)
  static bool deleteCashRegister(int cashRegisterId) {
    final index = _cashRegisters.indexWhere((register) => register.id == cashRegisterId);
    
    if (index == -1) {
      return false;
    }

    _cashRegisters.removeAt(index);
    return true;
  }

  /// Obtiene una caja registradora por ID
  static CashRegisterModel? getCashRegisterById(int cashRegisterId) {
    try {
      return _cashRegisters.firstWhere((register) => register.id == cashRegisterId);
    } catch (e) {
      return null;
    }
  }

  /// Limpia todas las cajas registradoras (solo para pruebas)
  static void clearAllCashRegisters() {
    _cashRegisters.clear();
    _nextId = 1;
  }

  /// Inicializa el servicio con datos de ejemplo
  static void initializeWithSampleData() {
    if (_cashRegisters.isEmpty) {
      // Caja cerrada de ejemplo (ayer)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final closedRegister = CashRegisterModel(
        id: _nextId++,
        businessId: 1,
        userId: 5, // Usuario caja
        userName: 'María Fernández',
        openedAt: yesterday.copyWith(hour: 8, minute: 0),
        closedAt: yesterday.copyWith(hour: 18, minute: 30),
        initialAmount: 5000.0,
        finalAmount: 27500.0,
        expectedAmount: 27000.0,
        difference: 500.0, // Sobrante
        status: CashRegisterStatus.closed,
        notes: 'Jornada normal, pequeño sobrante por redondeos',
        totalSales: 22000.0,
        transactionCount: 15,
        createdAt: yesterday.copyWith(hour: 8, minute: 0),
        updatedAt: yesterday.copyWith(hour: 18, minute: 30),
      );

      _cashRegisters.add(closedRegister);
    }
  }
}