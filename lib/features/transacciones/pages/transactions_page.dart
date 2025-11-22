import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/services/transaction_service.dart';
import '../../../shared/enums/transaction_filter_enum.dart';
import '../../../shared/widgets/transaction_filters_widget.dart';
import 'add_transaction_page.dart';
import 'edit_transaction_page.dart';

/// Página principal de transacciones
class TransactionsPage extends StatefulWidget {
  final UserModel user;
  final BusinessModel business;

  const TransactionsPage({
    super.key,
    required this.user,
    required this.business,
  });

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final TransactionService _transactionService = TransactionService();
  List<TransactionModel> _transactions = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  
  // Variables de filtro
  TransactionPeriodFilter _periodFilter = TransactionPeriodFilter.today;
  TransactionTypeFilter? _typeFilter;
  TransactionPaymentFilter? _paymentFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Inicializar datos de ejemplo si es necesario según tipo de negocio
      await _transactionService.initializeSampleData(widget.business.id, widget.business.tipo);
      
      // Cargar transacciones y estadísticas con filtros
      final transactions = await _transactionService.getFilteredTransactions(
        widget.business.id,
        periodFilter: _periodFilter,
        typeFilter: _typeFilter ?? TransactionTypeFilter.all,
        paymentFilter: _paymentFilter ?? TransactionPaymentFilter.all,
      );
      final stats = await _transactionService.getFilteredTransactionStats(
        widget.business.id,
        periodFilter: _periodFilter,
        typeFilter: _typeFilter ?? TransactionTypeFilter.all,
        paymentFilter: _paymentFilter ?? TransactionPaymentFilter.all,
      );
      
      setState(() {
        _transactions = transactions;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transacciones - ${widget.business.nombre}'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_from_trash),
            onPressed: _showDeletedTransactions,
            tooltip: 'Ver Eliminadas',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // Filtros de transacciones
                  TransactionFiltersWidget(
                    selectedPeriodFilter: _periodFilter,
                    selectedTypeFilter: _typeFilter,
                    selectedPaymentFilter: _paymentFilter,
                    onPeriodFilterChanged: (filter) {
                      setState(() {
                        _periodFilter = filter;
                      });
                      _loadData();
                    },
                    onTypeFilterChanged: (filter) {
                      setState(() {
                        _typeFilter = filter;
                      });
                      _loadData();
                    },
                    onPaymentFilterChanged: (filter) {
                      setState(() {
                        _paymentFilter = filter;
                      });
                      _loadData();
                    },
                  ),
                  
                  // Resumen de estadísticas
                  _buildStatsSection(),
                  
                  // Lista de transacciones
                  Expanded(
                    child: _buildTransactionsList(),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Sección de estadísticas
  Widget _buildStatsSection() {
    if (_stats.isEmpty) return const SizedBox.shrink();

    final totalIngresos = _stats['totalIngresos'] ?? 0.0;
    final totalEgresos = _stats['totalEgresos'] ?? 0.0;
    final balance = _stats['balance'] ?? 0.0;
    final totalTransacciones = _stats['totalTransacciones'] ?? 0;

    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      margin: EdgeInsets.fromLTRB(isMobile ? 8 : 12, 0, isMobile ? 8 : 12, isMobile ? 8 : 12),
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(_periodFilter.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resumen - ${_periodFilter.displayName}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
              if (_typeFilter != TransactionTypeFilter.all || 
                  _paymentFilter != TransactionPaymentFilter.all) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Filtrado',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: isMobile ? 10 : 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Ingresos',
                  '\$${totalIngresos.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.green,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: _buildStatCard(
                  'Egresos',
                  '\$${totalEgresos.toStringAsFixed(2)}',
                  Icons.trending_down,
                  Colors.red,
                  isMobile,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Balance',
                  '\$${balance.toStringAsFixed(2)}',
                  balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
                  balance >= 0 ? Colors.blue : Colors.orange,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: _buildStatCard(
                  'Transacciones',
                  '$totalTransacciones',
                  Icons.receipt_long,
                  Colors.purple,
                  isMobile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card individual de estadística
  Widget _buildStatCard(String title, String value, IconData icon, Color color, [bool isMobile = false]) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 18 : 20),
          SizedBox(height: isMobile ? 3 : 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isMobile ? 1 : 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de transacciones
  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _periodFilter.icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _periodFilter == TransactionPeriodFilter.today
                  ? 'Toca el botón + para agregar una transacción'
                  : 'Cambia el período o agrega nuevas transacciones',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  /// Card individual de transacción
  Widget _buildTransactionCard(TransactionModel transaction) {
    final isIngreso = transaction.tipo == 'ingreso';
    final color = isIngreso ? Colors.green : Colors.red;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isIngreso ? Icons.add_circle : Icons.remove_circle,
                    color: color,
                    size: isMobile ? 18 : 20,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              transaction.concepto,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            transaction.montoFormateado,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 2 : 4),
                      Text(
                        transaction.categoria,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (transaction.cliente != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Cliente: ${transaction.cliente}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${transaction.fecha.day}/${transaction.fecha.month}/${transaction.fecha.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Text(
                  transaction.metodoPagoDescripcion,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showTransactionHistory(transaction),
                  icon: const Icon(Icons.history, size: 14),
                  label: const Text('Historial', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _editTransaction(transaction),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Editar', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _deleteTransaction(transaction),
                  icon: const Icon(Icons.delete, size: 14),
                  label: const Text('Eliminar', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Mostrar formulario para agregar transacción
  void _showAddTransactionDialog() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(
          business: widget.business,
        ),
      ),
    );
    
    // Si se guardó exitosamente, recargar datos
    if (result == true) {
      _loadData();
    }
  }

  /// Mostrar historial de una transacción
  void _showTransactionHistory(TransactionModel transaction) async {
    try {
      final history = await _transactionService.getTransactionHistory(transaction.id);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Historial - ${transaction.concepto}'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: history.isEmpty
                  ? const Center(child: Text('No hay historial disponible'))
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final audit = history[index];
                        return ListTile(
                          leading: Text(audit.actionIcon, style: const TextStyle(fontSize: 20)),
                          title: Text(audit.actionDescription),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(audit.formattedTimestamp),
                              if (audit.reason != null) Text('Motivo: ${audit.reason}'),
                            ],
                          ),
                          isThreeLine: audit.reason != null,
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    }
  }

  /// Editar transacción
  void _editTransaction(TransactionModel transaction) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditTransactionPage(
          business: widget.business,
          transaction: transaction,
          userId: widget.user.id,
          userFullName: widget.user.fullName,
        ),
      ),
    );
    
    // Si se guardó exitosamente, recargar datos
    if (result == true) {
      _loadData();
    }
  }

  /// Eliminar transacción
  void _deleteTransaction(TransactionModel transaction) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Transacción?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se eliminará la transacción:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.concepto,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(transaction.montoFormateado),
                  Text(transaction.categoria),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo de eliminación *',
                hintText: 'Ingrese el motivo por el cual elimina esta transacción',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El motivo es obligatorio')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        await _transactionService.deleteTransaction(
          transaction.id,
          widget.user.id,
          reasonController.text.trim(),
          userFullName: widget.user.fullName,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transacción eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Recargar datos
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
    
    reasonController.dispose();
  }

  /// Obtener mensaje cuando no hay transacciones según filtros
  String _getEmptyMessage() {
    if (_typeFilter != null && _typeFilter != TransactionTypeFilter.all) {
      return 'No hay ${_typeFilter!.displayName.toLowerCase()} en ${_periodFilter.displayName.toLowerCase()}';
    }
    
    switch (_periodFilter) {
      case TransactionPeriodFilter.today:
        return 'No hay transacciones registradas hoy';
      case TransactionPeriodFilter.thisWeek:
        return 'No hay transacciones esta semana';
      case TransactionPeriodFilter.thisMonth:
        return 'No hay transacciones este mes';
      case TransactionPeriodFilter.last30Days:
        return 'No hay transacciones en los últimos 30 días';
    }
  }

  /// Mostrar transacciones eliminadas
  void _showDeletedTransactions() async {
    try {
      final deletedTransactions = await _transactionService.getDeletedTransactionsByBusiness(widget.business.id);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Container(
              width: double.maxFinite,
              height: 600,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transacciones Eliminadas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: deletedTransactions.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restore_from_trash, size: 48, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No hay transacciones eliminadas',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: deletedTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = deletedTransactions[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(transaction.concepto),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(transaction.categoria),
                                      Text(
                                        '${transaction.fecha.day}/${transaction.fecha.month}/${transaction.fecha.year}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        transaction.montoFormateado,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _restoreTransaction(transaction),
                                        icon: const Icon(Icons.restore, size: 16),
                                        label: const Text('Restaurar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar eliminadas: $e')),
        );
      }
    }
  }

  /// Restaurar transacción eliminada
  void _restoreTransaction(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Restaurar Transacción?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Se restaurará la transacción:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.concepto,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(transaction.montoFormateado),
                  Text(transaction.categoria),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _transactionService.restoreTransaction(
          transaction,
          widget.user.id,
          userFullName: widget.user.fullName,
        );
        
        if (mounted) {
          Navigator.of(context).pop(); // Cerrar dialog de eliminadas
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transacción restaurada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Recargar datos
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al restaurar: $e')),
          );
        }
      }
    }
  }
}