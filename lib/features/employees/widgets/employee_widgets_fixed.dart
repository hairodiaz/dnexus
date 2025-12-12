import 'package:flutter/material.dart';
import '../../../shared/models/employee_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/permission_widgets.dart';

/// Card para mostrar información de un empleado
class EmployeeCard extends StatelessWidget {
  final EmployeeModel employee;
  final UserModel currentUser;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.currentUser,
    this.onEdit,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: employee.isActive 
              ? Colors.transparent 
              : Colors.grey.withOpacity(0.3),
          width: employee.isActive ? 0 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: employee.isActive 
              ? null 
              : Colors.grey.withOpacity(0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con nombre y estado
              Row(
                children: [
                  // Avatar con inicial
                  CircleAvatar(
                    backgroundColor: Color(employee.roleColor),
                    radius: 24,
                    child: Text(
                      employee.fullName.isNotEmpty 
                          ? employee.fullName[0].toUpperCase()
                          : 'E',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Nombre y rol
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(employee.roleColor).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(employee.roleColor).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            employee.roleDisplayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(employee.roleColor),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Estado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: employee.isActive 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: employee.isActive 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
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
              
              // Información del empleado
              _buildInfoSection(),
              
              const SizedBox(height: 12),
              
              // Botones de acción
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                Icons.badge,
                'Cédula',
                employee.cedula,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                Icons.phone,
                'Teléfono',
                employee.phone ?? 'No registrado',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                Icons.calendar_today,
                'Ingreso',
                '${employee.hireDate.day}/${employee.hireDate.month}/${employee.hireDate.year}',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                Icons.access_time,
                'Antigüedad',
                employee.workTimeFormatted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                Icons.attach_money,
                'Salario Base',
                employee.salaryFormatted,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                Icons.email,
                'Email',
                employee.email ?? 'No registrado',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botón de cambiar estado
        PermissionWidget(
          user: currentUser,
          allowedRoles: [UserRole.superAdmin, UserRole.admin],
          child: _buildActionButton(
            context,
            employee.isActive ? Icons.pause_circle : Icons.play_circle,
            employee.isActive ? 'Desactivar' : 'Activar',
            employee.isActive ? Colors.orange : Colors.green,
            onToggleStatus,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Botón de editar
        PermissionWidget(
          user: currentUser,
          allowedRoles: [UserRole.superAdmin, UserRole.admin],
          child: _buildActionButton(
            context,
            Icons.edit,
            'Editar',
            Colors.blue,
            onEdit,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback? onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        tooltip: tooltip,
        iconSize: 20,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}

/// Diálogo para mostrar estadísticas de empleados
class EmployeeStatsDialog extends StatelessWidget {
  final Map<String, dynamic> stats;

  const EmployeeStatsDialog({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final roleStats = stats['byRole'] as Map<UserRole, int>;
    
    return AlertDialog(
      title: const Text('Estadísticas de Empleados'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estadísticas generales
            _buildStatRow('Total de empleados', stats['total'].toString()),
            _buildStatRow('Empleados activos', stats['active'].toString()),
            _buildStatRow('Empleados inactivos', stats['inactive'].toString()),
            
            const Divider(height: 24),
            
            const Text(
              'Nómina',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Nómina total mensual',
              '\$${(stats['totalPayroll'] as double).toStringAsFixed(0).replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              )}',
            ),
            _buildStatRow(
              'Salario promedio',
              '\$${(stats['averageSalary'] as double).toStringAsFixed(0).replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              )}',
            ),
            
            const Divider(height: 24),
            
            const Text(
              'Por Rol',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            
            // Estadísticas por rol
            ...roleStats.entries.where((e) => e.value > 0).map((entry) => 
              _buildStatRow(_getRoleDisplayName(entry.key), entry.value.toString())
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Administradores';
      case UserRole.admin:
        return 'Administradores';
      case UserRole.caja:
        return 'Cajeros';
      case UserRole.facturador:
        return 'Facturadores';
      case UserRole.vendedor:
        return 'Vendedores';
    }
  }
}