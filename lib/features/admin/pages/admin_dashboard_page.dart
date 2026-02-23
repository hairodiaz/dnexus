import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/business_model_new.dart';
import '../../../shared/models/contact_model.dart';
import '../../../shared/models/address_model.dart';
import '../../../shared/models/employee_model.dart';
import '../../../shared/models/role_model.dart';
import '../../../core/repositories/business_repository.dart';
import '../../../core/repositories/employee_repository.dart';

/// Dashboard del Administrador - Panel de gestión de negocios y empleados
class AdminDashboardPage extends StatefulWidget {
  final UserModel currentUser;

  const AdminDashboardPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  late BusinessRepository _businessRepository;
  late EmployeeRepository _employeeRepository;
  List<BusinessModel> _businesses = [];
  BusinessModel? _selectedBusiness;
  List<EmployeeModel> _employees = [];
  EmployeeModel? _selectedEmployee;
  List<RoleModel> _roles = [];
  bool _isLoading = false;
  
  // Sistema options
  static const List<String> _sistemaOptions = ['Repuesto', 'Prestamo', 'Inmuebles'];

  @override
  void initState() {
    super.initState();
    _businessRepository = BusinessRepository(client: Supabase.instance.client);
    _employeeRepository = EmployeeRepository(client: Supabase.instance.client);
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    setState(() => _isLoading = true);
    try {
      final businesses =
          await _businessRepository.getBusinessesByAdmin(widget.currentUser.id!);
      setState(() {
        _businesses = businesses;
        if (_businesses.isNotEmpty && _selectedBusiness == null) {
          _selectedBusiness = _businesses.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Menú lateral
          _buildSidebar(context),
          // Contenido principal
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final menuItems = [
      {'icon': Icons.home, 'label': 'Dashboard', 'index': 0},
      {'icon': Icons.store, 'label': 'Negocios', 'index': 1},
      {'icon': Icons.people, 'label': 'Empleados', 'index': 2},
      {'icon': Icons.security, 'label': 'Roles', 'index': 3},
      {'icon': Icons.dashboard, 'label': 'Módulos por Rol', 'index': 4},
      {'icon': Icons.people_outline, 'label': 'Clientes', 'index': 5},
      {'icon': Icons.settings, 'label': 'Configuración', 'index': 6},
      {'icon': Icons.history, 'label': 'Auditoría', 'index': 7},
    ];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.indigo[800],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del menú
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo[900],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'D-NEXUS',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Panel Administrador',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.currentUser.fullName ?? widget.currentUser.username,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Items del menú
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = _selectedIndex == item['index'];
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Colors.white12,
                  leading: Icon(
                    item['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  title: Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedIndex = item['index'] as int);
                  },
                );
              },
            ),
          ),
          // Botón logout
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildAdminHome();
      case 1:
        return _buildBusinessesSection();
      case 2:
        return _buildEmployeesSection();
      case 3:
        return _buildRolesSection();
      case 4:
        return _buildModulesByRoleSection();
      case 5:
        return _buildClientesSection();
      case 6:
        return _buildConfiguracionSection();
      case 7:
        return _buildAuditSection();
      default:
        return const Center(child: Text('Selecciona una opción'));
    }
  }

  Widget _buildAdminHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Administrativo',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bienvenido, ${widget.currentUser.fullName ?? widget.currentUser.username}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          // Tarjetas de resumen
          GridView.count(
            crossAxisCount: 4,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                title: 'Negocios',
                value: _businesses.length.toString(),
                icon: Icons.store,
                color: Colors.blue,
              ),
              _buildStatCard(
                title: 'Empleados',
                value: '0',
                icon: Icons.people,
                color: Colors.green,
              ),
              _buildStatCard(
                title: 'Clientes',
                value: '0',
                icon: Icons.people_outline,
                color: Colors.orange,
              ),
              _buildStatCard(
                title: 'Roles',
                value: '0',
                icon: Icons.security,
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessesSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestión de Negocios',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateBusinessDialog,
                icon: const Icon(Icons.add_business),
                label: const Text('+ Nuevo Negocio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_businesses.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes negocios registrados',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu primer negocio para comenzar',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  // Tabla de negocios
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      columns: [
                        DataColumn(label: const Text('Nombre')),
                        DataColumn(label: const Text('NIT')),
                        DataColumn(label: const Text('Sistema')),
                        DataColumn(label: const Text('Estado')),
                        DataColumn(label: const Text('Acciones')),
                      ],
                      rows: _businesses.map((business) {
                        final isSelected = _selectedBusiness?.id == business.id;
                        return DataRow(
                          selected: isSelected,
                          onSelectChanged: (selected) {
                            setState(() => _selectedBusiness = business);
                          },
                          cells: [
                            DataCell(Text(business.nombre)),
                            DataCell(Text(business.nit ?? 'N/A')),
                            DataCell(
                              Chip(
                                label: Text(business.sistema),
                                labelStyle: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                                backgroundColor: _getSistemaColor(business.sistema),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            DataCell(
                              Chip(
                                label: Text(
                                  business.estado ? 'Activo' : 'Inactivo',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: business.estado
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  color:
                                      business.estado ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () =>
                                        _showEditBusinessDialog(business),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      business.estado
                                          ? Icons.block
                                          : Icons.check_circle,
                                      size: 18,
                                      color: business.estado
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                    onPressed: () =>
                                        _toggleBusinessStatus(business),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Mostrar detalles si hay negocio seleccionado
          if (_selectedBusiness != null) ...[
            Text(
              'Detalles de ${_selectedBusiness!.nombre}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Información básica
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información General',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2,
                      children: [
                        _buildInfoField('Nombre', _selectedBusiness!.nombre),
                        _buildInfoField(
                          'NIT',
                          _selectedBusiness!.nit ?? 'N/A',
                        ),
                        _buildInfoField(
                          'Sistema',
                          _selectedBusiness!.sistema,
                        ),
                        _buildInfoField(
                          'Fecha Registro',
                          _selectedBusiness!.fechaRegistro != null
                              ? DateFormat('dd/MM/yyyy')
                                  .format(_selectedBusiness!.fechaRegistro!)
                              : 'N/A',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contactos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Contactos',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showManageContactsDialog(_selectedBusiness!),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_selectedBusiness!.contactos.isEmpty)
                      Text(
                        'Sin contactos registrados',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    else
                      Column(
                        children: _selectedBusiness!.contactos
                            .map((c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                c.tipo == 'telefono'
                                    ? Icons.phone
                                    : Icons.email,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(c.valor)),
                              if (c.principal)
                                Chip(
                                  label: const Text('Principal'),
                                  labelStyle: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                        ))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Direcciones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Direcciones',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showManageAddressesDialog(_selectedBusiness!),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_selectedBusiness!.direcciones.isEmpty)
                      Text(
                        'Sin direcciones registradas',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    else
                      Column(
                        children: _selectedBusiness!.direcciones
                            .map((d) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.calle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (d.ciudad != null ||
                                        d.departamento != null)
                                      Text(
                                        '${d.ciudad ?? ''} ${d.departamento ?? ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (d.principal)
                                Chip(
                                  label: const Text('Principal'),
                                  labelStyle: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                        ))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSistemaColor(String sistema) {
    switch (sistema) {
      case 'Repuesto':
        return Colors.blue;
      case 'Prestamo':
        return Colors.purple;
      case 'Inmuebles':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showCreateBusinessDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateBusinessDialog(
        repository: _businessRepository,
        adminId: widget.currentUser.id!,
        onBusinessCreated: _loadBusinesses,
      ),
    );
  }

  void _showEditBusinessDialog(BusinessModel business) {
    showDialog(
      context: context,
      builder: (context) => _EditBusinessDialog(
        business: business,
        repository: _businessRepository,
        onBusinessUpdated: _loadBusinesses,
      ),
    );
  }

  void _showManageContactsDialog(BusinessModel business) {
    showDialog(
      context: context,
      builder: (context) => _ManageContactsDialog(
        business: business,
        repository: _businessRepository,
        onUpdated: _loadBusinesses,
      ),
    );
  }

  void _showManageAddressesDialog(BusinessModel business) {
    showDialog(
      context: context,
      builder: (context) => _ManageAddressesDialog(
        business: business,
        repository: _businessRepository,
        onUpdated: _loadBusinesses,
      ),
    );
  }

  Future<void> _toggleBusinessStatus(BusinessModel business) async {
    final newStatus = !business.estado;
    try {
      await _businessRepository.toggleBusinessStatus(business.id, newStatus);
      await _loadBusinesses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Negocio activado correctamente'
                  : 'Negocio desactivado correctamente',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildEmployeesSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Empleados',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Administra los empleados por negocio',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (_selectedBusiness != null)
                ElevatedButton.icon(
                  onPressed: () => _showCreateEmployeeDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Empleado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                )
              else
                Text(
                  'Selecciona un negocio primero',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Selector de negocio
          if (_businesses.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Negocio Seleccionado',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<BusinessModel>(
                    value: _selectedBusiness,
                    isExpanded: true,
                    items: _businesses.map((business) {
                      return DropdownMenuItem(
                        value: business,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getSistemaColor(business.sistema),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(business.nombre),
                            ),
                            Text(
                              business.nit ?? 'N/A',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (business) {
                      if (business != null) {
                        setState(() {
                          _selectedBusiness = business;
                          _selectedEmployee = null;
                          _employees = [];
                        });
                        _loadEmployeesForBusiness(business.id!);
                      }
                    },
                  ),
                ],
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No hay negocios registrados',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Tabla de empleados
          if (_selectedBusiness != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Empleados del negocio: ${_selectedBusiness!.nombre}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEmployeesTable(),
                const SizedBox(height: 32),
                // Detalles del empleado seleccionado
                if (_selectedEmployee != null)
                  _buildEmployeeDetails(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeesTable() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_employees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'No hay empleados registrados en este negocio',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Documento')),
            DataColumn(label: Text('Cargo')),
            DataColumn(label: Text('Roles')),
            DataColumn(label: Text('Usuario')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: <DataRow>[
            for (var employee in _employees)
              DataRow(
                selected: _selectedEmployee?.id == employee.id,
                onSelectChanged: (selected) {
                  if (selected == true) {
                    setState(() => _selectedEmployee = employee);
                  }
                },
                cells: <DataCell>[
                  DataCell(Text(employee.nombre)),
                  DataCell(Text(employee.numeroDocumento ?? 'N/A')),
                  DataCell(Text(employee.cargo ?? 'N/A')),
                  DataCell(
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (employee.roles?.map((role) {
                        return Chip(
                          label: Text(
                            role.nombre,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.indigo[100],
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 0,
                          ),
                        );
                      }).toList()) ??
                        [],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (employee.tieneUsuarioSistema ?? false)
                            ? Colors.green[100]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (employee.tieneUsuarioSistema ?? false) ? 'Sí' : 'No',
                        style: TextStyle(
                          fontSize: 12,
                          color: (employee.tieneUsuarioSistema ?? false)
                              ? Colors.green[700]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: employee.estado ? Colors.blue[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        employee.estado ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 12,
                          color: employee.estado ? Colors.blue[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showEditEmployeeDialog(employee),
                          icon: const Icon(Icons.edit),
                          tooltip: 'Editar',
                          iconSize: 18,
                        ),
                        IconButton(
                          onPressed: () => _toggleEmployeeStatus(employee),
                          icon: Icon(
                            employee.estado ? Icons.block : Icons.check_circle,
                          ),
                          tooltip: employee.estado ? 'Desactivar' : 'Activar',
                          iconSize: 18,
                        ),
                        IconButton(
                          onPressed: () => _deleteEmployee(employee),
                          icon: const Icon(Icons.delete),
                          tooltip: 'Eliminar',
                          iconSize: 18,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.indigo[200]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.indigo[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detalles del Empleado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedEmployee = null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            children: [
              _buildDetailField('Nombre', _selectedEmployee!.nombre),
              _buildDetailField('Documento', _selectedEmployee!.numeroDocumento ?? 'N/A'),
              _buildDetailField('Email', _selectedEmployee!.email ?? 'N/A'),
              _buildDetailField('Teléfono', _selectedEmployee!.telefono ?? 'N/A'),
              _buildDetailField('Cargo', _selectedEmployee!.cargo ?? 'N/A'),
              _buildDetailField(
                'Estado',
                _selectedEmployee!.estado ? 'Activo' : 'Inactivo',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Future<void> _loadEmployeesForBusiness(int businessId) async {
    setState(() => _isLoading = true);
    try {
      final employees = await _employeeRepository.getEmployeesByBusiness(businessId);
      setState(() => _employees = employees);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) => _EmployeeFormDialog(
        onSubmit: (data) async {
          try {
            await _employeeRepository.createEmployee(
              businessId: _selectedBusiness!.id!,
              nombre: data['nombre'] as String,
              numeroDocumento: data['numeroDocumento'] as String?,
              email: data['email'] as String?,
              telefono: data['telefono'] as String?,
              cargo: data['cargo'] as String?,
              roleIds: (data['roleIds'] as List<int>?) ?? [],
            );
            if (mounted) {
              Navigator.pop(context);
              _loadEmployeesForBusiness(_selectedBusiness!.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Empleado creado exitosamente')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
        businessId: _selectedBusiness!.id!,
        businessName: _selectedBusiness!.nombre,
      ),
    );
  }

  void _showEditEmployeeDialog(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) => _EmployeeFormDialog(
        employee: employee,
        onSubmit: (data) async {
          try {
            await _employeeRepository.updateEmployee(
              employeeId: employee.id!,
              nombre: data['nombre'] as String,
              numeroDocumento: data['numeroDocumento'] as String?,
              email: data['email'] as String?,
              telefono: data['telefono'] as String?,
              cargo: data['cargo'] as String?,
            );
            
            // Actualizar roles
            final roleIds = data['roleIds'] as List<int>?;
            if (roleIds != null) {
              await _employeeRepository.updateEmployeeRoles(
                employeeId: employee.id!,
                newRoleIds: roleIds,
              );
            }
            
            if (mounted) {
              Navigator.pop(context);
              _loadEmployeesForBusiness(_selectedBusiness!.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Empleado actualizado exitosamente')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
        businessId: _selectedBusiness!.id!,
        businessName: _selectedBusiness!.nombre,
      ),
    );
  }

  Future<void> _toggleEmployeeStatus(EmployeeModel employee) async {
    try {
      await _employeeRepository.toggleEmployeeStatus(employee.id!, !employee.estado);
      _loadEmployeesForBusiness(_selectedBusiness!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Empleado ${employee.estado ? 'desactivado' : 'activado'} exitosamente',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteEmployee(EmployeeModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar al empleado ${employee.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _employeeRepository.toggleEmployeeStatus(employee.id!, false);
        _loadEmployeesForBusiness(_selectedBusiness!.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Empleado eliminado exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Widget _buildRolesSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Gestión de Roles',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Definir roles y permisos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesByRoleSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Módulos por Rol',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Asignar módulos a roles específicos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientesSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Gestión de Clientes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Ver y gestionar clientes globales',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracionSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Configuración',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Configurar datos del sistema',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Auditoría',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Ver historial de acciones',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/system_selection',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
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

// ============ DIALOGS ============

/// Dialog para crear/editar empleados con formulario de 3 pasos
class _EmployeeFormDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final int businessId;
  final String businessName;
  final EmployeeModel? employee;

  const _EmployeeFormDialog({
    required this.onSubmit,
    required this.businessId,
    required this.businessName,
    this.employee,
  });

  @override
  State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<_EmployeeFormDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nombreController;
  late TextEditingController _documentoController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _cargoController;
  late PageController _pageController;
  int _currentStep = 0;
  late EmployeeRepository _employeeRepository;
  List<RoleModel> _rolesDisponibles = [];
  Set<int> _rolesSeleccionados = {};
  bool _crearUsuarioSistema = false;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isLoadingRoles = false;

  @override
  void initState() {
    super.initState();
    _empleadoRepository = EmployeeRepository(client: Supabase.instance.client);
    _nombreController =
        TextEditingController(text: widget.employee?.nombre ?? '');
    _documentoController =
        TextEditingController(text: widget.employee?.numeroDocumento ?? '');
    _emailController =
        TextEditingController(text: widget.employee?.email ?? '');
    _telefonoController =
        TextEditingController(text: widget.employee?.telefono ?? '');
    _cargoController =
        TextEditingController(text: widget.employee?.cargo ?? '');
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _pageController = PageController();
    _crearUsuarioSistema = widget.employee?.tieneUsuarioSistema ?? false;
    _loadRoles();
  }

  late EmployeeRepository _empleadoRepository;

  @override
  void dispose() {
    _nombreController.dispose();
    _documentoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _cargoController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoadingRoles = true);
    try {
      final roles =
          await _empleadoRepository.getRolesByBusiness(widget.businessId);
      setState(() {
        _rolesDisponibles = roles;
        // Si es edición, cargar roles actuales
        if (widget.employee != null) {
          _rolesSeleccionados = widget.employee!.roleIds.toSet();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar roles: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingRoles = false);
    }
  }

  void _showCreateRoleDialog() {
    final roleNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Rol Rápido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: roleNameController,
              decoration: InputDecoration(
                labelText: 'Nombre del Rol',
                hintText: 'Ej: Administrador, Vendedor, Gerente',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Se creará un rol con acceso a todos los módulos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (roleNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor ingresa un nombre')),
                );
                return;
              }
              Navigator.pop(context);
              await _createQuickRole(roleNameController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear Rol'),
          ),
        ],
      ),
    );
  }

  Future<void> _createQuickRole(String roleName) async {
    try {
      // Crear rol con todos los módulos (1, 2, 3, 4)
      final newRole = await _empleadoRepository.createRole(
        businessId: widget.businessId,
        nombre: roleName,
        descripcion: 'Cuenta creada rápidamente',
        moduloIds: [1, 2, 3, 4], // Todos los módulos
      );
      
      // Recargar roles
      await _loadRoles();
      
      // Seleccionar el rol nuevo automáticamente
      if (newRole != null) {
        setState(() {
          _rolesSeleccionados.add(newRole.id!);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rol "$roleName" creado exitosamente')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear rol: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Encabezado
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigo[600],
                borderRadius:
                    const BorderRadius.only(topLeft: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.employee == null
                            ? 'Nuevo Empleado'
                            : 'Editar Empleado',
                        style:
                            const TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Negocio: ${widget.businessName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Indicador de pasos
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStepIndicator(0, 'Información'),
                  Container(
                    width: 60,
                    height: 2,
                    color:
                        _currentStep >= 1 ? Colors.indigo[600] : Colors.grey[300],
                  ),
                  _buildStepIndicator(1, 'Roles'),
                  if (!_crearUsuarioSistema)
                    Container(
                      width: 60,
                      height: 2,
                      color: Colors.grey[300],
                    ),
                  if (!_crearUsuarioSistema)
                    _buildStepIndicator(2, 'Confirmación', enabled: false),
                ],
              ),
            ),
            // Contenido del formulario
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentStep = index),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(), // Información básica
                  _buildStep2(), // Selección de roles
                ],
              ),
            ),
            // Botones de navegación
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    ElevatedButton(
                      onPressed: _goToPreviousStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Anterior'),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: _currentStep == 1 ? _submit : _goToNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[600],
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _currentStep == 1 ? 'Guardar' : 'Siguiente',
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

  Widget _buildStepIndicator(int step, String label, {bool enabled = true}) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.indigo[600] : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.indigo[600] : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información del Empleado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            _nombreController,
            'Nombre Completo',
            Icons.person,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _documentoController,
            'Número de Documento',
            Icons.badge,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _emailController,
            'Email (Opcional)',
            Icons.email,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _telefonoController,
            'Teléfono (Opcional)',
            Icons.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _cargoController,
            'Cargo',
            Icons.work,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asignar Roles',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona los roles que tendrá este empleado (opcional)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoadingRoles)
            const Center(child: CircularProgressIndicator())
          else if (_rolesDisponibles.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.orange[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay roles disponibles en este negocio',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showCreateRoleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Rol Rápido'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'O continúa sin asignar roles ahora',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _rolesDisponibles.map((role) {
                    final isSelected = _rolesSeleccionados.contains(role.id);
                    return FilterChip(
                      label: Text(role.nombre),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _rolesSeleccionados.add(role.id!);
                          } else {
                            _rolesSeleccionados.remove(role.id!);
                          }
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: Colors.indigo[100],
                      side: BorderSide(
                        color: isSelected ? Colors.indigo[600]! : Colors.grey[300]!,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _showCreateRoleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Nuevo Rol'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo[600],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  void _goToNextStep() {
    if (_currentStep == 0) {
      if (_nombreController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre del empleado es obligatorio')),
        );
        return;
      }
      if (_documentoController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El documento es obligatorio')),
        );
        return;
      }
    }
    if (_currentStep < 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    if (_rolesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe asignar al menos un rol')),
      );
      return;
    }

    try {
      final data = <String, dynamic>{
        'nombre': _nombreController.text,
        'numeroDocumento': _documentoController.text.isEmpty
            ? null
            : _documentoController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'telefono': _telefonoController.text.isEmpty
            ? null
            : _telefonoController.text,
        'cargo': _cargoController.text,
        'roleIds': _rolesSeleccionados.toList(),
      };

      widget.onSubmit(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _CreateBusinessDialog extends StatefulWidget {
  final BusinessRepository repository;
  final int adminId;
  final VoidCallback onBusinessCreated;

  const _CreateBusinessDialog({
    required this.repository,
    required this.adminId,
    required this.onBusinessCreated,
  });

  @override
  State<_CreateBusinessDialog> createState() => _CreateBusinessDialogState();
}

class _CreateBusinessDialogState extends State<_CreateBusinessDialog> {
  final _nameController = TextEditingController();
  final _nitController = TextEditingController();
  final _dateController = TextEditingController();
  late PageController _pageController;
  int _currentStep = 0;
  String _selectedSistema = 'Repuesto';

  List<ContactModel> _contactos = [];
  List<AddressModel> _direcciones = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nitController.dispose();
    _dateController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Nuevo Negocio'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de pasos
            Row(
              children: [
                _buildStepIndicator(0, 'Info'),
                const Spacer(),
                _buildStepIndicator(1, 'Contactos'),
                const Spacer(),
                _buildStepIndicator(2, 'Direcciones'),
              ],
            ),
            const SizedBox(height: 24),
            // Contenido del paso actual
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepInfo(),
                  _buildStepContactos(),
                  _buildStepDirecciones(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (_currentStep > 0)
          TextButton(
            onPressed: _goToPreviousStep,
            child: const Text('Anterior'),
          ),
        if (_currentStep < 2)
          ElevatedButton(
            onPressed: _validateAndGoNextStep,
            child: const Text('Siguiente'),
          )
        else
          ElevatedButton(
            onPressed: _createBusiness,
            child: const Text('Crear'),
          ),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              (step + 1).toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStepInfo() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del Negocio *',
              hintText: 'Ej: Mi Tienda',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nitController,
            decoration: const InputDecoration(
              labelText: 'NIT/Cédula',
              hintText: 'Ej: 123456789',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Fecha de Registro',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                _dateController.text =
                    DateFormat('dd/MM/yyyy').format(date);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSistema,
            decoration: const InputDecoration(
              labelText: 'Sistema a Utilizar *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: ['Repuesto', 'Prestamo', 'Inmuebles']
                .map((sistema) => DropdownMenuItem(
              value: sistema,
              child: Text(sistema),
            ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedSistema = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepContactos() {
    return Column(
      children: [
        Expanded(
          child: _contactos.isEmpty
              ? Center(
                child: Text(
                  'Sin contactos agregados',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
              : ListView.builder(
                itemCount: _contactos.length,
                itemBuilder: (context, index) {
                  final contact = _contactos[index];
                  return ListTile(
                    leading: Icon(
                      contact.tipo == 'telefono'
                          ? Icons.phone
                          : Icons.email,
                    ),
                    title: Text(contact.valor),
                    subtitle: contact.principal ? const Text('Principal') : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() => _contactos.removeAt(index));
                      },
                    ),
                  );
                },
              ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _showAddContactDialog,
          icon: const Icon(Icons.add),
          label: const Text('Agregar Contacto'),
        ),
        const SizedBox(height: 8),
        Text(
          'Al menos un contacto es obligatorio',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStepDirecciones() {
    return Column(
      children: [
        Expanded(
          child: _direcciones.isEmpty
              ? Center(
                child: Text(
                  'Sin direcciones agregadas',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
              : ListView.builder(
                itemCount: _direcciones.length,
                itemBuilder: (context, index) {
                  final address = _direcciones[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(address.calle),
                    subtitle: Text(
                      '${address.ciudad ?? ''} ${address.departamento ?? ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() => _direcciones.removeAt(index));
                      },
                    ),
                  );
                },
              ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _showAddAddressDialog,
          icon: const Icon(Icons.add),
          label: const Text('Agregar Dirección'),
        ),
        const SizedBox(height: 8),
        Text(
          'Al menos una dirección es obligatoria',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showAddContactDialog() {
    final typeController = TextEditingController();
    final valueController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Contacto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: 'telefono',
              items: const [
                DropdownMenuItem(
                  value: 'telefono',
                  child: Text('Teléfono'),
                ),
                DropdownMenuItem(
                  value: 'email',
                  child: Text('Email'),
                ),
              ],
              onChanged: (value) {
                if (value != null) typeController.text = value;
              },
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (valueController.text.isNotEmpty) {
                setState(() {
                  _contactos.add(ContactModel(
                    id: 0,
                    negocioId: 0,
                    tipo: typeController.text.isEmpty
                        ? 'telefono'
                        : typeController.text,
                    valor: valueController.text,
                    principal: _contactos.isEmpty,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog() {
    final calleController = TextEditingController();
    final ciudadController = TextEditingController();
    final departamentoController = TextEditingController();
    final codigoPostalController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Dirección'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: calleController,
                decoration: const InputDecoration(
                  labelText: 'Calle y Número *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ciudadController,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: departamentoController,
                decoration: const InputDecoration(
                  labelText: 'Departamento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codigoPostalController,
                decoration: const InputDecoration(
                  labelText: 'Código Postal',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (calleController.text.isNotEmpty) {
                setState(() {
                  _direcciones.add(AddressModel(
                    id: 0,
                    negocioId: 0,
                    tipo: 'principal',
                    calle: calleController.text,
                    ciudad: ciudadController.text.isEmpty
                        ? null
                        : ciudadController.text,
                    departamento: departamentoController.text.isEmpty
                        ? null
                        : departamentoController.text,
                    codigoPostal: codigoPostalController.text.isEmpty
                        ? null
                        : codigoPostalController.text,
                    principal: _direcciones.isEmpty,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _validateAndGoNextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre del negocio es obligatorio')),
        );
        return;
      }
      _goToNextStep();
    } else if (_currentStep == 1) {
      if (_contactos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Al menos un contacto es obligatorio')),
        );
        return;
      }
      _goToNextStep();
    }
  }

  void _goToNextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createBusiness() async {
    if (_direcciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Al menos una dirección es obligatoria')),
      );
      return;
    }

    try {
      final dateStr = _dateController.text;
      DateTime? fechaRegistro;
      if (dateStr.isNotEmpty) {
        fechaRegistro = DateFormat('dd/MM/yyyy').parse(dateStr);
      }

      await widget.repository.createBusiness(
        nombre: _nameController.text,
        nit: _nitController.text.isEmpty ? null : _nitController.text,
        fechaRegistro: fechaRegistro,
        adminId: widget.adminId,
        sistema: _selectedSistema,
        contactos: _contactos,
        direcciones: _direcciones,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Negocio creado correctamente')),
        );
        widget.onBusinessCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _EditBusinessDialog extends StatefulWidget {
  final BusinessModel business;
  final BusinessRepository repository;
  final VoidCallback onBusinessUpdated;

  const _EditBusinessDialog({
    required this.business,
    required this.repository,
    required this.onBusinessUpdated,
  });

  @override
  State<_EditBusinessDialog> createState() => _EditBusinessDialogState();
}

class _EditBusinessDialogState extends State<_EditBusinessDialog> {
  late TextEditingController _nameController;
  late TextEditingController _nitController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business.nombre);
    _nitController = TextEditingController(text: widget.business.nit ?? '');
    _dateController = TextEditingController(
      text: widget.business.fechaRegistro != null
          ? DateFormat('dd/MM/yyyy').format(widget.business.fechaRegistro!)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nitController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Negocio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Negocio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nitController,
              decoration: const InputDecoration(
                labelText: 'NIT/Cédula',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Fecha de Registro',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: widget.business.fechaRegistro ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _dateController.text = DateFormat('dd/MM/yyyy').format(date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _updateBusiness,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _updateBusiness() async {
    try {
      final dateStr = _dateController.text;
      DateTime? fechaRegistro;
      if (dateStr.isNotEmpty) {
        fechaRegistro = DateFormat('dd/MM/yyyy').parse(dateStr);
      }

      await widget.repository.updateBusiness(
        businessId: widget.business.id,
        nombre: _nameController.text,
        nit: _nitController.text.isEmpty ? null : _nitController.text,
        fechaRegistro: fechaRegistro,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Negocio actualizado correctamente')),
        );
        widget.onBusinessUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _ManageContactsDialog extends StatefulWidget {
  final BusinessModel business;
  final BusinessRepository repository;
  final VoidCallback onUpdated;

  const _ManageContactsDialog({
    required this.business,
    required this.repository,
    required this.onUpdated,
  });

  @override
  State<_ManageContactsDialog> createState() => _ManageContactsDialogState();
}

class _ManageContactsDialogState extends State<_ManageContactsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gestionar Contactos'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.business.contactos.length,
                itemBuilder: (context, index) {
                  final contact = widget.business.contactos[index];
                  return ListTile(
                    leading: Icon(
                      contact.tipo == 'telefono'
                          ? Icons.phone
                          : Icons.email,
                    ),
                    title: Text(contact.valor),
                    subtitle: contact.principal
                        ? const Text('Principal')
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteContact(contact),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Contacto'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  void _showAddContactDialog() {
    final typeController = TextEditingController(text: 'telefono');
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Contacto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: 'telefono',
              items: const [
                DropdownMenuItem(
                  value: 'telefono',
                  child: Text('Teléfono'),
                ),
                DropdownMenuItem(
                  value: 'email',
                  child: Text('Email'),
                ),
              ],
              onChanged: (value) {
                if (value != null) typeController.text = value;
              },
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _addContact(typeController.text, valueController.text),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _addContact(String tipo, String valor) async {
    if (valor.isEmpty) return;

    try {
      await widget.repository.addContact(
        businessId: widget.business.id,
        tipo: tipo,
        valor: valor,
        principal: widget.business.contactos.isEmpty,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteContact(ContactModel contact) async {
    try {
      await widget.repository.deleteContact(contact.id);
      widget.onUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _ManageAddressesDialog extends StatefulWidget {
  final BusinessModel business;
  final BusinessRepository repository;
  final VoidCallback onUpdated;

  const _ManageAddressesDialog({
    required this.business,
    required this.repository,
    required this.onUpdated,
  });

  @override
  State<_ManageAddressesDialog> createState() => _ManageAddressesDialogState();
}

class _ManageAddressesDialogState extends State<_ManageAddressesDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gestionar Direcciones'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.business.direcciones.length,
                itemBuilder: (context, index) {
                  final address = widget.business.direcciones[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(address.calle),
                    subtitle: Text(
                      '${address.ciudad ?? ''} ${address.departamento ?? ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteAddress(address),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddAddressDialog,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Dirección'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  void _showAddAddressDialog() {
    final calleController = TextEditingController();
    final ciudadController = TextEditingController();
    final departamentoController = TextEditingController();
    final codigoPostalController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Dirección'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: calleController,
                decoration: const InputDecoration(
                  labelText: 'Calle y Número',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ciudadController,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: departamentoController,
                decoration: const InputDecoration(
                  labelText: 'Departamento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codigoPostalController,
                decoration: const InputDecoration(
                  labelText: 'Código Postal',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _addAddress(
              calleController.text,
              ciudadController.text,
              departamentoController.text,
              codigoPostalController.text,
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAddress(
    String calle,
    String ciudad,
    String departamento,
    String codigoPostal,
  ) async {
    if (calle.isEmpty) return;

    try {
      await widget.repository.addAddress(
        businessId: widget.business.id,
        tipo: 'sucursal',
        calle: calle,
        ciudad: ciudad.isEmpty ? null : ciudad,
        departamento: departamento.isEmpty ? null : departamento,
        codigoPostal: codigoPostal.isEmpty ? null : codigoPostal,
        principal: widget.business.direcciones.isEmpty,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    try {
      await widget.repository.deleteAddress(address.id);
      widget.onUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
