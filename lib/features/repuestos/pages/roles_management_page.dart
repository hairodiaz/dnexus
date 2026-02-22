import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/role_model.dart';
import '../../../shared/models/permission_model.dart';
import '../../../shared/services/role_service.dart';
import '../../../core/config/app_config.dart';

/// Panel de Gestión de Roles para Repuestos
class RolesManagementPage extends StatefulWidget {
  const RolesManagementPage({super.key});

  @override
  State<RolesManagementPage> createState() => _RolesManagementPageState();
}

class _RolesManagementPageState extends State<RolesManagementPage> {
  List<RoleModel> _roles = [];
  Map<String, List<PermissionModel>> _permissionsByModule = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadRoles(),
        _loadPermissions(),
      ]);
    } catch (e) {
      AppConfig.logger.e('Error loading data: $e');
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await RoleService.getAllRoles();
      setState(() {
        _roles = roles;
      });
    } catch (e) {
      AppConfig.logger.e('Error loading roles: $e');
    }
  }

  Future<void> _loadPermissions() async {
    try {
      final permissions = await RoleService.getPermissionsByModule();
      setState(() {
        _permissionsByModule = permissions;
      });
    } catch (e) {
      AppConfig.logger.e('Error loading permissions: $e');
    }
  }

  Future<void> _createRole() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Rol'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Rol',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
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
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa el nombre del rol')),
                );
                return;
              }

              final role = await RoleService.createRole(
                nombre: nameController.text,
                descripcion: descController.text.isEmpty ? null : descController.text,
              );

              if (mounted) {
                Navigator.pop(context);
                if (role != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rol "${role.nombre}" creado exitosamente')),
                  );
                  await _loadRoles();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al crear el rol')),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _editRolePermissions(RoleModel role) async {
    final selectedPermissions = <int>{};
    final rolePermissions = await RoleService.getRoleWithPermissions(role.id);

    // Obtener IDs de permisos del rol
    if (rolePermissions != null) {
      final allPermissions = await RoleService.getAllPermissions();
      for (var perm in allPermissions) {
        if (rolePermissions.permissionNames.contains(perm.nombre)) {
          selectedPermissions.add(perm.id);
        }
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Permisos: ${role.nombre}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _permissionsByModule.entries.map((entry) {
                final modulo = entry.key;
                final permisos = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modulo.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...permisos.map((perm) {
                      return CheckboxListTile(
                        title: Text(perm.nombre),
                        subtitle: Text(perm.descripcion ?? ''),
                        value: selectedPermissions.contains(perm.id),
                        onChanged: (value) {
                          setStateDialog(() {
                            if (value ?? false) {
                              selectedPermissions.add(perm.id);
                            } else {
                              selectedPermissions.remove(perm.id);
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
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
                final success = await RoleService.assignPermissionsToRole(
                  roleId: role.id,
                  permissionIds: selectedPermissions.toList(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Permisos asignados exitosamente')),
                    );
                    await _loadRoles();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al asignar permisos')),
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

  Future<void> _deleteRole(RoleModel role) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rol'),
        content: Text('¿Estás seguro de que deseas eliminar el rol "${role.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await RoleService.deleteRole(role.id);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rol "${role.nombre}" eliminado')),
                  );
                  await _loadRoles();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al eliminar el rol')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Roles'),
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
                        onPressed: _createRole,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Nuevo Rol'),
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
                      child: _roles.isEmpty
                          ? const Center(
                              child: Text('No hay roles creados'),
                            )
                          : ListView.builder(
                              itemCount: _roles.length,
                              itemBuilder: (context, index) {
                                final role = _roles[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    title: Text(role.nombre),
                                    subtitle: Text(role.descripcion ?? 'Sin descripción'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.security),
                                          tooltip: 'Editar Permisos',
                                          onPressed: () => _editRolePermissions(role),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Eliminar',
                                          onPressed: () => _deleteRole(role),
                                        ),
                                      ],
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
