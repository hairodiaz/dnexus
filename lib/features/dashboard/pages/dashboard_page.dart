import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/services/business_service.dart';
import '../../transacciones/pages/transactions_page.dart';
import '../../reports/pages/consolidated_reports_page.dart';
import '../../clients/pages/clients_page.dart';

/// Dashboard principal de D-Nexus
class DashboardPage extends StatefulWidget {
  final UserModel user;

  const DashboardPage({
    super.key,
    required this.user,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<BusinessModel> _businesses = [];
  BusinessModel? _selectedBusiness;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    setState(() => _isLoading = true);
    try {
      _businesses = await BusinessService.getBusinessesForUser(widget.user.id);
      if (_businesses.isNotEmpty) {
        _selectedBusiness = _businesses.first;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar negocios: $e')),
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
        title: const Text('D-Nexus Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  _handleLogout(context);
                }
              },
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.fullName ?? widget.user.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.user.role,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red[600]),
                        const SizedBox(width: 12),
                        const Text(
                          'Cerrar Sesión',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.onPrimary,
                      radius: 16,
                      child: Text(
                        widget.user.username[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.user.fullName?.split(' ').first ?? widget.user.username,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo de bienvenida
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.waving_hand,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Bienvenido, ${widget.user.fullName ?? widget.user.username}!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sistema de Gestión Multi-Negocios',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Selector de negocio
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_businesses.isNotEmpty) ...
            [
              _buildBusinessSelector(),
              const SizedBox(height: 24),
            ],
            
            // Título de módulos
            Text(
              'Módulos Disponibles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Grid de módulos - Layout responsivo
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final crossAxisCount = isMobile ? 2 : 4;
                  final childAspectRatio = isMobile ? 1.1 : 1.3;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: isMobile ? 12 : 16,
                    mainAxisSpacing: isMobile ? 12 : 16,
                    childAspectRatio: childAspectRatio,
                children: [
                  _buildModuleCard(
                    context,
                    icon: Icons.monetization_on,
                    title: 'Transacciones',
                    subtitle: 'Ingresos, Egresos y Control de Caja',
                    color: Colors.green,
                    onTap: () => _navigateToModule(context, 'transactions'),
                  ),
                  // Módulo especial para Super Admin
                  if (widget.user.role == 'super_admin')
                    _buildModuleCard(
                      context,
                      icon: Icons.dashboard_outlined,
                      title: 'Reportes Consolidados',
                      subtitle: 'Vista Global de Todos los Negocios',
                      color: Colors.purple,
                      onTap: () => _navigateToModule(context, 'consolidated_reports'),
                    ),
                  _buildModuleCard(
                    context,
                    icon: Icons.analytics,
                    title: 'Reportes',
                    subtitle: 'Análisis y Estadísticas',
                    color: Colors.blue,
                    onTap: () => _navigateToModule(context, 'reports'),
                  ),
                  _buildModuleCard(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    subtitle: 'Panel de Control',
                    color: Colors.purple,
                    onTap: () => _navigateToModule(context, 'dashboard'),
                  ),
                  _buildModuleCard(
                    context,
                    icon: Icons.inventory,
                    title: 'Inventario',
                    subtitle: 'Gestión de Stock',
                    color: Colors.orange,
                    onTap: () => _navigateToModule(context, 'inventory'),
                  ),
                  _buildModuleCard(
                    context,
                    icon: Icons.people,
                    title: 'Clientes',
                    subtitle: 'Base de Clientes',
                    color: Colors.teal,
                    onTap: () => _navigateToModule(context, 'clients'),
                  ),
                  _buildModuleCard(
                    context,
                    icon: Icons.settings,
                    title: 'Configuración',
                    subtitle: 'Ajustes del Sistema',
                    color: Colors.grey,
                    onTap: () => _navigateToModule(context, 'settings'),
                  ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el selector de negocio
  Widget _buildBusinessSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Negocio Activo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedBusiness != null) ...
            [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<BusinessModel>(
                    value: _selectedBusiness,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    items: _businesses.map((business) {
                      return DropdownMenuItem<BusinessModel>(
                        value: business,
                        child: Row(
                          children: [
                            Text(
                              business.displayName,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            const SizedBox(width: 8),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (BusinessModel? newBusiness) {
                      if (newBusiness != null) {
                        setState(() {
                          _selectedBusiness = newBusiness;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cambiado a: ${newBusiness.displayName}'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedBusiness?.descripcion?.isNotEmpty == true)
                Text(
                  _selectedBusiness!.descripcion!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
            ]
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No tienes acceso a ningún negocio',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Construye una tarjeta de módulo
  Widget _buildModuleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navega a un módulo específico
  void _navigateToModule(BuildContext context, String module) {
    if (module == 'transactions' && _selectedBusiness != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TransactionsPage(
            user: widget.user,
            business: _selectedBusiness!,
          ),
        ),
      );
    } else if (module == 'consolidated_reports' && widget.user.role == 'super_admin') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConsolidatedReportsPage(
            user: widget.user,
          ),
        ),
      );
    } else if (module == 'clients') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ClientsPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Módulo "$module" próximamente disponible'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Maneja el cierre de sesión
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: Colors.red[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Está seguro que desea cerrar sesión?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}