import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';

/// Dashboard del Empleado - Panel de acceso a módulos
class EmployeeDashboardPage extends StatefulWidget {
  final UserModel currentUser;

  const EmployeeDashboardPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D-NEXUS - Dashboard Empleado'),
        backgroundColor: Colors.teal[700],
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.currentUser.fullName ?? widget.currentUser.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Empleado',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton(
            color: Colors.white,
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 12),
                    Text('Cerrar Sesión'),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pushReplacementNamed('/system_selection');
                },
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${widget.currentUser.fullName ?? widget.currentUser.username}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Módulos disponibles para este rol',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            // Grid de módulos disponibles
            GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildModuleCard(
                  title: 'Cash Register',
                  icon: Icons.point_of_sale,
                  color: Colors.blue,
                  onTap: () => _navigateToModule('cash_register'),
                ),
                _buildModuleCard(
                  title: 'Inventario',
                  icon: Icons.inventory_2,
                  color: Colors.green,
                  onTap: () => _navigateToModule('inventario'),
                ),
                _buildModuleCard(
                  title: 'Facturas',
                  icon: Icons.receipt,
                  color: Colors.orange,
                  onTap: () => _navigateToModule('facturas'),
                ),
                _buildModuleCard(
                  title: 'Empleados',
                  icon: Icons.people,
                  color: Colors.purple,
                  onTap: () => _navigateToModule('empleados'),
                ),
                _buildModuleCard(
                  title: 'Contabilidad',
                  icon: Icons.calculate,
                  color: Colors.red,
                  onTap: () => _navigateToModule('contabilidad'),
                ),
                _buildModuleCard(
                  title: 'Reportes',
                  icon: Icons.bar_chart,
                  color: Colors.indigo,
                  onTap: () => _navigateToModule('reportes'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Información del negocio
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información de tu Negocio',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Negocio:', 'Por asignar'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Rol:', 'Empleado'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Email:', widget.currentUser.email ?? 'No especificado'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 40,
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToModule(String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo módulo: $moduleName'),
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Implementar navegación a módulos específicos
  }
}
