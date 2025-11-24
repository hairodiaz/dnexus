import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_extensions.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/models/business_model.dart';
import '../../../shared/services/business_service.dart';
import '../../../shared/services/auth_service_with_roles.dart';
import '../../../shared/widgets/permission_widgets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../transacciones/pages/transactions_page.dart';
import '../../cash_register/pages/cash_register_page.dart';
import '../../invoices/pages/invoice_list_page.dart';
import '../../invoices/pages/create_invoice_simple.dart';
import '../../invoices/pages/cashier_simple.dart';
import '../../clients/pages/clients_page.dart';
import '../../inventory/pages/inventory_page.dart';
import '../../employees/pages/employees_page_basic.dart';
import '../../../shared/services/client_service.dart';
import '../../../shared/services/inventory_service.dart';
import '../widgets/professional_stats_card.dart';
import '../widgets/executive_summary.dart';

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
    _preloadData();
  }

  /// Precarga datos de clientes y productos para mejor rendimiento
  Future<void> _preloadData() async {
    try {
      // Precargar clientes
      ClientService().getAllClients();
      
      // Precargar productos del negocio principal
      if (_businesses.isNotEmpty) {
        final businessId = _businesses.first.id;
        await InventoryService.getProducts(businessId);
      }
    } catch (e) {
      // Silenciar errores de precarga para no afectar la experiencia del usuario
      print('Error precargando datos: $e');
    }
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
        backgroundColor: Color(widget.user.roleColor ?? 0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          // Mostrar rol del usuario en el AppBar
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  IconData(widget.user.roleIcon ?? 0xe7fd, fontFamily: 'MaterialIcons'),
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
                    Icon(Icons.person, color: Color(widget.user.roleColor ?? 0xFF2196F3)),
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
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              _buildBusinessSelector(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildStatCards(),
              // Espacio adicional para mejor scroll
              const SizedBox(height: 60),
            ],
          ),
        ),
      );
    } else {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: Row(
          children: [
            // Panel lateral
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final panelWidth = screenWidth < 1200 ? 320.0 : 380.0;
                
                return SizedBox(
                  width: panelWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Parte fija del panel
                        Padding(
                          padding: EdgeInsets.all(screenWidth < 1200 ? 16 : 24),
                          child: Column(
                            children: [
                              _buildWelcomeCard(),
                              _buildBusinessSelector(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        // Parte scrollable del panel
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth < 1200 ? 16 : 24,
                            ),
                            child: _buildQuickActions(),
                          ),
                        ),
                        // Espacio adicional al final
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStatCards(),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4facfe),
            Color(0xFF00f2fe),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(
                IconData(widget.user.roleIcon ?? 0xe7fd, fontFamily: 'MaterialIcons'),
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.user.fullName ?? widget.user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.user.roleDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
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
    );
  }

  Widget _buildBusinessSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.business,
                    color: Color(0xFF667eea),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Negocio Activo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2d3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.user.fullName ?? 'Negocio Demo',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      // Transacciones - Visible para la mayoría de roles
      _QuickAction(
        icon: Icons.account_balance_wallet,
        title: 'Transacciones',
        subtitle: 'Gestionar movimientos',
        color: Colors.blue,
        onTap: () => _navigateToTransactions(),
        permissions: ['transactions_view'],
      ),

      // Clientes - Visible para todos los roles operativos
      _QuickAction(
        icon: Icons.people,
        title: 'Clientes',
        subtitle: 'Gestionar clientes',
        color: Colors.green,
        onTap: () => _navigateToClients(),
        permissions: ['clients_view'],
      ),

      // Inventario - Visible para todos los roles operativos
      _QuickAction(
        icon: Icons.inventory,
        title: 'Inventario',
        subtitle: 'Gestionar productos',
        color: Colors.orange,
        onTap: () => _navigateToInventory(),
        permissions: ['inventory_view'],
      ),

      // Facturación General - Lista de facturas
      _QuickAction(
        icon: Icons.receipt_long,
        title: 'Facturas',
        subtitle: 'Ver todas las facturas',
        color: Colors.purple,
        onTap: () => _navigateToInvoicing(),
        permissions: ['invoicing_create'],
      ),

      // Crear Facturas - Específico para facturadores
      if (widget.user.hasPermission('invoicing_create'))
        _QuickAction(
          icon: Icons.add_business,
          title: 'Crear Factura',
          subtitle: 'Nueva factura rápida',
          color: Colors.blue,
          onTap: () => _navigateToCreateInvoice(),
          permissions: ['invoicing_create'],
        ),

      // Caja - Específico para cajeros
      if (widget.user.hasPermission('invoicing_process'))
        _QuickAction(
          icon: Icons.point_of_sale,
          title: 'Caja',
          subtitle: 'Procesar pagos',
          color: Colors.green,
          onTap: () => _navigateToCashier(),
          permissions: ['invoicing_process'],
        ),

      // Caja Registradora - Para roles con permisos de caja
      if (widget.user.hasPermission('cash_register_view') || widget.user.userRole == UserRole.admin || widget.user.userRole == UserRole.superAdmin)
        _QuickAction(
          icon: Icons.app_registration,
          title: 'Caja Registradora',
          subtitle: 'Gestionar apertura/cierre',
          color: Colors.amber,
          onTap: () => _navigateToCashRegister(),
          permissions: ['cash_register_view'],
        ),

      // Reportes - Solo si tiene permisos
      _QuickAction(
        icon: Icons.analytics,
        title: 'Reportes',
        subtitle: 'Ver estadísticas',
        color: Colors.indigo,
        onTap: () => _navigateToReports(),
        permissions: ['reports_view'],
      ),

      // Empleados - Solo si tiene permisos
      _QuickAction(
        icon: Icons.badge,
        title: 'Empleados',
        subtitle: 'Gestionar personal',
        color: Colors.teal,
        onTap: () => _navigateToEmployees(),
        permissions: ['employees_view'],
      ),

      // Configuración - Solo si tiene permisos
      _QuickAction(
        icon: Icons.settings,
        title: 'Configuración',
        subtitle: 'Ajustes del sistema',
        color: Colors.grey,
        onTap: () => _navigateToSettings(),
        permissions: ['settings_view'],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallPanel = constraints.maxWidth < 350;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(isSmallPanel ? 6 : 8),
                  child: Icon(
                    Icons.dashboard,
                    color: const Color(0xFF667eea),
                    size: isSmallPanel ? 18 : 20,
                  ),
                ),
                SizedBox(width: isSmallPanel ? 8 : 12),
                Expanded(
                  child: Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontSize: isSmallPanel ? 18 : 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2d3748),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallPanel ? 8 : 12),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: actions.map((action) => 
                      PermissionWidget(
                        user: widget.user,
                        requiredPermissions: action.permissions,
                        requireAll: false,
                        child: Container(
                          margin: EdgeInsets.only(bottom: isSmallPanel ? 6 : 8),
                          child: _buildActionCard(action, isSmallPanel),
                        ),
                      )
                    ).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(_QuickAction action, [bool isSmallPanel = false]) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(isSmallPanel ? 12 : 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallPanel ? 12 : 16),
            border: Border.all(
              color: action.color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: action.color.withOpacity(0.1),
                blurRadius: isSmallPanel ? 10 : 15,
                offset: Offset(0, isSmallPanel ? 4 : 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallPanel ? 14 : 20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        action.color,
                        action.color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isSmallPanel ? 10 : 12),
                    boxShadow: [
                      BoxShadow(
                        color: action.color.withOpacity(0.3),
                        blurRadius: isSmallPanel ? 6 : 8,
                        offset: Offset(0, isSmallPanel ? 2 : 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(isSmallPanel ? 10 : 12),
                  child: Icon(
                    action.icon,
                    color: Colors.white,
                    size: isSmallPanel ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallPanel ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isSmallPanel ? 14 : 16,
                          color: const Color(0xFF2d3748),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallPanel ? 2 : 4),
                      Text(
                        action.subtitle,
                        style: TextStyle(
                          fontSize: isSmallPanel ? 11 : 13,
                          color: const Color(0xFF718096),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: EdgeInsets.all(isSmallPanel ? 6 : 8),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: isSmallPanel ? 12 : 14,
                    color: action.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen ejecutivo
        const ExecutiveSummary(
          totalSales: 'RD\$ 2,450,000',
          monthlyGrowth: '+15.2%',
          totalTransactions: 234,
          activeClients: 128,
          isPositiveGrowth: true,
        ),
        
        const SizedBox(height: 32),
        
        // Header de estadísticas detalladas
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.analytics,
                color: Color(0xFF667eea),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Estadísticas Detalladas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2d3748),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Mostrar estadísticas basadas en el rol del usuario
        _buildRoleBasedStats(),
        
        const SizedBox(height: 32),
        
        // Alertas del sistema
        const BusinessAlerts(),
      ],
    );
  }

  Widget _buildRoleBasedStats() {
    // Verificar si tiene permisos de reportes (roles administrativos)
    if (widget.user.hasPermission('reports_view')) {
      return _buildGeneralStats();
    }
    
    // Estadísticas específicas para facturador
    if (widget.user.userRole == UserRole.facturador) {
      return _buildInvoicingStats();
    }
    
    // Estadísticas básicas para otros roles con permisos limitados
    if (widget.user.hasPermission('clients_view') || 
        widget.user.hasPermission('inventory_view')) {
      return _buildBasicStats();
    }
    
    // Sin permisos
    return _buildNoPermissionsWidget();
  }

  Widget _buildGeneralStats() {
    final salesData = [120000.0, 145000.0, 138000.0, 165000.0, 180000.0, 205000.0, 250000.0];
    final transactionData = [28.0, 32.0, 35.0, 31.0, 42.0, 38.0, 45.0];
    final clientData = [98.0, 105.0, 112.0, 108.0, 118.0, 125.0, 128.0];
    final productData = [78.0, 82.0, 85.0, 83.0, 87.0, 89.0, 89.0];
    
    return StatsGrid(
      cards: [
        ProfessionalStatsCard(
          title: 'Ventas Hoy',
          value: CurrencyFormatter.formatForDashboard(250000),
          subtitle: 'Meta: RD\$ 300K',
          icon: Icons.trending_up,
          primaryColor: const Color(0xFF10b981),
          secondaryColor: const Color(0xFF34d399),
          trend: '+12.5%',
          isPositiveTrend: true,
          percentage: 18.2,
          chartData: salesData,
          onTap: () => _navigateToSalesReport(),
        ),
        ProfessionalStatsCard(
          title: 'Transacciones',
          value: '45',
          subtitle: 'Promedio: 38/día',
          icon: Icons.swap_horiz,
          primaryColor: const Color(0xFF3b82f6),
          secondaryColor: const Color(0xFF60a5fa),
          trend: '+8.2%',
          isPositiveTrend: true,
          percentage: 8.2,
          chartData: transactionData,
          onTap: () => _navigateToTransactions(),
        ),
        ProfessionalStatsCard(
          title: 'Clientes Activos',
          value: '128',
          subtitle: 'Nuevos: 12 este mes',
          icon: Icons.people,
          primaryColor: const Color(0xFF8b5cf6),
          secondaryColor: const Color(0xFFa78bfa),
          trend: '+5.7%',
          isPositiveTrend: true,
          percentage: 5.7,
          chartData: clientData,
          onTap: () => _navigateToClients(),
        ),
        ProfessionalStatsCard(
          title: 'Productos',
          value: '89',
          subtitle: 'Stock total: 1,245 unidades',
          icon: Icons.inventory,
          primaryColor: const Color(0xFFf59e0b),
          secondaryColor: const Color(0xFFfbbf24),
          trend: '0%',
          isPositiveTrend: true,
          percentage: 0.0,
          chartData: productData,
          onTap: () => _navigateToInventory(),
        ),
      ],
    );
  }

  Widget _buildInvoicingStats() {
    final invoicesData = [8.0, 10.0, 9.0, 11.0, 14.0, 13.0, 12.0];
    final salesData = [45000.0, 52000.0, 48000.0, 61000.0, 72000.0, 78000.0, 85000.0];
    final clientsData = [15.0, 18.0, 16.0, 22.0, 26.0, 23.0, 24.0];
    final productsData = [89.0, 102.0, 95.0, 128.0, 145.0, 138.0, 156.0];
    
    return StatsGrid(
      cards: [
        ProfessionalStatsCard(
          title: 'Facturas Hoy',
          value: '12',
          subtitle: 'Promedio: 9/día',
          icon: Icons.receipt_long,
          primaryColor: const Color(0xFF3b82f6),
          secondaryColor: const Color(0xFF60a5fa),
          trend: '+33%',
          isPositiveTrend: true,
          percentage: 33.3,
          chartData: invoicesData,
          onTap: () => _navigateToInvoices(),
        ),
        ProfessionalStatsCard(
          title: 'Total Facturado',
          value: CurrencyFormatter.formatForDashboard(85000),
          subtitle: 'Meta diaria: RD\$ 100K',
          icon: Icons.monetization_on,
          primaryColor: const Color(0xFF10b981),
          secondaryColor: const Color(0xFF34d399),
          trend: '+18.5%',
          isPositiveTrend: true,
          percentage: 18.5,
          chartData: salesData,
          onTap: () => _navigateToSalesReport(),
        ),
        ProfessionalStatsCard(
          title: 'Clientes Atendidos',
          value: '24',
          subtitle: 'Únicos hoy',
          icon: Icons.people_outline,
          primaryColor: const Color(0xFF8b5cf6),
          secondaryColor: const Color(0xFFa78bfa),
          trend: '+4.3%',
          isPositiveTrend: true,
          percentage: 4.3,
          chartData: clientsData,
          onTap: () => _navigateToClients(),
        ),
        ProfessionalStatsCard(
          title: 'Productos Vendidos',
          value: '156',
          subtitle: 'Unidades hoy',
          icon: Icons.inventory_2,
          primaryColor: const Color(0xFFf59e0b),
          secondaryColor: const Color(0xFFfbbf24),
          trend: '+12.9%',
          isPositiveTrend: true,
          percentage: 12.9,
          chartData: productsData,
          onTap: () => _navigateToInventory(),
        ),
      ],
    );
  }

  Widget _buildBasicStats() {
    final clientData = [98.0, 105.0, 112.0, 108.0, 118.0, 125.0, 128.0];
    final productData = [78.0, 82.0, 85.0, 83.0, 87.0, 89.0, 89.0];
    
    List<ProfessionalStatsCard> cards = [];
    
    if (widget.user.hasPermission('clients_view')) {
      cards.add(
        ProfessionalStatsCard(
          title: 'Clientes Registrados',
          value: '128',
          subtitle: 'Activos este mes: 96',
          icon: Icons.people,
          primaryColor: const Color(0xFF8b5cf6),
          secondaryColor: const Color(0xFFa78bfa),
          trend: '+5.7%',
          isPositiveTrend: true,
          percentage: 5.7,
          chartData: clientData,
          onTap: () => _navigateToClients(),
        ),
      );
    }
    
    if (widget.user.hasPermission('inventory_view')) {
      cards.add(
        ProfessionalStatsCard(
          title: 'Productos Disponibles',
          value: '89',
          subtitle: 'Stock total: 1,245 unidades',
          icon: Icons.inventory,
          primaryColor: const Color(0xFFf59e0b),
          secondaryColor: const Color(0xFFfbbf24),
          trend: '0%',
          isPositiveTrend: true,
          percentage: 0.0,
          chartData: productData,
          onTap: () => _navigateToInventory(),
        ),
      );
    }
    
    return StatsGrid(cards: cards);
  }

  Widget _buildNoPermissionsWidget() {
    return Card(
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
      if (_selectedBusiness != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionsPage(
              user: widget.user,
              business: _selectedBusiness!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona un negocio primero')),
        );
      }
    }
  }

  void _navigateToClients() {
    if (checkPermissionOrError(context, widget.user, 'clients_view')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientsPage(),
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceListPage(
            user: widget.user,
            businessId: _selectedBusiness?.id ?? 1,
          ),
        ),
      );
    }
  }

  void _navigateToCreateInvoice() {
    if (checkPermissionOrError(context, widget.user, 'invoicing_create')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateInvoiceSimplePage(
            user: widget.user,
            businessId: _selectedBusiness?.id ?? 1,
          ),
        ),
      );
    }
  }

  void _navigateToCashier() {
    if (checkPermissionOrError(context, widget.user, 'invoicing_process')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CashierSimplePage(
            user: widget.user,
            businessId: _selectedBusiness?.id ?? 1,
          ),
        ),
      );
    }
  }

  void _navigateToCashRegister() {
    if (checkPermissionOrError(context, widget.user, 'cash_register_view') || 
        widget.user.userRole == UserRole.admin || 
        widget.user.userRole == UserRole.superAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CashRegisterPage(
            user: widget.user,
            businessId: _selectedBusiness?.id ?? 1,
          ),
        ),
      );
    }
  }

  void _navigateToReports() {
    if (checkPermissionOrError(context, widget.user, 'reports_view')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Módulo de reportes en desarrollo')),
      );
    }
  }

  void _navigateToSalesReport() {
    if (checkPermissionOrError(context, widget.user, 'reports_view')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte de ventas en desarrollo')),
      );
    }
  }

  void _navigateToInvoices() {
    if (checkPermissionOrError(context, widget.user, 'invoices_view')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceListPage(
            user: widget.user,
            businessId: _selectedBusiness?.id ?? 1,
          ),
        ),
      );
    }
  }

  void _navigateToEmployees() {
    if (checkPermissionOrError(context, widget.user, 'employees_view')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmployeesPageBasic(currentUser: widget.user),
        ),
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
    final navigator = Navigator.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Cerrar diálogo inmediatamente
              Navigator.pop(dialogContext);
              
              try {
                print('🔄 Iniciando logout...');
                
                // Limpiar sesión
                await AuthService.logout();
                print('✅ Sesión limpiada');
                
                // Navegar al login usando el navigator guardado
                // Usar scheduleMicrotask para evitar problemas de contexto
                scheduleMicrotask(() {
                  if (mounted) {
                    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                    print('✅ Navegación al login completada');
                  }
                });
                
              } catch (e) {
                print('❌ Error en logout: $e');
                // Fallback directo
                if (mounted) {
                  navigator.pushReplacementNamed('/login');
                }
              }
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

/// Widget temporal simple para UserRoleCard
class UserRoleCard extends StatelessWidget {
  final UserModel user;
  final bool? showPermissions;

  const UserRoleCard({Key? key, required this.user, this.showPermissions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Bienvenido, ${user.fullName ?? user.username}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Rol: ${user.role}'),
          ],
        ),
      ),
    );
  }
}