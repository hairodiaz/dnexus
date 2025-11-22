import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/services/business_service.dart';
import '../../transacciones/pages/transactions_page.dart';

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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${widget.user.fullName ?? widget.user.username} (${widget.user.role})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Cerrar Sesión',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: Text(
                      widget.user.username[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down),
                ],
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
            
            // Grid de módulos
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildModuleCard(
                    context,
                    icon: Icons.monetization_on,
                    title: 'Transacciones',
                    subtitle: 'Ingresos, Egresos y Control de Caja',
                    color: Colors.green,
                    onTap: () => _navigateToModule(context, 'transactions'),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
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
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}