import 'package:flutter/material.dart';
import '../../../shared/models/employee_model.dart';
import '../../../shared/models/user_model.dart';

/// Card simple para mostrar información de un empleado
class EmployeeCard extends StatelessWidget {
  final EmployeeModel employee;
  final UserModel currentUser;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;

  const EmployeeCard({
    Key? key,
    required this.employee,
    required this.currentUser,
    this.onEdit,
    this.onToggleStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(employee.roleColor),
                  child: Text(
                    employee.fullName.isNotEmpty 
                        ? employee.fullName[0].toUpperCase()
                        : 'E',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        employee.roleDisplayName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
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
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Información
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Cédula', employee.cedula),
                ),
                Expanded(
                  child: _buildInfoItem('Teléfono', employee.phone ?? 'No registrado'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Ingreso', '${employee.hireDate.day}/${employee.hireDate.month}/${employee.hireDate.year}'),
                ),
                Expanded(
                  child: _buildInfoItem('Salario', employee.salaryFormatted),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Botones de acción
            if (_canEdit())
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onToggleStatus,
                    icon: Icon(
                      employee.isActive ? Icons.pause_circle : Icons.play_circle,
                      color: employee.isActive ? Colors.orange : Colors.green,
                    ),
                    tooltip: employee.isActive ? 'Desactivar' : 'Activar',
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Editar',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  bool _canEdit() {
    return currentUser.role == 'super_admin' || 
           currentUser.role == 'admin';
  }
}

/// Diálogo simple de estadísticas
class EmployeeStatsDialog extends StatelessWidget {
  final Map<String, dynamic> stats;

  const EmployeeStatsDialog({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Estadísticas de Empleados'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatRow('Total', stats['total'].toString()),
          _buildStatRow('Activos', stats['active'].toString()),
          _buildStatRow('Inactivos', stats['inactive'].toString()),
          const Divider(),
          _buildStatRow('Nómina Total', '\$${(stats['totalPayroll'] / 1000000).toStringAsFixed(1)}M'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
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
}