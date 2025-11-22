import '../models/transaction_model.dart';
import '../models/transaction_audit_model.dart';

/// Servicio para auditoría de transacciones
class TransactionAuditService {
  static final TransactionAuditService _instance = TransactionAuditService._internal();
  factory TransactionAuditService() => _instance;
  TransactionAuditService._internal();

  // Lista en memoria para desarrollo
  final List<TransactionAuditModel> _auditLogs = [];
  int _nextId = 1;

  /// Registrar creación de transacción
  Future<void> logCreated(TransactionModel transaction, int userId, {String? userFullName}) async {
    final audit = TransactionAuditModel(
      id: _nextId++,
      transactionId: transaction.id,
      action: 'created',
      oldData: null,
      newData: transaction.toMap(),
      userId: userId,
      reason: null,
      timestamp: DateTime.now(),
      userFullName: userFullName,
    );
    
    _auditLogs.add(audit);
  }

  /// Registrar actualización de transacción
  Future<void> logUpdated(
    TransactionModel oldTransaction, 
    TransactionModel newTransaction, 
    int userId, 
    String reason,
    {String? userFullName}
  ) async {
    final audit = TransactionAuditModel(
      id: _nextId++,
      transactionId: newTransaction.id,
      action: 'updated',
      oldData: oldTransaction.toMap(),
      newData: newTransaction.toMap(),
      userId: userId,
      reason: reason,
      timestamp: DateTime.now(),
      userFullName: userFullName,
    );
    
    _auditLogs.add(audit);
  }

  /// Registrar eliminación de transacción
  Future<void> logDeleted(TransactionModel transaction, int userId, String reason, {String? userFullName}) async {
    final audit = TransactionAuditModel(
      id: _nextId++,
      transactionId: transaction.id,
      action: 'deleted',
      oldData: transaction.toMap(),
      newData: {
        'deleted_at': DateTime.now().toIso8601String(),
        'deleted_by': userId,
        'reason': reason,
      },
      userId: userId,
      reason: reason,
      timestamp: DateTime.now(),
      userFullName: userFullName,
    );
    
    _auditLogs.add(audit);
  }

  /// Registrar restauración de transacción
  Future<void> logRestored(TransactionModel transaction, int userId, {String? userFullName}) async {
    final audit = TransactionAuditModel(
      id: _nextId++,
      transactionId: transaction.id,
      action: 'restored',
      oldData: {
        'status': 'deleted',
      },
      newData: transaction.toMap(),
      userId: userId,
      reason: 'Transacción restaurada',
      timestamp: DateTime.now(),
      userFullName: userFullName,
    );
    
    _auditLogs.add(audit);
  }

  /// Obtener historial de una transacción específica
  Future<List<TransactionAuditModel>> getTransactionHistory(int transactionId) async {
    return _auditLogs
        .where((audit) => audit.transactionId == transactionId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Más reciente primero
  }

  /// Obtener historial completo de un negocio
  Future<List<TransactionAuditModel>> getBusinessAuditHistory(
    int businessId, 
    List<TransactionModel> businessTransactions
  ) async {
    final businessTransactionIds = businessTransactions.map((t) => t.id).toSet();
    
    return _auditLogs
        .where((audit) => businessTransactionIds.contains(audit.transactionId))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Obtener historial filtrado por fecha
  Future<List<TransactionAuditModel>> getAuditByDateRange(
    int businessId,
    List<TransactionModel> businessTransactions,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final businessHistory = await getBusinessAuditHistory(businessId, businessTransactions);
    
    return businessHistory.where((audit) {
      return audit.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
             audit.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Obtener historial por usuario
  Future<List<TransactionAuditModel>> getAuditByUser(
    int businessId,
    List<TransactionModel> businessTransactions,
    int userId,
  ) async {
    final businessHistory = await getBusinessAuditHistory(businessId, businessTransactions);
    return businessHistory.where((audit) => audit.userId == userId).toList();
  }

  /// Obtener historial por tipo de acción
  Future<List<TransactionAuditModel>> getAuditByAction(
    int businessId,
    List<TransactionModel> businessTransactions,
    String action,
  ) async {
    final businessHistory = await getBusinessAuditHistory(businessId, businessTransactions);
    return businessHistory.where((audit) => audit.action == action).toList();
  }

  /// Obtener estadísticas de auditoría
  Future<Map<String, dynamic>> getAuditStats(
    int businessId,
    List<TransactionModel> businessTransactions,
  ) async {
    final history = await getBusinessAuditHistory(businessId, businessTransactions);
    
    final stats = <String, dynamic>{
      'total_changes': history.length,
      'created': history.where((h) => h.action == 'created').length,
      'updated': history.where((h) => h.action == 'updated').length,
      'deleted': history.where((h) => h.action == 'deleted').length,
      'restored': history.where((h) => h.action == 'restored').length,
    };
    
    // Usuarios más activos
    final userActivity = <int, int>{};
    for (final audit in history) {
      userActivity[audit.userId] = (userActivity[audit.userId] ?? 0) + 1;
    }
    
    final mostActiveUsers = userActivity.entries
        .map((entry) => {'user_id': entry.key, 'changes': entry.value})
        .toList()
      ..sort((a, b) => (b['changes'] as int).compareTo(a['changes'] as int));
    
    stats['most_active_users'] = mostActiveUsers;
    
    return stats;
  }

  /// Verificar si una transacción ha sido modificada
  Future<bool> hasBeenModified(int transactionId) async {
    final history = await getTransactionHistory(transactionId);
    return history.any((audit) => audit.action == 'updated');
  }

  /// Verificar si una transacción ha sido eliminada
  Future<bool> hasBeenDeleted(int transactionId) async {
    final history = await getTransactionHistory(transactionId);
    return history.any((audit) => audit.action == 'deleted') &&
           !history.any((audit) => audit.action == 'restored');
  }

  /// Obtener el último cambio de una transacción
  Future<TransactionAuditModel?> getLastChange(int transactionId) async {
    final history = await getTransactionHistory(transactionId);
    return history.isNotEmpty ? history.first : null;
  }

  /// Comparar dos versiones de una transacción
  Map<String, Map<String, dynamic>> compareTransactions(
    TransactionModel oldTransaction,
    TransactionModel newTransaction,
  ) {
    final changes = <String, Map<String, dynamic>>{};
    final oldData = oldTransaction.toMap();
    final newData = newTransaction.toMap();
    
    newData.forEach((key, newValue) {
      final oldValue = oldData[key];
      if (oldValue != newValue) {
        changes[key] = {
          'old': oldValue,
          'new': newValue,
          'field_name': _getFieldDisplayName(key),
        };
      }
    });
    
    return changes;
  }

  /// Obtener nombre amigable del campo
  String _getFieldDisplayName(String fieldName) {
    switch (fieldName) {
      case 'monto':
        return 'Monto';
      case 'tipo':
        return 'Tipo';
      case 'concepto':
        return 'Concepto';
      case 'categoria':
        return 'Categoría';
      case 'metodoPago':
        return 'Método de Pago';
      case 'cliente':
        return 'Cliente';
      case 'fecha':
        return 'Fecha';
      case 'observaciones':
        return 'Observaciones';
      default:
        return fieldName;
    }
  }

  /// Limpiar historial de auditoría (para testing)
  Future<void> clearAuditHistory() async {
    _auditLogs.clear();
    _nextId = 1;
  }
}