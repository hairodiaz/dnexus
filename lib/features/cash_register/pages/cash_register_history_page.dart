import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/cash_register_model.dart';
import '../../../shared/services/cash_register_service.dart';
import '../../../core/utils/currency_formatter.dart';

/// Página de historial de cajas registradoras
class CashRegisterHistoryPage extends StatefulWidget {
  final UserModel user;
  final int businessId;

  const CashRegisterHistoryPage({
    super.key,
    required this.user,
    required this.businessId,
  });

  @override
  State<CashRegisterHistoryPage> createState() => _CashRegisterHistoryPageState();
}

class _CashRegisterHistoryPageState extends State<CashRegisterHistoryPage> {
  List<CashRegisterModel> _cashRegisters = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      _cashRegisters = CashRegisterService.getCashRegisterHistory(widget.user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando historial: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Cajas'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cashRegisters.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cashRegisters.length,
                    itemBuilder: (context, index) {
                      final cashRegister = _cashRegisters[index];
                      return _buildCashRegisterCard(cashRegister);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.all(24),
            child: Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin historial de cajas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tienes registros de cajas abiertas anteriormente',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashRegisterCard(CashRegisterModel cashRegister) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCashRegisterDetails(cashRegister),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cashRegister.isOpen
                          ? Colors.green.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cashRegister.isOpen ? Icons.lock_open : Icons.lock,
                          color: cashRegister.isOpen ? Colors.green : Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cashRegister.status.displayName,
                          style: TextStyle(
                            color: cashRegister.isOpen ? Colors.green : Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (cashRegister.hasDifference)
                    Container(
                      decoration: BoxDecoration(
                        color: (cashRegister.difference! > 0 ? Colors.orange : Colors.red)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cashRegister.difference! > 0 
                                ? Icons.trending_up 
                                : Icons.trending_down,
                            color: cashRegister.difference! > 0 ? Colors.orange : Colors.red,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${cashRegister.difference! > 0 ? '+' : ''}${CurrencyFormatter.formatNoDecimals(cashRegister.difference!)}',
                            style: TextStyle(
                              color: cashRegister.difference! > 0 ? Colors.orange : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Date and time
              Text(
                _formatDateRange(cashRegister),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimeRange(cashRegister),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Inicial',
                      CurrencyFormatter.formatNoDecimals(cashRegister.initialAmount),
                      Icons.account_balance_wallet,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Ventas',
                      CurrencyFormatter.formatNoDecimals(cashRegister.totalSales),
                      Icons.monetization_on,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Transacciones',
                      cashRegister.transactionCount.toString(),
                      Icons.receipt,
                      Colors.orange,
                    ),
                  ),
                  if (cashRegister.isClosed)
                    Expanded(
                      child: _buildStatItem(
                        'Final',
                        CurrencyFormatter.formatNoDecimals(cashRegister.finalAmount!),
                        Icons.account_balance,
                        Colors.purple,
                      ),
                    ),
                ],
              ),

              if (cashRegister.notes != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cashRegister.notes!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDateRange(CashRegisterModel cashRegister) {
    final opened = cashRegister.openedAt;
    final closed = cashRegister.closedAt;

    if (closed == null) {
      return '${opened.day}/${opened.month}/${opened.year}';
    }

    if (opened.day == closed.day && 
        opened.month == closed.month && 
        opened.year == closed.year) {
      return '${opened.day}/${opened.month}/${opened.year}';
    }

    return '${opened.day}/${opened.month} - ${closed.day}/${closed.month}/${closed.year}';
  }

  String _formatTimeRange(CashRegisterModel cashRegister) {
    final opened = cashRegister.openedAt;
    final closed = cashRegister.closedAt;
    
    final openedTime = '${opened.hour.toString().padLeft(2, '0')}:${opened.minute.toString().padLeft(2, '0')}';
    
    if (closed == null) {
      return '$openedTime - Abierta';
    }

    final closedTime = '${closed.hour.toString().padLeft(2, '0')}:${closed.minute.toString().padLeft(2, '0')}';
    return '$openedTime - $closedTime';
  }

  void _showCashRegisterDetails(CashRegisterModel cashRegister) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _buildDetailsSheet(
          cashRegister, 
          scrollController,
        ),
      ),
    );
  }

  Widget _buildDetailsSheet(CashRegisterModel cashRegister, ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cashRegister.isOpen
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  cashRegister.isOpen ? Icons.lock_open : Icons.lock,
                  color: cashRegister.isOpen ? Colors.green : Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caja ${cashRegister.status.displayName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: ${cashRegister.id}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Details sections
          _buildDetailSection('Información General', [
            _buildDetailRow('Cajero(a)', cashRegister.userName),
            _buildDetailRow('Fecha apertura', _formatDateTime(cashRegister.openedAt)),
            if (cashRegister.closedAt != null)
              _buildDetailRow('Fecha cierre', _formatDateTime(cashRegister.closedAt!)),
            if (cashRegister.workDuration != null)
              _buildDetailRow('Duración', 
                '${cashRegister.workDuration!.inHours}h ${cashRegister.workDuration!.inMinutes.remainder(60)}m'),
          ]),

          const SizedBox(height: 20),

          _buildDetailSection('Montos', [
            _buildDetailRow('Monto inicial', CurrencyFormatter.formatNoDecimals(cashRegister.initialAmount)),
            _buildDetailRow('Ventas totales', CurrencyFormatter.formatNoDecimals(cashRegister.totalSales)),
            _buildDetailRow('Monto esperado', CurrencyFormatter.formatNoDecimals(cashRegister.calculatedExpectedAmount)),
            if (cashRegister.finalAmount != null)
              _buildDetailRow('Monto final', CurrencyFormatter.formatNoDecimals(cashRegister.finalAmount!)),
            if (cashRegister.difference != null)
              _buildDetailRow('Diferencia', 
                '${cashRegister.difference! > 0 ? '+' : ''}${CurrencyFormatter.formatNoDecimals(cashRegister.difference!)}',
                color: cashRegister.difference! > 0 ? Colors.green : Colors.red),
          ]),

          const SizedBox(height: 20),

          _buildDetailSection('Estadísticas', [
            _buildDetailRow('Transacciones', cashRegister.transactionCount.toString()),
            if (cashRegister.transactionCount > 0)
              _buildDetailRow('Promedio por transacción', 
                CurrencyFormatter.formatNoDecimals(cashRegister.totalSales / cashRegister.transactionCount)),
          ]),

          if (cashRegister.notes != null) ...[
            const SizedBox(height: 20),
            _buildDetailSection('Notas', [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  cashRegister.notes!,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ]),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: color ?? Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}