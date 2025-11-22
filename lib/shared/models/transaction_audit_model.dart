/// Modelo para el historial de auditoría de transacciones
class TransactionAuditModel {
  final int id;
  final int transactionId;
  final String action; // 'created', 'updated', 'deleted', 'restored'
  final Map<String, dynamic>? oldData; // Datos anteriores (null para created)
  final Map<String, dynamic> newData; // Datos nuevos
  final int userId; // ID del usuario que hizo el cambio
  final String? reason; // Motivo del cambio (opcional)
  final DateTime timestamp;
  final String? userFullName; // Nombre del usuario (para display)

  const TransactionAuditModel({
    required this.id,
    required this.transactionId,
    required this.action,
    this.oldData,
    required this.newData,
    required this.userId,
    this.reason,
    required this.timestamp,
    this.userFullName,
  });

  /// Factory para crear desde Map (resultado de DB)
  factory TransactionAuditModel.fromMap(Map<String, dynamic> map) {
    return TransactionAuditModel(
      id: map['id'] as int,
      transactionId: map['transaction_id'] as int,
      action: map['action'] as String,
      oldData: map['old_data'] != null 
          ? Map<String, dynamic>.from(map['old_data']) 
          : null,
      newData: Map<String, dynamic>.from(map['new_data']),
      userId: map['user_id'] as int,
      reason: map['reason'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      userFullName: map['user_full_name'] as String?,
    );
  }

  /// Convertir a Map para base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'action': action,
      'old_data': oldData,
      'new_data': newData,
      'user_id': userId,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Crear copia con cambios
  TransactionAuditModel copyWith({
    int? id,
    int? transactionId,
    String? action,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    int? userId,
    String? reason,
    DateTime? timestamp,
    String? userFullName,
  }) {
    return TransactionAuditModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      action: action ?? this.action,
      oldData: oldData ?? this.oldData,
      newData: newData ?? this.newData,
      userId: userId ?? this.userId,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      userFullName: userFullName ?? this.userFullName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionAuditModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransactionAuditModel(id: $id, action: $action, userId: $userId, timestamp: $timestamp)';
  }

  /// Validar datos de auditoría
  bool get isValid {
    return action.isNotEmpty && 
           transactionId > 0 &&
           userId > 0 &&
           ['created', 'updated', 'deleted', 'restored'].contains(action);
  }

  /// Icono según la acción
  String get actionIcon {
    switch (action) {
      case 'created':
        return '➕';
      case 'updated':
        return '✏️';
      case 'deleted':
        return '🗑️';
      case 'restored':
        return '↩️';
      default:
        return '📝';
    }
  }

  /// Descripción de la acción
  String get actionDescription {
    switch (action) {
      case 'created':
        return 'Transacción creada';
      case 'updated':
        return 'Transacción modificada';
      case 'deleted':
        return 'Transacción eliminada';
      case 'restored':
        return 'Transacción restaurada';
      default:
        return 'Acción desconocida';
    }
  }

  /// Obtener cambios específicos entre oldData y newData
  Map<String, Map<String, dynamic>> get changes {
    if (oldData == null) return {};
    
    final Map<String, Map<String, dynamic>> changes = {};
    
    // Comparar cada campo
    newData.forEach((key, newValue) {
      final oldValue = oldData![key];
      if (oldValue != newValue) {
        changes[key] = {
          'old': oldValue,
          'new': newValue,
        };
      }
    });
    
    return changes;
  }

  /// Obtener lista de campos modificados
  List<String> get modifiedFields {
    return changes.keys.toList();
  }

  /// Verificar si hubo cambios significativos
  bool get hasSignificantChanges {
    final significantFields = ['monto', 'tipo', 'categoria', 'concepto', 'metodoPago'];
    return modifiedFields.any((field) => significantFields.contains(field));
  }

  /// Formato amigable de fecha y hora
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Hace unos segundos';
    }
  }

  /// Descripción detallada del cambio
  String get changesSummary {
    if (action == 'created') {
      return 'Transacción creada por ${userFullName ?? 'Usuario #$userId'}';
    }
    
    if (action == 'deleted') {
      final reasonText = reason != null ? ' - Motivo: $reason' : '';
      return 'Transacción eliminada por ${userFullName ?? 'Usuario #$userId'}$reasonText';
    }
    
    if (action == 'restored') {
      return 'Transacción restaurada por ${userFullName ?? 'Usuario #$userId'}';
    }
    
    if (action == 'updated') {
      final changesCount = modifiedFields.length;
      final reasonText = reason != null ? ' - Motivo: $reason' : '';
      return '$changesCount campo${changesCount == 1 ? '' : 's'} modificado${changesCount == 1 ? '' : 's'} por ${userFullName ?? 'Usuario #$userId'}$reasonText';
    }
    
    return actionDescription;
  }
}