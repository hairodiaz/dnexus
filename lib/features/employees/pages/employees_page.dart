import 'package:flutter/material.dart';
import '../../../shared/models/employee_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/services/employee_service.dart';
import '../../../shared/widgets/permission_widgets.dart';
import '../widgets/employee_widgets_simple.dart';
import '../widgets/employee_dialogs.dart';

/// Página principal para gestión de empleados
class EmployeesPage extends StatefulWidget {
  final UserModel currentUser;

  const EmployeesPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  List<EmployeeModel> employees = [];
  List<EmployeeModel> filteredEmployees = [];
  final searchController = TextEditingController();
  
  EmployeeFilter selectedFilter = EmployeeFilter.all;
  UserRole? selectedRole;
  EmployeeSortBy sortBy = EmployeeSortBy.name;
  bool sortAscending = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _loadEmployees() {
    setState(() {
      isLoading = true;
    });

    // Cargar empleados según permisos del usuario
    if (widget.currentUser.userRole == UserRole.superAdmin) {
      employees = EmployeeService.getAllEmployees();
    } else {
      // Admin y otros roles solo ven empleados de su negocio
      employees = EmployeeService.getEmployeesByBusiness(
        widget.currentUser.businessId ?? 'business_ferreteria'
      );
    }

    _applyFilters();
    
    setState(() {
      isLoading = false;
    });
  }

  void _applyFilters() {
    var results = EmployeeService.filterEmployees(
      filter: selectedFilter,
      filterRole: selectedRole,
      businessId: widget.currentUser.userRole == UserRole.superAdmin 
          ? null 
          : widget.currentUser.businessId,
    );

    // Aplicar búsqueda
    if (searchController.text.isNotEmpty) {
      results = EmployeeService.searchEmployees(
        searchController.text,
        widget.currentUser.userRole == UserRole.superAdmin 
            ? null 
            : widget.currentUser.businessId,
      );
    }

    // Aplicar ordenamiento
    results = EmployeeService.sortEmployees(
      results,
      sortBy,
      ascending: sortAscending,
    );

    setState(() {
      filteredEmployees = results;
    });
  }

  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEmployeeDialog(
        currentUser: widget.currentUser,
        onEmployeeAdded: (employee) {
          _loadEmployees();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Empleado ${employee.fullName} agregado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showEditEmployeeDialog(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) => EditEmployeeDialog(
        employee: employee,
        currentUser: widget.currentUser,
        onEmployeeUpdated: (updatedEmployee) {
          _loadEmployees();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Empleado ${updatedEmployee.fullName} actualizado exitosamente'),
              backgroundColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  void _toggleEmployeeStatus(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${employee.isActive ? 'Desactivar' : 'Activar'} Empleado'),
        content: Text(
          '¿Estás seguro de que quieres ${employee.isActive ? 'desactivar' : 'activar'} a ${employee.fullName}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (EmployeeService.toggleEmployeeStatus(employee.id)) {
                _loadEmployees();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Empleado ${employee.isActive ? 'desactivado' : 'activado'} exitosamente'
                    ),
                    backgroundColor: employee.isActive ? Colors.orange : Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: employee.isActive ? Colors.orange : Colors.green,
            ),
            child: Text(employee.isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = EmployeeService.getEmployeeStats(
      widget.currentUser.userRole == UserRole.superAdmin 
          ? null 
          : widget.currentUser.businessId
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleados'),
        elevation: 0,
        actions: [
          // Botón de estadísticas
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatsDialog(stats),
          ),
          // Botón de agregar (solo admins)
          PermissionWidget(
            user: widget.currentUser,
            allowedRoles: [UserRole.superAdmin, UserRole.admin],
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddEmployeeDialog,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Estadísticas rápidas
          _buildQuickStats(stats),
          
          // Filtros y búsqueda
          _buildFiltersSection(),
          
          // Lista de empleados
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredEmployees.isEmpty
                    ? _buildEmptyState()
                    : _buildEmployeesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              stats['total'].toString(),
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Activos',
              stats['active'].toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Nómina',
              '\$${(stats['totalPayroll'] / 1000000).toStringAsFixed(1)}M',
              Icons.attach_money,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Búsqueda
          TextField(
            controller: searchController,
            onChanged: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o cédula...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Filtro por estado
                _buildFilterChip(
                  'Todos',
                  selectedFilter == EmployeeFilter.all,
                  () => setState(() {
                    selectedFilter = EmployeeFilter.all;
                    selectedRole = null;
                    _applyFilters();
                  }),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Activos',
                  selectedFilter == EmployeeFilter.active,
                  () => setState(() {
                    selectedFilter = EmployeeFilter.active;
                    selectedRole = null;
                    _applyFilters();
                  }),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Inactivos',
                  selectedFilter == EmployeeFilter.inactive,
                  () => setState(() {
                    selectedFilter = EmployeeFilter.inactive;
                    selectedRole = null;
                    _applyFilters();
                  }),
                ),
                const SizedBox(width: 16),
                
                // Filtros por rol
                ...UserRole.values.map((role) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    _getRoleDisplayName(role),
                    selectedRole == role,
                    () => setState(() {
                      selectedFilter = EmployeeFilter.byRole;
                      selectedRole = selectedRole == role ? null : role;
                      _applyFilters();
                    }),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[700],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = filteredEmployees[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EmployeeCard(
            employee: employee,
            currentUser: widget.currentUser,
            onEdit: () => _showEditEmployeeDialog(employee),
            onToggleStatus: () => _toggleEmployeeStatus(employee),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay empleados',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchController.text.isNotEmpty
                ? 'No se encontraron resultados para "${searchController.text}"'
                : 'Agrega el primer empleado para comenzar',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          PermissionWidget(
            user: widget.currentUser,
            allowedRoles: [UserRole.superAdmin, UserRole.admin],
            child: ElevatedButton.icon(
              onPressed: _showAddEmployeeDialog,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Empleado'),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog(Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => EmployeeStatsDialog(stats: stats),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.caja:
        return 'Caja';
      case UserRole.facturador:
        return 'Facturador';
      case UserRole.vendedor:
        return 'Vendedor';
    }
  }
}