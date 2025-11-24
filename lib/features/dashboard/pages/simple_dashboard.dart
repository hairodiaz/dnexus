import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../employees/pages/employees_page_basic.dart';
import '../../clients/pages/clients_page.dart';
import '../../inventory/pages/inventory_page.dart';

/// Dashboard simple de D-Nexus para presentación
class SimpleDashboard extends StatelessWidget {
  final UserModel user;

  const SimpleDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D-Nexus Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Text(
                  user.role == 'super_admin' ? 'Super Admin' : 'Admin',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de bienvenida
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.business, size: 32, color: Colors.blue),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Bienvenido, ${user.role == 'super_admin' ? 'Super Administrador' : user.fullName ?? 'Usuario'}!',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Sistema de Gestión Multi-Negocios',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Título de módulos
            const Text(
              'Módulos Disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 16),
            
            // Grid de módulos
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Transacciones
                  _buildModuleCard(
                    context,
                    'Transacciones',
                    'Ingresos, Egresos y Control de Caja',
                    Icons.account_balance_wallet,
                    Colors.green,
                    () => _showComingSoon(context, 'Transacciones'),
                  ),
                  
                  // Reportes Consolidados
                  _buildModuleCard(
                    context,
                    'Reportes Consolidados',
                    'Vista global de Todos los Negocios',
                    Icons.assessment,
                    Colors.purple,
                    () => _showComingSoon(context, 'Reportes Consolidados'),
                  ),
                  
                  // Reportes
                  _buildModuleCard(
                    context,
                    'Reportes',
                    'Análisis y Estadísticas',
                    Icons.bar_chart,
                    Colors.blue,
                    () => _showComingSoon(context, 'Reportes'),
                  ),
                  
                  // Dashboard
                  _buildModuleCard(
                    context,
                    'Dashboard',
                    'Panel de Control',
                    Icons.dashboard,
                    Colors.purple[300]!,
                    () => _showComingSoon(context, 'Dashboard'),
                  ),
                  
                  // Inventario
                  _buildModuleCard(
                    context,
                    'Inventario',
                    'Gestión de Stock',
                    Icons.inventory,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InventoryPage(
                          user: user,
                          businessId: 1,
                        ),
                      ),
                    ),
                  ),
                  
                  // Clientes
                  _buildModuleCard(
                    context,
                    'Clientes',
                    'Base de Clientes',
                    Icons.people,
                    Colors.teal,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClientsPage(),
                      ),
                    ),
                  ),
                  
                  // Empleados - SOLO para admin y super_admin
                  if (user.role == 'admin' || user.role == 'super_admin')
                    _buildModuleCard(
                      context,
                      'Empleados',
                      'Gestión de Personal',
                      Icons.badge,
                      Colors.teal,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeesPageBasic(currentUser: user),
                        ),
                      ),
                    ),
                  
                  // Configuración - SOLO para admin y super_admin
                  if (user.role == 'admin' || user.role == 'super_admin')
                    _buildModuleCard(
                      context,
                      'Configuración',
                      'Ajustes del Sistema',
                      Icons.settings,
                      Colors.grey,
                      () => _showComingSoon(context, 'Configuración'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Módulo de $module en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}