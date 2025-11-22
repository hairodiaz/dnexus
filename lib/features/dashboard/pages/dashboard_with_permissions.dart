import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_extensions.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/services/business_service.dart';
import '../../../shared/widgets/permission_widgets.dart';
import '../../transacciones/pages/transactions_page.dart';
import '../../reports/pages/consolidated_reports_page.dart';
import '../../clients/pages/clients_page.dart';
import '../../inventory/pages/inventory_page.dart';

/// Dashboard principal de D-Nexus con sistema de permisos
class DashboardPageWithPermissions extends StatefulWidget {
  final UserModel user;

  const DashboardPageWithPermissions({
    super.key,
    required this.user,
  });

  @override
  State<DashboardPageWithPermissions> createState() => _DashboardPageWithPermissionsState();
}

class _DashboardPageWithPermissionsState extends State<DashboardPageWithPermissions>
    with PermissionMixin {
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('D-Nexus Dashboard'),
        backgroundColor: Color(widget.user.roleColor),
        foregroundColor: Colors.white,
        actions: [
          // Mostrar rol del usuario en el AppBar
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  IconData(widget.user.roleIcon, fontFamily: 'MaterialIcons'),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.user.roleDisplayName,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showUserProfile();
                  break;
                case 'permissions':
                  _showUserPermissions();
                  break;
                case 'logout':
                  _handleLogout(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Color(widget.user.roleColor)),
                    const SizedBox(width: 12),
                    const Text('Mi Perfil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'permissions',
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Text('Mis Permisos'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingBody() : _buildMainBody(isMobile),
    );
  }

  Widget _buildLoadingBody() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando dashboard...'),
        ],
      ),
    );
  }

  Widget _buildMainBody(bool isMobile) {
    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            _buildBusinessSelector(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildStatCards(),
          ],
        ),
      );
    } else {
      return Row(
        children: [
          // Panel lateral
          SizedBox(
            width: 280,
            child: Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 16),
                  _buildBusinessSelector(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildQuickActions()),
                ],
              ),
            ),
          ),
          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStatCards(),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildWelcomeCard() {
    return UserRoleCard(
      user: widget.user,
      onTap: _showUserProfile,
    );
  }

  Widget _buildBusinessSelector() {
    if (_businesses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay negocios disponibles'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Negocio Activo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<BusinessModel>(
              value: _selectedBusiness,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _businesses.map((business) {
                return DropdownMenuItem(
                  value: business,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: business.isActive ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          business.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (business) {
                setState(() => _selectedBusiness = business);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      // Transacciones - Solo si tiene permisos
      if (widget.user.hasPermission('transactions_view'))
        _QuickAction(
          icon: Icons.account_balance_wallet,
          title: 'Transacciones',
          subtitle: 'Gestionar movimientos',
          color: Colors.blue,
          onTap: () => _navigateToTransactions(),
          permissions: ['transactions_view'],
        ),

      // Clientes - Solo si tiene permisos
      if (widget.user.hasPermission('clients_view'))
        _QuickAction(
          icon: Icons.people,
          title: 'Clientes',
          subtitle: 'Gestionar clientes',
          color: Colors.green,
          onTap: () => _navigateToClients(),
          permissions: ['clients_view'],
        ),

      // Inventario - Solo si tiene permisos
      if (widget.user.hasPermission('inventory_view'))
        _QuickAction(
          icon: Icons.inventory,
          title: 'Inventario',
          subtitle: 'Gestionar productos',
          color: Colors.orange,
          onTap: () => _navigateToInventory(),
          permissions: ['inventory_view'],
        ),

      // Facturación - Solo si puede facturar
      if (widget.user.canInvoice)
        _QuickAction(
          icon: Icons.receipt_long,
          title: 'Facturación',
          subtitle: 'Crear facturas',
          color: Colors.purple,
          onTap: () => _navigateToInvoicing(),
          permissions: ['invoicing_create'],
        ),

      // Reportes - Solo si tiene permisos
      if (widget.user.hasPermission('reports_view'))
        _QuickAction(
          icon: Icons.analytics,
          title: 'Reportes',
          subtitle: 'Ver estadísticas',
          color: Colors.indigo,
          onTap: () => _navigateToReports(),
          permissions: ['reports_view'],
        ),

      // Empleados - Solo administradores
      if (widget.user.canManageEmployees)
        _QuickAction(
          icon: Icons.badge,
          title: 'Empleados',
          subtitle: 'Gestionar personal',
          color: Colors.teal,
          onTap: () => _navigateToEmployees(),
          permissions: ['employees_view'],
        ),

      // Configuración - Solo administradores
      if (widget.user.canAccessSettings)
        _QuickAction(
          icon: Icons.settings,
          title: 'Configuración',
          subtitle: 'Ajustes del sistema',
          color: Colors.grey,
          onTap: () => _navigateToSettings(),
          permissions: ['settings_view'],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...actions.map((action) => 
          PermissionWidget(
            user: widget.user,
            requiredPermissions: action.permissions,
            requireAll: false,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: _buildActionCard(action),
            ),
          )
        ),
      ],
    );
  }

  Widget _buildActionCard(_QuickAction action) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: action.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            action.icon,
            color: action.color,
            size: 24,
          ),
        ),
        title: Text(
          action.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          action.subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: action.onTap,
      ),
    );
  }

  Widget _buildStatCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Mostrar estadísticas solo si tiene permisos de reportes
        PermissionWidget(
          user: widget.user,
          requiredPermission: 'reports_view',
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Ventas Hoy',
                '\$250,000',
                Icons.trending_up,
                Colors.green,
              ),
              _buildStatCard(
                'Transacciones',
                '45',
                Icons.swap_horiz,
                Colors.blue,
              ),
              _buildStatCard(
                'Clientes',
                '128',
                Icons.people,
                Colors.purple,
              ),
              _buildStatCard(
                'Productos',
                '89',
                Icons.inventory,
                Colors.orange,
              ),
            ],
          ),
          fallback: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.lock,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sin permisos para ver estadísticas',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Perfil de Usuario',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              UserRoleCard(user: widget.user),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserPermissions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mis Permisos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: UserPermissionsView(user: widget.user),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos de navegación con verificación de permisos
  void _navigateToTransactions() {
    if (checkPermissionOrError(context, widget.user, 'transactions_view')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionsPage(
            user: widget.user,
            businessId: _selectedBusiness?.id,
          ),
        ),
      );
    }
  }

  void _navigateToClients() {
    if (checkPermissionOrError(context, widget.user, 'clients_view')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientsPage(user: widget.user),
        ),
      );
    }
  }

  void _navigateToInventory() {
    if (checkPermissionOrError(context, widget.user, 'inventory_view')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InventoryPage(
            user: widget.user,
            businessId: _selectedBusiness?.id ?? 1,
          ),
        ),
      );
    }
  }

  void _navigateToInvoicing() {
    if (checkPermissionOrError(context, widget.user, 'invoicing_create')) {
      // Navigator.push para facturación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Módulo de facturación en desarrollo')),
      );
    }
  }

  void _navigateToReports() {
    if (checkPermissionOrError(context, widget.user, 'reports_view')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConsolidatedReportsPage(user: widget.user),
        ),
      );
    }
  }

  void _navigateToEmployees() {
    if (checkPermissionOrError(context, widget.user, 'employees_view')) {
      // Navigator.push para empleados
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Módulo de empleados en desarrollo')),
      );
    }
  }

  void _navigateToSettings() {
    if (checkPermissionOrError(context, widget.user, 'settings_view')) {
      // Navigator.push para configuración
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Módulo de configuración en desarrollo')),
      );
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver al login
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final List<String> permissions;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.permissions,
  });
}