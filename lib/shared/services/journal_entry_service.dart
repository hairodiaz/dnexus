import '../models/journal_entry_model.dart';
import '../models/chart_of_accounts_model.dart';
import 'chart_of_accounts_service.dart';

/// Servicio para gestionar los Asientos Contables
class JournalEntryService {
  // Lista estática para simular base de datos
  static List<JournalEntryModel> _journalEntries = [];
  static List<JournalEntryDetailModel> _journalEntryDetails = [];
  static int _nextJournalId = 1;
  static int _nextDetailId = 1;

  /// Obtiene todos los asientos de un negocio
  static Future<List<JournalEntryModel>> getJournalEntriesByBusiness(
    int businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(Duration.zero); // Simular async
    
    var entries = _journalEntries.where((entry) => entry.businessId == businessId);
    
    if (startDate != null) {
      entries = entries.where((entry) => entry.fecha.isAfter(startDate.subtract(Duration(days: 1))));
    }
    
    if (endDate != null) {
      entries = entries.where((entry) => entry.fecha.isBefore(endDate.add(Duration(days: 1))));
    }
    
    return entries.toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  /// Obtiene un asiento por ID con sus detalles
  static Future<JournalEntryModel?> getJournalEntryById(int id) async {
    await Future.delayed(Duration.zero);
    
    try {
      final entry = _journalEntries.firstWhere((e) => e.id == id);
      final details = _journalEntryDetails.where((d) => d.journalEntryId == id).toList();
      
      return entry.copyWith(detalles: details);
    } catch (e) {
      return null;
    }
  }

  /// Crea un nuevo asiento contable
  static Future<int> createJournalEntry({
    required int businessId,
    required String concepto,
    required DateTime fecha,
    required List<JournalEntryDetailModel> detalles,
    String? referencia,
    required int creadoPorUserId,
  }) async {
    await Future.delayed(Duration.zero);
    
    // Validar que el asiento esté balanceado
    double totalDebe = detalles.fold(0.0, (sum, detail) => sum + detail.debe);
    double totalHaber = detalles.fold(0.0, (sum, detail) => sum + detail.haber);
    
    if (totalDebe != totalHaber) {
      throw Exception('El asiento no está balanceado: Debe = $totalDebe, Haber = $totalHaber');
    }
    
    if (detalles.isEmpty) {
      throw Exception('El asiento debe tener al menos un detalle');
    }
    
    // Validar que las cuentas existan y acepten movimiento
    for (var detail in detalles) {
      final accounts = await ChartOfAccountsService.getAccountsByBusiness(businessId);
      final account = accounts.firstWhere(
        (a) => a.id == detail.chartOfAccountsId,
        orElse: () => throw Exception('Cuenta con ID ${detail.chartOfAccountsId} no encontrada'),
      );
      
      if (!account.aceptaMovimiento) {
        throw Exception('La cuenta ${account.fullName} no acepta movimientos');
      }
    }
    
    // Generar número de asiento
    final numero = await _getNextJournalNumber(businessId);
    
    // Crear el asiento
    final journalEntry = JournalEntryModel(
      id: _nextJournalId++,
      businessId: businessId,
      numero: numero,
      concepto: concepto,
      fecha: fecha,
      estado: 'BORRADOR',
      referencia: referencia,
      totalDebe: totalDebe,
      totalHaber: totalHaber,
      creadoPorUserId: creadoPorUserId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _journalEntries.add(journalEntry);
    
    // Crear los detalles
    for (var detail in detalles) {
      final journalDetail = detail.copyWith(
        id: _nextDetailId++,
        journalEntryId: journalEntry.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _journalEntryDetails.add(journalDetail);
    }
    
    return journalEntry.id;
  }

  /// Contabiliza un asiento (cambia el estado a CONTABILIZADO)
  static Future<void> postJournalEntry(int journalEntryId) async {
    await Future.delayed(Duration.zero);
    
    final index = _journalEntries.indexWhere((e) => e.id == journalEntryId);
    if (index == -1) {
      throw Exception('Asiento no encontrado');
    }
    
    final entry = _journalEntries[index];
    if (entry.estado != 'BORRADOR') {
      throw Exception('Solo se pueden contabilizar asientos en estado BORRADOR');
    }
    
    _journalEntries[index] = entry.copyWith(
      estado: 'CONTABILIZADO',
      updatedAt: DateTime.now(),
    );
    
    // Aquí se actualizaría el libro mayor
    await _updateGeneralLedger(journalEntryId);
  }

  /// Anula un asiento
  static Future<void> voidJournalEntry(int journalEntryId) async {
    await Future.delayed(Duration.zero);
    
    final index = _journalEntries.indexWhere((e) => e.id == journalEntryId);
    if (index == -1) {
      throw Exception('Asiento no encontrado');
    }
    
    final entry = _journalEntries[index];
    if (entry.estado == 'ANULADO') {
      throw Exception('El asiento ya está anulado');
    }
    
    _journalEntries[index] = entry.copyWith(
      estado: 'ANULADO',
      updatedAt: DateTime.now(),
    );
  }

  /// Obtiene los detalles de un asiento
  static Future<List<JournalEntryDetailModel>> getJournalEntryDetails(int journalEntryId) async {
    await Future.delayed(Duration.zero);
    return _journalEntryDetails.where((d) => d.journalEntryId == journalEntryId).toList();
  }

  /// Genera el siguiente número de asiento para un negocio
  static Future<String> _getNextJournalNumber(int businessId) async {
    final currentYear = DateTime.now().year;
    final existingEntries = _journalEntries
        .where((e) => 
          e.businessId == businessId && 
          e.fecha.year == currentYear
        )
        .length;
    
    return '${currentYear.toString().substring(2)}-${(existingEntries + 1).toString().padLeft(4, '0')}';
  }

  /// Actualiza el libro mayor (implementación básica)
  static Future<void> _updateGeneralLedger(int journalEntryId) async {
    // Esta función se implementará cuando creemos el servicio del libro mayor
    // Por ahora solo simula la operación
    await Future.delayed(Duration.zero);
  }

  /// Obtiene estadísticas de asientos por negocio
  static Future<Map<String, dynamic>> getJournalEntryStats(int businessId) async {
    await Future.delayed(Duration.zero);
    
    final entries = _journalEntries.where((e) => e.businessId == businessId).toList();
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    
    final thisMonthEntries = entries.where((e) => 
      e.fecha.month == currentMonth && e.fecha.year == currentYear
    ).toList();
    
    return {
      'totalEntries': entries.length,
      'thisMonthEntries': thisMonthEntries.length,
      'draftEntries': entries.where((e) => e.estado == 'BORRADOR').length,
      'postedEntries': entries.where((e) => e.estado == 'CONTABILIZADO').length,
      'voidedEntries': entries.where((e) => e.estado == 'ANULADO').length,
      'thisMonthTotal': thisMonthEntries.fold(0.0, (sum, e) => sum + e.totalDebe),
    };
  }

  /// Limpia todos los datos (para testing)
  static void clearAll() {
    _journalEntries.clear();
    _journalEntryDetails.clear();
    _nextJournalId = 1;
    _nextDetailId = 1;
  }
}