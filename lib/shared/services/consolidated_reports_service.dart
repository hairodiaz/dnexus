import '../models/business_model.dart';
import '../enums/transaction_filter_enum.dart';
import 'transaction_service.dart';
import 'business_service.dart';

/// Servicio para reportes consolidados de múltiples negocios
class ConsolidatedReportsService {
  static final ConsolidatedReportsService _instance = ConsolidatedReportsService._internal();
  factory ConsolidatedReportsService() => _instance;
  ConsolidatedReportsService._internal();

  final TransactionService _transactionService = TransactionService();

  /// Obtener reporte consolidado de todos los negocios
  Future<Map<String, dynamic>> getConsolidatedReport({
    TransactionPeriodFilter periodFilter = TransactionPeriodFilter.today,
  }) async {
    // Obtener todos los negocios
    final businesses = await BusinessService.getAllActiveBusinesses();
    
    double totalIngresos = 0;
    double totalEgresos = 0;
    int totalTransacciones = 0;
    
    List<Map<String, dynamic>> businessReports = [];

    // Procesar cada negocio individualmente
    for (final business in businesses) {
      final businessStats = await _transactionService.getFilteredTransactionStats(
        business.id,
        periodFilter: periodFilter,
        typeFilter: TransactionTypeFilter.all,
        paymentFilter: TransactionPaymentFilter.all,
      );

      final businessReport = {
        'negocio': business,
        'ingresos': businessStats['totalIngresos'] ?? 0.0,
        'egresos': businessStats['totalEgresos'] ?? 0.0,
        'balance': businessStats['balance'] ?? 0.0,
        'cantidadTransacciones': businessStats['totalTransacciones'] ?? 0,
        'cantidadIngresos': businessStats['cantidadIngresos'] ?? 0,
        'cantidadEgresos': businessStats['cantidadEgresos'] ?? 0,
      };

      businessReports.add(businessReport);
      
      // Sumar a totales consolidados
      totalIngresos += businessReport['ingresos'] as double;
      totalEgresos += businessReport['egresos'] as double;
      totalTransacciones += businessReport['cantidadTransacciones'] as int;
    }

    // Calcular métricas adicionales
    final balanceConsolidado = totalIngresos - totalEgresos;
    final mejorNegocio = businessReports.isNotEmpty 
        ? businessReports.reduce((a, b) => 
            (a['ingresos'] as double) > (b['ingresos'] as double) ? a : b)
        : null;

    return {
      // Totales consolidados
      'totalIngresos': totalIngresos,
      'totalEgresos': totalEgresos,
      'balanceConsolidado': balanceConsolidado,
      'totalTransacciones': totalTransacciones,
      'cantidadNegocios': businesses.length,
      
      // Reportes individuales por negocio
      'reportesPorNegocio': businessReports,
      
      // Análisis comparativo
      'mejorNegocioIngresos': mejorNegocio,
      'promedioIngresosPorNegocio': businesses.isNotEmpty ? totalIngresos / businesses.length : 0.0,
      'promedioEgresosPorNegocio': businesses.isNotEmpty ? totalEgresos / businesses.length : 0.0,
      
      // Distribución porcentual
      'distribucionIngresos': businessReports.map((report) => {
        'negocio': (report['negocio'] as BusinessModel).nombre,
        'tipo': (report['negocio'] as BusinessModel).tipo,
        'porcentaje': totalIngresos > 0 ? ((report['ingresos'] as double) / totalIngresos * 100) : 0.0,
        'monto': report['ingresos'],
      }).toList(),
      
      // Metadata
      'periodo': periodFilter.displayName,
      'fechaGeneracion': DateTime.now(),
    };
  }

  /// Obtener resumen ejecutivo simplificado
  Future<Map<String, dynamic>> getExecutiveSummary({
    TransactionPeriodFilter periodFilter = TransactionPeriodFilter.today,
  }) async {
    final consolidatedReport = await getConsolidatedReport(periodFilter: periodFilter);
    
    return {
      'totalIngresos': consolidatedReport['totalIngresos'],
      'totalEgresos': consolidatedReport['totalEgresos'],
      'gananciaNeta': consolidatedReport['balanceConsolidado'],
      'cantidadNegocios': consolidatedReport['cantidadNegocios'],
      'mejorNegocio': consolidatedReport['mejorNegocioIngresos']?['negocio']?.nombre ?? 'N/A',
      'periodo': consolidatedReport['periodo'],
      'rendimientoPromedio': consolidatedReport['promedioIngresosPorNegocio'],
    };
  }

  /// Comparativa entre negocios
  Future<List<Map<String, dynamic>>> getBusinessComparison({
    TransactionPeriodFilter periodFilter = TransactionPeriodFilter.today,
  }) async {
    final consolidatedReport = await getConsolidatedReport(periodFilter: periodFilter);
    final businessReports = consolidatedReport['reportesPorNegocio'] as List<Map<String, dynamic>>;
    
    // Ordenar por ingresos descendente
    businessReports.sort((a, b) => (b['ingresos'] as double).compareTo(a['ingresos'] as double));
    
    return businessReports.asMap().entries.map((entry) {
      final index = entry.key;
      final report = entry.value;
      final business = report['negocio'] as BusinessModel;
      
      return {
        'ranking': index + 1,
        'nombre': business.nombre,
        'tipo': business.tipo,
        'displayName': business.displayName,
        'ingresos': report['ingresos'],
        'egresos': report['egresos'],
        'balance': report['balance'],
        'transacciones': report['cantidadTransacciones'],
        'margenBruto': report['ingresos'] > 0 
            ? ((report['balance'] as double) / (report['ingresos'] as double) * 100) 
            : 0.0,
      };
    }).toList();
  }

  /// Obtener tendencias por período
  Future<Map<String, dynamic>> getTrends() async {
    final hoy = await getConsolidatedReport(periodFilter: TransactionPeriodFilter.today);
    final semana = await getConsolidatedReport(periodFilter: TransactionPeriodFilter.thisWeek);
    final mes = await getConsolidatedReport(periodFilter: TransactionPeriodFilter.thisMonth);
    
    return {
      'hoy': {
        'ingresos': hoy['totalIngresos'],
        'balance': hoy['balanceConsolidado'],
        'transacciones': hoy['totalTransacciones'],
      },
      'semana': {
        'ingresos': semana['totalIngresos'],
        'balance': semana['balanceConsolidado'],
        'transacciones': semana['totalTransacciones'],
      },
      'mes': {
        'ingresos': mes['totalIngresos'],
        'balance': mes['balanceConsolidado'],
        'transacciones': mes['totalTransacciones'],
      },
      'crecimiento': {
        'ingresosSemanalVsHoy': hoy['totalIngresos'] > 0 
            ? ((semana['totalIngresos'] as double) / (hoy['totalIngresos'] as double) - 1) * 100
            : 0.0,
        'ingresosMensualVsSemanal': semana['totalIngresos'] > 0 
            ? ((mes['totalIngresos'] as double) / (semana['totalIngresos'] as double) - 1) * 100
            : 0.0,
      }
    };
  }
}