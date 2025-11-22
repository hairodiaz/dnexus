/// Enum para filtros de período de transacciones
enum TransactionPeriodFilter {
  today,
  thisWeek,
  thisMonth,
  last30Days;

  /// Obtener el nombre para mostrar
  String get displayName {
    switch (this) {
      case TransactionPeriodFilter.today:
        return 'Hoy';
      case TransactionPeriodFilter.thisWeek:
        return 'Esta Semana';
      case TransactionPeriodFilter.thisMonth:
        return 'Este Mes';
      case TransactionPeriodFilter.last30Days:
        return 'Últimos 30 días';
    }
  }

  /// Obtener el icono para el filtro
  String get icon {
    switch (this) {
      case TransactionPeriodFilter.today:
        return '📅';
      case TransactionPeriodFilter.thisWeek:
        return '🗓️';
      case TransactionPeriodFilter.thisMonth:
        return '📊';
      case TransactionPeriodFilter.last30Days:
        return '📈';
    }
  }

  /// Calcular el rango de fechas para el filtro
  DateRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case TransactionPeriodFilter.today:
        return DateRange(
          start: today,
          end: today.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
        );

      case TransactionPeriodFilter.thisWeek:
        final weekday = today.weekday;
        final startOfWeek = today.subtract(Duration(days: weekday - 1));
        return DateRange(
          start: startOfWeek,
          end: startOfWeek.add(const Duration(days: 7)).subtract(const Duration(microseconds: 1)),
        );

      case TransactionPeriodFilter.thisMonth:
        final startOfMonth = DateTime(today.year, today.month, 1);
        final endOfMonth = DateTime(today.year, today.month + 1, 1).subtract(const Duration(microseconds: 1));
        return DateRange(
          start: startOfMonth,
          end: endOfMonth,
        );

      case TransactionPeriodFilter.last30Days:
        final start30Days = today.subtract(const Duration(days: 30));
        return DateRange(
          start: start30Days,
          end: today.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
        );
    }
  }
}

/// Enum para filtros de tipo de transacción
enum TransactionTypeFilter {
  all,
  ingreso,
  egreso;

  /// Obtener el nombre para mostrar
  String get displayName {
    switch (this) {
      case TransactionTypeFilter.all:
        return 'Todos';
      case TransactionTypeFilter.ingreso:
        return 'Ingresos';
      case TransactionTypeFilter.egreso:
        return 'Egresos';
    }
  }

  /// Obtener el icono para el filtro
  String get icon {
    switch (this) {
      case TransactionTypeFilter.all:
        return '💼';
      case TransactionTypeFilter.ingreso:
        return '💚';
      case TransactionTypeFilter.egreso:
        return '❤️';
    }
  }
}

/// Enum para filtros de método de pago
enum TransactionPaymentFilter {
  all,
  efectivo,
  banco,
  tarjeta;

  /// Obtener el nombre para mostrar
  String get displayName {
    switch (this) {
      case TransactionPaymentFilter.all:
        return 'Todos';
      case TransactionPaymentFilter.efectivo:
        return 'Efectivo';
      case TransactionPaymentFilter.banco:
        return 'Banco';
      case TransactionPaymentFilter.tarjeta:
        return 'Tarjeta';
    }
  }

  /// Obtener el icono para el filtro
  String get icon {
    switch (this) {
      case TransactionPaymentFilter.all:
        return '💳';
      case TransactionPaymentFilter.efectivo:
        return '💵';
      case TransactionPaymentFilter.banco:
        return '🏦';
      case TransactionPaymentFilter.tarjeta:
        return '💳';
    }
  }
}

/// Clase para representar un rango de fechas
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  /// Verificar si una fecha está dentro del rango
  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(microseconds: 1))) &&
           date.isBefore(end.add(const Duration(microseconds: 1)));
  }

  @override
  String toString() {
    return 'DateRange(${start.toIso8601String()} - ${end.toIso8601String()})';
  }
}