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

  @override
  void initState() {
    super.initState();
  }
}
              children: [
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Contraseña inicial: Abc123',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Asignar Roles:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._roles.map((role) {
                  return CheckboxListTile(
                    title: Text(role.nombre),
                    value: selectedRoles.contains(role.id),
                    onChanged: (value) {
                      setStateDialog(() {
                        if (value ?? false) {
                          selectedRoles.add(role.id);
                        } else {
                          selectedRoles.remove(role.id);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (usernameController.text.isEmpty || nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa todos los campos')),
                  );
                  return;
                }

                try {
                  final supabase = Supabase.instance.client;
                  const defaultPassword = 'Abc123';
                  final hashedPassword = sha256.convert(defaultPassword.codeUnits).toString();

                  // Crear usuario
                  final userResponse = await supabase
                      .from('users')
                      .insert({
                        'username': usernameController.text,
                        'password': hashedPassword,
                        'nombre_completo': nameController.text,
                        'rol': 'admin_negocio',
                        'email': '${usernameController.text}@repuestos.local',
                        'activo': true,
                      })
                      .select();

                  final userId = userResponse[0]['id'] as int;

                  // Asignar roles
                  for (var roleId in selectedRoles) {
                    await RoleService.assignRoleToUser(
                      userId: userId,
                      roleId: roleId,
                    );
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Usuario "${usernameController.text}" creado con ${selectedRoles.length} rol(es)',
                        ),
                      ),
                    );
                    await _loadUsers();
                  }
                } catch (e) {
                  AppConfig.logger.e('Error creating user: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editUserRoles(Map<String, dynamic> user) async {
    final userId = user['id'] as int;
    final userName = user['nombre_completo'] as String;
    final currentRoles = (user['roles'] as List<RoleModel>?)?.map((r) => r.id).toSet() ?? <int>{};
    final selectedRoles = Set<int>.from(currentRoles);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Roles: $userName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _roles.map((role) {
                return CheckboxListTile(
                  title: Text(role.nombre),
                  subtitle: Text(role.descripcion ?? ''),
                  value: selectedRoles.contains(role.id),
                  onChanged: (value) {
                    setStateDialog(() {
                      if (value ?? false) {
                        selectedRoles.add(role.id);
                      } else {
                        selectedRoles.remove(role.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Remover roles que ya no están seleccionados
                  for (var roleId in currentRoles) {
                    if (!selectedRoles.contains(roleId)) {
                      await RoleService.removeRoleFromUser(
                        userId: userId,
                        roleId: roleId,
                      );
                    }
                  }

                  // Agregar nuevos roles
                  for (var roleId in selectedRoles) {
                    if (!currentRoles.contains(roleId)) {
                      await RoleService.assignRoleToUser(
                        userId: userId,
                        roleId: roleId,
                      );
                    }
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Roles actualizados')),
                    );
                    await _loadUsers();
                  }
                } catch (e) {
                  AppConfig.logger.e('Error updating user roles: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios del Sistema'),
        backgroundColor: const Color(0xFFFF8C00),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: _createUser,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Nuevo Usuario'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C00),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _users.isEmpty
                          ? const Center(
                              child: Text('No hay usuarios del sistema'),
                            )
                          : ListView.builder(
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                final roles = (user['roles'] as List<RoleModel>?) ?? [];
                                
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    title: Text(user['nombre_completo'] as String),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Usuario: ${user['username']}'),
                                        const SizedBox(height: 4),
                                        if (roles.isNotEmpty)
                                          Wrap(
                                            spacing: 4,
                                            children: roles
                                                .map((r) => Chip(
                                                      label: Text(r.nombre),
                                                      backgroundColor: const Color(0xFFFF8C00).withOpacity(0.3),
                                                    ))
                                                .toList(),
                                          )
                                        else
                                          const Text('Sin roles asignados'),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Editar Roles',
                                      onPressed: () => _editUserRoles(user),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: const Color(0xFFFF8C00),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
