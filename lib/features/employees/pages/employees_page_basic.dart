import 'package:flutter/material.dart';
import '../../../shared/models/employee_model.dart';
import '../../../shared/models/user_model.dart';
import 'employee_form_simple.dart';

/// Página básica de empleados - versión simple que funciona
/// NOTA: Esta es una versión legacy. Para producción, usar admin_dashboard_page.dart
class EmployeesPageBasic extends StatefulWidget {
  final UserModel currentUser;

  const EmployeesPageBasic({
    super.key,
    required this.currentUser,
  });

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
    // NOTA: Esta es una versión placeholder. La carga actual está deprecada.
    // Los empleados deberían cargarse desde EmployeeRepository
    setState(() {
      isLoading = false;
      employees = []; // Lista vacía hasta implementar EmployeeRepository
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleados'),
        elevation: 0,
        actions: [
          // Agregar (solo admins)
          if (_canManageEmployees())
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddDialog(),
            ),
        ],
      ),
      body: Expanded(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : employees.isEmpty
                ? _buildEmptyState()
                : _buildEmployeesList(),
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
              backgroundColor: Colors.blueAccent,
              child: Text(
                employee.nombre.isNotEmpty 
                    ? employee.nombre[0].toUpperCase()
                    : 'E',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              employee.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (employee.cargo != null) Text(employee.cargo!),
                if (employee.numeroDocumento != null) Text('Cédula: ${employee.numeroDocumento!}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: employee.estado ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                employee.estado ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: 12,
                  color: employee.estado ? Colors.green : Colors.red,
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
        title: Text(employee.nombre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (employee.numeroDocumento != null) 
              Text('Cédula: ${employee.numeroDocumento!}'),
            if (employee.cargo != null) 
              Text('Cargo: ${employee.cargo!}'),
            if (employee.telefono != null) 
              Text('Teléfono: ${employee.telefono!}'),
            if (employee.email != null) 
              Text('Email: ${employee.email!}'),
            Text('Creado: ${employee.createdAt.day}/${employee.createdAt.month}/${employee.createdAt.year}'),
            Text('Estado: ${employee.estado ? "Activo" : "Inactivo"}'),
            if (employee.roles.isNotEmpty)
              Text('Roles: ${employee.roles.map((r) => r.nombre).join(", ")}'),
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

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estadísticas de Empleados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total de empleados', employees.length.toString()),
            _buildStatRow('Empleados activos', employees.where((e) => e.estado).length.toString()),
            _buildStatRow('Empleados inactivos', employees.where((e) => !e.estado).length.toString()),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeFormPage(
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  bool _canManageEmployees() {
    return widget.currentUser.role == 'super_admin' || 
           widget.currentUser.role == 'admin';
  }
}