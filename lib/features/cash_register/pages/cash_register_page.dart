import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_extensions.dart';
import '../../../shared/models/cash_register_model.dart';
import '../../../shared/services/cash_register_service.dart';
import '../../../core/utils/currency_formatter.dart';
import 'open_cash_register_dialog.dart';
import 'close_cash_register_dialog.dart';
import 'cash_register_history_page.dart';

/// Página principal para la gestión de caja registradora
class CashRegisterPage extends StatefulWidget {
  final UserModel user;
  final int businessId;

  const CashRegisterPage({
    super.key,
    required this.user,
    required this.businessId,
  });

  @override
  State<CashRegisterPage> createState() => _CashRegisterPageState();
}

class _CashRegisterPageState extends State<CashRegisterPage> {
  CashRegisterModel? _currentCashRegister;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentCashRegister();
  }

  Future<void> _loadCurrentCashRegister() async {
    setState(() => _isLoading = true);
    try {
      _currentCashRegister = CashRegisterService.getCurrentOpenCashRegister(widget.user.id);
      if (_currentCashRegister != null) {
        // Actualizar estadísticas si hay caja abierta
        _currentCashRegister = CashRegisterService.updateCashRegisterStats(_currentCashRegister!.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando caja: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openCashRegister() async {
    final result = await showDialog<CashRegisterModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OpenCashRegisterDialog(
        user: widget.user,
        businessId: widget.businessId,
      ),
    );

    if (result != null) {
      setState(() {
        _currentCashRegister = result;
      });
      _showSuccessMessage('Caja abierta exitosamente');
    }
  }

  Future<void> _closeCashRegister() async {
    if (_currentCashRegister == null) return;

    final result = await showDialog<CashRegisterModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CloseCashRegisterDialog(
        cashRegister: _currentCashRegister!,
      ),
    );

    if (result != null) {
      setState(() {
        _currentCashRegister = null;
      });
      _showSuccessMessage('Caja cerrada exitosamente');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CashRegisterHistoryPage(
          user: widget.user,
          businessId: widget.businessId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja Registradora'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistory,
            tooltip: 'Historial de cajas',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildUserInfoCard(),
                  const SizedBox(height: 16),
                  _buildCurrentCashRegisterCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  if (_currentCashRegister != null) ...[
                    const SizedBox(height: 16),
                    _buildStatsCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.person,
                color: Color(0xFF2196F3),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.fullName ?? widget.user.username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cajero(a) - ${widget.user.roleDisplayName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCashRegisterCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _currentCashRegister?.isOpen == true
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.point_of_sale,
                    color: _currentCashRegister?.isOpen == true
                        ? Colors.green
                        : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentCashRegister?.isOpen == true
                            ? 'Caja Abierta'
                            : 'Caja Cerrada',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentCashRegister?.isOpen == true
                            ? 'Desde: ${_formatDateTime(_currentCashRegister!.openedAt)}'
                            : 'No hay caja abierta actualmente',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_currentCashRegister != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Monto inicial',
                      CurrencyFormatter.formatNoDecimals(_currentCashRegister!.initialAmount),
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Ventas del día',
                      CurrencyFormatter.formatNoDecimals(_currentCashRegister!.totalSales),
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF2196F3),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentCashRegister == null)
              ElevatedButton.icon(
                onPressed: _openCashRegister,
                icon: const Icon(Icons.lock_open),
                label: const Text('Abrir Caja'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _closeCashRegister,
                icon: const Icon(Icons.lock),
                label: const Text('Cerrar Caja'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _navigateToHistory,
              icon: const Icon(Icons.history),
              label: const Text('Ver Historial'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_currentCashRegister == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas del día',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Transacciones',
                    _currentCashRegister!.transactionCount.toString(),
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Ventas totales',
                    CurrencyFormatter.formatNoDecimals(_currentCashRegister!.totalSales),
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'En caja (esperado)',
                    CurrencyFormatter.formatNoDecimals(_currentCashRegister!.calculatedExpectedAmount),
                    Icons.calculate,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Tiempo abierta',
                    _formatDuration(DateTime.now().difference(_currentCashRegister!.openedAt)),
                    Icons.access_time,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
            textAlign: TextAlign.center,
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}