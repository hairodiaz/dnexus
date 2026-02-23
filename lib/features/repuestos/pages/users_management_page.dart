import 'package:flutter/material.dart';

/// DEPRECATED PAGE - This page uses an old user and role model that is no longer supported
/// 
/// The current architecture focuses on employee management with role assignment at the employee level
/// rather than separate user/role management. 
/// For user management, please use the admin dashboard (AdminDashboardPage).
///
/// TODO: Implement new user management UI based on current architecture if needed
/// 
/// Status: Non-functional placeholder
class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios (DEPRECATED)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Página Deprecada',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Esta página usa un modelo de usuarios que ya no es compatible.\n\nUsa AdminDashboard para gestionar empleados y permisos.\n\nEsta página será removida en una futura versión.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
