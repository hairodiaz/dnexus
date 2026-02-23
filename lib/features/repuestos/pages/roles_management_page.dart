import 'package:flutter/material.dart';

/// DEPRECATED PAGE - This page uses an old role and permission model that is no longer supported
/// 
/// The current architecture uses modulo-based access control instead of granular permissions.
/// For role management, please use the admin dashboard (AdminDashboardPage) which has
/// role assignment functionality for employees.
///
/// TODO: Implement new role management UI based on current architecture
/// 
/// Status: Non-functional placeholder
class RolesManagementPage extends StatefulWidget {
  const RolesManagementPage({super.key});

  @override
  State<RolesManagementPage> createState() => _RolesManagementPageState();
}

class _RolesManagementPageState extends State<RolesManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Roles (DEPRECATED)'),
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
                'Esta página usa un modelo de permisos que ya no es compatible.\n\nUsa AdminDashboard para gestionar roles de empleados.\n\nEsta página será removida en una futura versión.',
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


