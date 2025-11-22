import 'package:flutter/material.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/chart_of_accounts_model.dart';
import '../../../shared/models/journal_entry_model.dart';
import '../../../shared/services/chart_of_accounts_service.dart';
import '../../../shared/services/journal_entry_service.dart';

/// Página principal del módulo de contabilidad
class AccountingPage extends StatefulWidget {
  final UserModel user;
  final BusinessModel business;

  const AccountingPage({
    super.key,
    required this.user,
    required this.business,
  });

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChartOfAccountsModel> _accounts = [];
  List<JournalEntryModel> _journalEntries = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAccounting();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeAccounting() async {
    setState(() => _isLoading = true);
    
    try {
      // Inicializar plan de cuentas si no existe
      await ChartOfAccountsService.initializeBasicChartOfAccounts(widget.business.id);
      
      // Cargar datos
      await Future.wait([
        _loadAccounts(),
        _loadJournalEntries(),
        _loadStats(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar contabilidad: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAccounts() async {
    _accounts = await ChartOfAccountsService.getAccountsByBusiness(widget.business.id);
    if (mounted) setState(() {});
  }

  Future<void> _loadJournalEntries() async {
    _journalEntries = await JournalEntryService.getJournalEntriesByBusiness(widget.business.id);
    if (mounted) setState(() {});
  }

  Future<void> _loadStats() async {
    _stats = await JournalEntryService.getJournalEntryStats(widget.business.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contabilidad - ${widget.business.displayName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'Resumen', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Plan de Cuentas', icon: Icon(Icons.account_tree_outlined)),
            Tab(text: 'Asientos', icon: Icon(Icons.receipt_long_outlined)),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildChartOfAccountsTab(),
              _buildJournalEntriesTab(),
            ],
          ),
      floatingActionButton: _tabController.index == 2 
        ? FloatingActionButton(
            onPressed: _createJournalEntry,
            child: const Icon(Icons.add),
            tooltip: 'Nuevo Asiento',
          )
        : null,
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen Contable',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Tarjetas de estadísticas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Asientos',
                  '${_stats['totalEntries'] ?? 0}',
                  Icons.receipt_long,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Este Mes',
                  '${_stats['thisMonthEntries'] ?? 0}',
                  Icons.calendar_month,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Borradores',
                  '${_stats['draftEntries'] ?? 0}',
                  Icons.edit_note,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Contabilizados',
                  '${_stats['postedEntries'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Plan de cuentas summary
          Text(
            'Plan de Cuentas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _buildAccountTypesSummary(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypesSummary() {
    final accountTypes = <String, List<ChartOfAccountsModel>>{};
    
    for (var account in _accounts) {
      accountTypes.putIfAbsent(account.tipo, () => []).add(account);
    }

    return ListView(
      children: accountTypes.entries.map((entry) {
        final tipo = entry.key;
        final accounts = entry.value;
        
        Color typeColor;
        IconData typeIcon;
        
        switch (tipo) {
          case 'ACTIVO':
            typeColor = Colors.green;
            typeIcon = Icons.trending_up;
            break;
          case 'PASIVO':
            typeColor = Colors.red;
            typeIcon = Icons.trending_down;
            break;
          case 'PATRIMONIO':
            typeColor = Colors.purple;
            typeIcon = Icons.account_balance;
            break;
          case 'INGRESO':
            typeColor = Colors.blue;
            typeIcon = Icons.arrow_circle_up;
            break;
          case 'GASTO':
            typeColor = Colors.orange;
            typeIcon = Icons.arrow_circle_down;
            break;
          default:
            typeColor = Colors.grey;
            typeIcon = Icons.help;
        }
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: Icon(typeIcon, color: typeColor),
            title: Text(
              tipo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${accounts.length} cuenta(s)'),
            children: accounts.map((account) {
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 64, right: 16),
                title: Text(account.fullName),
                subtitle: Text(account.subtipo),
                trailing: account.aceptaMovimiento
                  ? Icon(Icons.edit, size: 16, color: Colors.green)
                  : Icon(Icons.folder, size: 16, color: Colors.grey),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartOfAccountsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plan de Cuentas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addAccount,
                icon: const Icon(Icons.add),
                label: const Text('Nueva Cuenta'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getAccountTypeColor(account.tipo),
                      child: Text(
                        account.codigo.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(account.fullName),
                    subtitle: Text('${account.tipo} - ${account.subtipo}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (account.aceptaMovimiento)
                          Icon(Icons.edit, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleAccountAction(value, account),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Editar'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Eliminar'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalEntriesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asientos Contables',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: _journalEntries.length,
              itemBuilder: (context, index) {
                final entry = _journalEntries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getEntryStatusColor(entry.estado),
                      child: Text(
                        entry.numero.split('-')[1],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(entry.concepto),
                    subtitle: Text(
                      '${entry.numero} • ${_formatDate(entry.fecha)} • \$${entry.totalDebe.toStringAsFixed(2)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusChip(entry.estado),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _viewJournalEntry(entry),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccountTypeColor(String tipo) {
    switch (tipo) {
      case 'ACTIVO': return Colors.green;
      case 'PASIVO': return Colors.red;
      case 'PATRIMONIO': return Colors.purple;
      case 'INGRESO': return Colors.blue;
      case 'GASTO': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Color _getEntryStatusColor(String estado) {
    switch (estado) {
      case 'BORRADOR': return Colors.orange;
      case 'CONTABILIZADO': return Colors.green;
      case 'ANULADO': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildStatusChip(String estado) {
    Color color = _getEntryStatusColor(estado);
    
    return Chip(
      label: Text(
        estado,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _addAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de agregar cuenta próximamente')),
    );
  }

  void _handleAccountAction(String action, ChartOfAccountsModel account) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Editar cuenta: ${account.nombre}')),
        );
        break;
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eliminar cuenta: ${account.nombre}')),
        );
        break;
    }
  }

  void _createJournalEntry() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de crear asiento próximamente')),
    );
  }

  void _viewJournalEntry(JournalEntryModel entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ver asiento: ${entry.numero}')),
    );
  }
}