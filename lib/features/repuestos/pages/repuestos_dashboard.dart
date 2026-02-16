import 'package:flutter/material.dart';
import 'roles_management_page.dart';
import 'users_management_page.dart';

class RepuestosDashboard extends StatefulWidget {
  const RepuestosDashboard({super.key});

  @override
  State<RepuestosDashboard> createState() => _RepuestosDashboardState();
}

class _RepuestosDashboardState extends State<RepuestosDashboard> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        title: const Text(
          'Sistema de Repuestos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              text: 'Gestión de Roles',
              icon: Icon(Icons.security),
            ),
            Tab(
              text: 'Gestión de Usuarios',
              icon: Icon(Icons.people),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RolesManagementPage(),
          UsersManagementPage(),
        ],
      ),
    );
  }
}
