import 'package:flutter/material.dart';
import '../../../shared/models/employee_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/services/employee_service.dart';

/// Página básica de empleados - versión simple que funciona
class EmployeesPageBasic extends StatefulWidget {
  final UserModel currentUser;

  const EmployeesPageBasic({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<EmployeesPageBasic> createState() => _EmployeesPageBasicState();
}

class _EmployeesPageBasicState extends State<EmployeesPageBasic> {
  List<EmployeeModel> employees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  void _loadEmployees() {
    setState(() {
      isLoading = true;
    });

    // Cargar empleados según permisos del usuario
    if (widget.currentUser.role == 'SuperAdmin') {
      employees = EmployeeService.getAllEmployees();
    } else {
      // Admin y otros roles solo ven empleados de su negocio
      employees = EmployeeService.getEmployeesByBusiness(
        'business_ferreteria' // Por ahora fijo, después se puede hacer dinámico
      );
    }
    
    setState(() {
      isLoading = false;
    });
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
          // Estadísticas
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showStatsDialog(stats),
          ),
          // Agregar (solo admins)
          if (_canManageEmployees())
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddDialog(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Stats rápidos
          _buildQuickStats(stats),
          
          // Lista de empleados
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : employees.isEmpty
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

  Widget _buildEmployeesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Color(employee.roleColor),
              child: Text(
                employee.fullName.isNotEmpty 
                    ? employee.fullName[0].toUpperCase()
                    : 'E',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              employee.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.roleDisplayName),
                Text('Cédula: ${employee.cedula}'),
                Text('Salario: ${employee.salaryFormatted}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: employee.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                employee.statusDisplay,
                style: TextStyle(
                  fontSize: 12,
                  color: employee.isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: () => _showEmployeeDetails(employee),
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
            'Agrega el primer empleado para comenzar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          if (_canManageEmployees()) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Empleado'),
            ),
          ],
        ],
      ),
    );
  }

  void _showEmployeeDetails(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(employee.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cédula: ${employee.cedula}'),
            Text('Rol: ${employee.roleDisplayName}'),
            Text('Teléfono: ${employee.phone ?? 'No registrado'}'),
            Text('Email: ${employee.email ?? 'No registrado'}'),
            Text('Fecha ingreso: ${employee.hireDate.day}/${employee.hireDate.month}/${employee.hireDate.year}'),
            Text('Antigüedad: ${employee.workTimeFormatted}'),
            Text('Salario: ${employee.salaryFormatted}'),
            Text('Estado: ${employee.statusDisplay}'),
            if (employee.notes != null) Text('Notas: ${employee.notes}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog(Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Empleados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total de empleados', stats['total'].toString()),
            _buildStatRow('Empleados activos', stats['active'].toString()),
            _buildStatRow('Empleados inactivos', stats['inactive'].toString()),
            const Divider(height: 24),
            _buildStatRow('Nómina total', '\$${(stats['totalPayroll'] / 1000000).toStringAsFixed(1)}M'),
            _buildStatRow('Salario promedio', '\$${(stats['averageSalary'] / 1000).toStringAsFixed(0)}K'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de agregar empleado disponible próximamente'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  bool _canManageEmployees() {
    return widget.currentUser.role == 'SuperAdmin' || 
           widget.currentUser.role == 'Admin';
  }
}