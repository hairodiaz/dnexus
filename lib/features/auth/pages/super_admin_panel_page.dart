import 'package:flutter/material.dart';
import 'package:dnexus/shared/models/user_model.dart';
import 'package:dnexus/shared/models/system_module_model.dart';
import 'package:dnexus/shared/services/super_admin_service.dart';
import 'package:dnexus/shared/services/auth_service_with_roles.dart';

/// Página del Panel SuperAdmin - Interfaz administrativa del sistema
class SuperAdminPanelPage extends StatefulWidget {
  final UserModel currentUser;

  const SuperAdminPanelPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<SuperAdminPanelPage> createState() => _SuperAdminPanelPageState();
}

class _SuperAdminPanelPageState extends State<SuperAdminPanelPage> {
  final SuperAdminService _superAdminService = SuperAdminService();
  final AuthService _authService = AuthService();
  
  int _selectedIndex = 0;
  List<SystemModule> _modules = [];
  List<AuditLog> _auditLogs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadModules();
    _loadAuditLogs();
  }

  Future<void> _loadModules() async {
    setState(() => _loading = true);
    try {
      final modules = await _superAdminService.getSystemModules();
      setState(() {
        _modules = modules;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando módulos: $e')),
      );
    }
  }

  Future<void> _loadAuditLogs() async {
    try {
      final logs = await _superAdminService.getAuditLog(limit: 50);
      setState(() => _auditLogs = logs);
    } catch (e) {
      // Silent fail for audit logs
    }
  }

  Future<void> _toggleModule(SystemModule module) async {
    setState(() => _loading = true);
    try {
      final success = await _superAdminService.toggleModule(module.id, !module.activo);
      if (success) {
        // Actualizar módulo en memoria localmente
        final index = _modules.indexWhere((m) => m.id == module.id);
        if (index != -1) {
          _modules[index] = module.copyWith(activo: !module.activo);
        }
        
        await _superAdminService.logAuditAction(
          usuarioId: widget.currentUser.id.toString(),
          nombreUsuario: widget.currentUser.fullName ?? 'SuperAdmin',
          tipo: 'cambiar_modulo',
          descripcion: 'Cambió estado del módulo ${module.nombre} a ${!module.activo ? 'activo' : 'inactivo'}',
        );
        
        // Recargar audit logs
        await _loadAuditLogs();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Módulo ${module.nombre} ${!module.activo ? 'activado' : 'desactivado'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showCreateAdminDialog() {
    final formKey = GlobalKey<FormState>();
    String username = '';
    String password = '';
    String email = '';
    String nombreCompleto = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Administrador'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre Completo'),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  onChanged: (v) => nombreCompleto = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Usuario'),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  onChanged: (v) => username = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  onChanged: (v) => email = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                  onChanged: (v) => password = v,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final admin = await _superAdminService.createAdministrator(
                  username: username,
                  password: password,
                  email: email,
                  nombreCompleto: nombreCompleto,
                );

                if (admin != null) {
                  await _superAdminService.logAuditAction(
                    usuarioId: widget.currentUser.id.toString(),
                    nombreUsuario: widget.currentUser.fullName ?? 'SuperAdmin',
                    tipo: 'crear_usuario',
                    descripcion: 'Creó nuevo usuario Administrador: $nombreCompleto ($username)',
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Administrador creado: $nombreCompleto')),
                  );
                  _loadAuditLogs();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error creando administrador')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel SuperAdmin - D-Nexus'),
        elevation: 0,
        backgroundColor: Colors.deepPurple[700],
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '${widget.currentUser.fullName} (SuperAdmin)',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.deepPurple[50],
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildNavItem(0, Icons.manage_accounts, 'Crear Administrador'),
                _buildNavItem(1, Icons.dashboard, 'Módulos del Sistema'),
                _buildNavItem(2, Icons.history, 'Historial de Auditoría'),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenido Principal
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepPurple[300] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.deepPurple[700] : Colors.grey),
        title: Text(label),
        onTap: () {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return _buildCreateAdminSection();
      case 1:
        return _buildModulesSection();
      case 2:
        return _buildAuditSection();
      default:
        return const Center(child: Text('Selecciona una opción'));
    }
  }

  Widget _buildCreateAdminSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crear Nuevo Administrador',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'El Administrador es el usuario principal que gestiona el sistema.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Responsabilidades del Administrador:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Crear y gestionar negocios'),
                          Text('• Crear y asignar empleados'),
                          Text('• Ver historial de auditoría'),
                          Text('• Configurar permisos de usuarios'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showCreateAdminDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Administrador'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Módulos del Sistema',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Activa o desactiva módulos para controlar las funciones disponibles'),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _modules.length,
              itemBuilder: (context, index) {
                final module = _modules[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    module.nombre,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    module.descripcion,
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: module.activo,
                              onChanged: (_) => _toggleModule(module),
                              activeThumbColor: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Auditoría',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (_auditLogs.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No hay registros de auditoría'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _auditLogs.length,
                itemBuilder: (context, index) {
                  final log = _auditLogs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        log.estado == 'exitoso' ? Icons.check_circle : Icons.error,
                        color: log.estado == 'exitoso' ? Colors.green : Colors.red,
                      ),
                      title: Text(log.descripcion),
                      subtitle: Text('${log.nombreUsuario} - ${log.tipo}'),
                      trailing: Text(
                        '${log.fechaHora.day}/${log.fechaHora.month}/${log.fechaHora.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
