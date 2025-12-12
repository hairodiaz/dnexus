import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/services/consolidated_reports_service.dart';
import '../../../shared/enums/transaction_filter_enum.dart';

/// Página de reportes consolidados para Super Administrador
class ConsolidatedReportsPage extends StatefulWidget {
  final UserModel user;

  const ConsolidatedReportsPage({
    super.key,
    required this.user,
  });

  @override
  State<ConsolidatedReportsPage> createState() => _ConsolidatedReportsPageState();
}

class _ConsolidatedReportsPageState extends State<ConsolidatedReportsPage> {
  final ConsolidatedReportsService _reportsService = ConsolidatedReportsService();
  
  Map<String, dynamic>? _consolidatedReport;
  Map<String, dynamic>? _executiveSummary;
  List<Map<String, dynamic>>? _businessComparison;
  Map<String, dynamic>? _trends;
  
  TransactionPeriodFilter _selectedPeriod = TransactionPeriodFilter.today;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllReports();
  }

  Future<void> _loadAllReports() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _reportsService.getConsolidatedReport(periodFilter: _selectedPeriod),
        _reportsService.getExecutiveSummary(periodFilter: _selectedPeriod),
        _reportsService.getBusinessComparison(periodFilter: _selectedPeriod),
        _reportsService.getTrends(),
      ]);

      setState(() {
        _consolidatedReport = results[0] as Map<String, dynamic>;
        _executiveSummary = results[1] as Map<String, dynamic>;
        _businessComparison = results[2] as List<Map<String, dynamic>>;
        _trends = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar reportes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Reportes Consolidados'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllReports,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildExecutiveSummary(),
                    const SizedBox(height: 20),
                    _buildConsolidatedMetrics(),
                    const SizedBox(height: 20),
                    _buildBusinessComparison(),
                    const SizedBox(height: 20),
                    _buildTrendsAnalysis(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Selector de período
  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Período de Análisis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: TransactionPeriodFilter.values.map((period) {
                final isSelected = _selectedPeriod == period;
                return FilterChip(
                  label: Text('${period.icon} ${period.displayName}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPeriod = period;
                      });
                      _loadAllReports();
                    }
                  },
                  selectedColor: Colors.purple[100],
                  checkmarkColor: Colors.purple[700],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Resumen ejecutivo
  Widget _buildExecutiveSummary() {
    if (_executiveSummary == null) return const SizedBox();

    final summary = _executiveSummary!;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.purple[700]!, Colors.purple[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.dashboard, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Resumen Ejecutivo',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isMobile ? 2 : 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isMobile ? 1.2 : 1.0,
                children: [
                  _buildSummaryMetric(
                    '💰 Ingresos Totales',
                    '\$${(summary['totalIngresos'] as double).toStringAsFixed(2)}',
                    Colors.green[300]!,
                  ),
                  _buildSummaryMetric(
                    '💸 Egresos Totales',
                    '\$${(summary['totalEgresos'] as double).toStringAsFixed(2)}',
                    Colors.red[300]!,
                  ),
                  _buildSummaryMetric(
                    '📈 Ganancia Neta',
                    '\$${(summary['gananciaNeta'] as double).toStringAsFixed(2)}',
                    Colors.blue[300]!,
                  ),
                  _buildSummaryMetric(
                    '🏢 Negocios Activos',
                    '${summary['cantidadNegocios']}',
                    Colors.orange[300]!,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mejor negocio: ${summary['mejorNegocio']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Métrica individual del resumen
  Widget _buildSummaryMetric(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Métricas consolidadas detalladas
  Widget _buildConsolidatedMetrics() {
    if (_consolidatedReport == null) return const SizedBox();

    final report = _consolidatedReport!;
    final businessReports = report['reportesPorNegocio'] as List<Map<String, dynamic>>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Desglose por Negocio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...businessReports.map((businessReport) {
              final business = businessReport['negocio'] as BusinessModel;
              return _buildBusinessCard(businessReport, business);
            }),
          ],
        ),
      ),
    );
  }

  /// Card individual de cada negocio
  Widget _buildBusinessCard(Map<String, dynamic> report, BusinessModel business) {
    final ingresos = report['ingresos'] as double;
    final egresos = report['egresos'] as double;
    final balance = report['balance'] as double;
    final transacciones = report['cantidadTransacciones'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            width: 4,
            color: _getBusinessColor(business.tipo),
          ),
        ),
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  business.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBusinessColor(business.tipo).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$transacciones transacciones',
                    style: TextStyle(
                      color: _getBusinessColor(business.tipo),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn(
                    'Ingresos',
                    '\$${ingresos.toStringAsFixed(2)}',
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildMetricColumn(
                    'Egresos',
                    '\$${egresos.toStringAsFixed(2)}',
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
                Expanded(
                  child: _buildMetricColumn(
                    'Balance',
                    '\$${balance.toStringAsFixed(2)}',
                    balance >= 0 ? Colors.blue : Colors.red,
                    balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Columna de métrica
  Widget _buildMetricColumn(String title, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Comparación entre negocios
  Widget _buildBusinessComparison() {
    if (_businessComparison == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏆 Ranking de Negocios',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._businessComparison!.asMap().entries.map((entry) {
              final index = entry.key;
              final business = entry.value;
              return _buildRankingItem(business, index);
            }),
          ],
        ),
      ),
    );
  }

  /// Item individual del ranking
  Widget _buildRankingItem(Map<String, dynamic> business, int index) {
    final ranking = business['ranking'] as int;
    final medalColor = ranking == 1 ? Colors.amber : 
                     ranking == 2 ? Colors.grey[400] : 
                     ranking == 3 ? Colors.brown[300] : Colors.grey[300];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ranking <= 3 ? medalColor?.withOpacity(0.1) : null,
        border: Border.all(
          color: ranking <= 3 ? medalColor! : Colors.grey[300]!,
          width: ranking == 1 ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: medalColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$ranking',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business['nombre'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Ingresos: \$${(business['ingresos'] as double).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(business['margenBruto'] as double).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'Margen',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Análisis de tendencias
  Widget _buildTrendsAnalysis() {
    if (_trends == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📈 Análisis de Tendencias',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Comparación temporal de ingresos consolidados',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            _buildTrendRow('Hoy', _trends!['hoy']['ingresos'], Colors.blue),
            _buildTrendRow('Esta Semana', _trends!['semana']['ingresos'], Colors.green),
            _buildTrendRow('Este Mes', _trends!['mes']['ingresos'], Colors.orange),
          ],
        ),
      ),
    );
  }

  /// Fila de tendencia
  Widget _buildTrendRow(String period, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              period,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtener color por tipo de negocio
  Color _getBusinessColor(String tipo) {
    switch (tipo) {
      case 'repuestos':
        return Colors.blue[700]!;
      case 'electrodomesticos':
        return Colors.green[700]!;
      case 'prestamos':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}