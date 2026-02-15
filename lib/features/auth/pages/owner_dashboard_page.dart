import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/config/app_config.dart';

class OwnerDashboardPage extends StatefulWidget {
  final UserModel currentUser;

  const OwnerDashboardPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  List<Map<String, dynamic>> _admins = [];
  Map<String, bool> _systemsActive = {
    'repuestos': true,
    'prestamos': true,
    'inmuebles': true,
  };
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
        _loadAdmins(),
        _loadSystemsStatus(),
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

  Future<void> _loadAdmins() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('users')
          .select()
          .eq('rol', 'admin_negocio')
          .order('created_at', ascending: false);

      // Cargar sistemas para cada admin
      final adminsWithSystems = [];
      for (var admin in response) {
        final adminId = admin['id'];
        final systemsResponse = await supabase
            .from('admin_sistemas')
            .select('sistema')
            .eq('admin_id', adminId);
        
        final sistemas = (systemsResponse as List)
            .map((s) => s['sistema'] as String)
            .toList();
        
        admin['sistemas'] = sistemas;
        adminsWithSystems.add(admin);
      }

      setState(() {
        _admins = List<Map<String, dynamic>>.from(adminsWithSystems);
      });
      AppConfig.logger.i('Loaded ${_admins.length} admins with systems');
    } catch (e) {
      AppConfig.logger.e('Error loading admins: $e');
      rethrow;
    }
  }

  Future<void> _loadSystemsStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('systems')
          .select()
          .inFilter('name', ['repuestos', 'prestamos', 'inmuebles']);

      for (var system in response) {
        setState(() {
          _systemsActive[system['name']] = system['activo'] ?? true;
        });
      }
    } catch (e) {
      AppConfig.logger.e('Error loading systems status: $e');
    }
  }

  void _showCreateAdminDialog() {
    final usernameController = TextEditingController();
    final nameController = TextEditingController();
    final Map<String, bool> selectedSystems = {
      'repuestos': false,
      'prestamos': false,
      'inmuebles': false,
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Admin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
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
              const Text('Asignar a Sistemas:'),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setStateCheckbox) => Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Repuestos'),
                      value: selectedSystems['repuestos'],
                      onChanged: (value) {
                        setStateCheckbox(() {
                          selectedSystems['repuestos'] = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Préstamos'),
                      value: selectedSystems['prestamos'],
                      onChanged: (value) {
                        setStateCheckbox(() {
                          selectedSystems['prestamos'] = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Inmuebles'),
                      value: selectedSystems['inmuebles'],
                      onChanged: (value) {
                        setStateCheckbox(() {
                          selectedSystems['inmuebles'] = value ?? false;
                        });
                      },
                    ),
                  ],
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
              await _createAdmin(
                username: usernameController.text,
                fullName: nameController.text,
                systems: selectedSystems,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAdmin({
    required String username,
    required String fullName,
    required Map<String, bool> systems,
  }) async {
    if (username.isEmpty || fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    final selectedSystems = systems.entries.where((e) => e.value).map((e) => e.key).toList();
    if (selectedSystems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un sistema')),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      const defaultPassword = 'Abc123';
      final hashedPassword = sha256.convert(defaultPassword.codeUnits).toString();

      // Crear usuario con contraseña por defecto
      final userResponse = await supabase.from('users').insert({
        'username': username,
        'password': hashedPassword,
        'nombre_completo': fullName,
        'rol': 'admin_negocio',
        'email': '$username@admin.local',
        'activo': true,
      }).select();

      final userId = userResponse[0]['id'];

      // Asignar sistemas
      for (var system in selectedSystems) {
        await supabase.from('admin_sistemas').insert({
          'admin_id': userId,
          'sistema': system,
        });
      }

      AppConfig.logger.i('Admin created: $username for systems: $selectedSystems');
      await _loadAdmins();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin "$username" creado para ${selectedSystems.join(", ")}')),
        );
      }
    } catch (e) {
      AppConfig.logger.e('Error creating admin: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleAdminStatus(Map<String, dynamic> admin) async {
    try {
      final supabase = Supabase.instance.client;
      final currentStatus = admin['activo'] ?? true;
      final newStatus = !currentStatus;

      AppConfig.logger.i('Toggling admin ${admin['username']}: $currentStatus -> $newStatus');

      await supabase
          .from('users')
          .update({'activo': newStatus})
          .eq('username', admin['username']);

      AppConfig.logger.i('Admin ${admin['username']} status toggled to: $newStatus');
      
      setState(() {
        _admins = [];
      });
      await _loadAdmins();

      if (mounted) {
        final action = newStatus ? 'desbloqueado' : 'bloqueado';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin ${action}: ${admin['username']}')),
        );
      }
    } catch (e) {
      AppConfig.logger.e('Error toggling admin status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteAdmin(Map<String, dynamic> admin) async {
    try {
      final supabase = Supabase.instance.client;
      const defaultPassword = 'Abc123';
      final hashedPassword = sha256.convert(defaultPassword.codeUnits).toString();

      await supabase
          .from('users')
          .update({'password': hashedPassword})
          .eq('username', admin['username']);

      AppConfig.logger.i('Admin password reset: ${admin['username']}');
      await _loadAdmins();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contraseña reseteada a Abc123: ${admin['username']}')),
        );
      }
    } catch (e) {
      AppConfig.logger.e('Error resetting admin password: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showEditAdminDialog(Map<String, dynamic> admin) {
    final usernameController = TextEditingController(text: admin['username']);
    final nameController = TextEditingController(text: admin['nombre_completo']);
    final currentSystems = admin['sistemas'] as List<String>? ?? [];
    final Map<String, bool> selectedSystems = {
      'repuestos': currentSystems.contains('repuestos'),
      'prestamos': currentSystems.contains('prestamos'),
      'inmuebles': currentSystems.contains('inmuebles'),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Admin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Usuario (no editable)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Asignar a Sistemas:'),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setStateCheckbox) => Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Repuestos'),
                      value: selectedSystems['repuestos'],
                      onChanged: (value) {
                        setStateCheckbox(() {
                          selectedSystems['repuestos'] = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Préstamos'),
                      value: selectedSystems['prestamos'],
                      onChanged: (value) {
                        setStateCheckbox(() {
                          selectedSystems['prestamos'] = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Inmuebles'),
                      value: selectedSystems['inmuebles'],
                      onChanged: (value) {
                        setStateCheckbox(() {
                          selectedSystems['inmuebles'] = value ?? false;
                        });
                      },
                    ),
                  ],
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
              await _updateAdmin(
                adminUsername: admin['username'],
                adminId: admin['id'],
                fullName: nameController.text,
                systems: selectedSystems,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAdmin({
    required String adminUsername,
    required int adminId,
    required String fullName,
    required Map<String, bool> systems,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Actualizar nombre
      await supabase
          .from('users')
          .update({'nombre_completo': fullName})
          .eq('username', adminUsername);

      // Eliminar sistemas anteriores
      await supabase
          .from('admin_sistemas')
          .delete()
          .eq('admin_id', adminId);

      // Agregar nuevos sistemas
      final selectedSystems = systems.entries.where((e) => e.value).map((e) => e.key).toList();
      for (var system in selectedSystems) {
        await supabase.from('admin_sistemas').insert({
          'admin_id': adminId,
          'sistema': system,
        });
      }

      AppConfig.logger.i('Admin updated: $adminUsername with systems: $selectedSystems');
      
      setState(() {
        _admins = [];
      });
      await _loadAdmins();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin actualizado')),
        );
      }
    } catch (e) {
      AppConfig.logger.e('Error updating admin: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleSystem(String systemName) async {
    try {
      final supabase = Supabase.instance.client;
      final newStatus = !_systemsActive[systemName]!;

      try {
        await supabase
            .from('systems')
            .update({'activo': newStatus})
            .eq('name', systemName);
      } catch (_) {
        await supabase.from('systems').insert({
          'name': systemName,
          'activo': newStatus,
        });
      }

      setState(() {
        _systemsActive[systemName] = newStatus;
      });

      AppConfig.logger.i('System $systemName status: $newStatus');
      if (mounted) {
        final action = newStatus ? 'Activado' : 'Desactivado';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$action: $systemName')),
        );
      }
    } catch (e) {
      AppConfig.logger.e('Error toggling system: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        backgroundColor: Colors.purple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/system_selection', (route) => false),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[900]),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Estado de Sistemas',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildSystemCard('Repuestos', '', Colors.orange, 'repuestos'),
                      _buildSystemCard('Préstamos', '', Colors.green, 'prestamos'),
                      _buildSystemCard('Inmuebles', '', Colors.blue, 'inmuebles'),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Admins de Sistemas',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showCreateAdminDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_admins.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No hay admins creados',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _admins.length,
                      itemBuilder: (context, index) {
                        final admin = _admins[index];
                        final isActive = admin['activo'] ?? true;
                        final sistemas = admin['sistemas'] as List<String>? ?? [];
                        final sistemasText = sistemas.isEmpty ? 'N/A' : sistemas.join(', ');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(admin['nombre_completo'] ?? admin['username']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Usuario: ${admin['username']}'),
                                Text('Sistemas: $sistemasText'),
                              ],
                            ),
                            trailing: SizedBox(width: 200,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isActive ? 'Activo' : 'Bloqueado',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isActive
                                            ? Colors.green[900]
                                            : Colors.red[900],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditAdminDialog(admin),
                                    tooltip: 'Editar',
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      isActive ? Icons.block : Icons.check_circle,
                                      color: isActive ? Colors.orange : Colors.green,
                                    ),
                                    onPressed: () => _toggleAdminStatus(admin),
                                    tooltip: isActive ? 'Bloquear' : 'Desbloquear',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.lock_reset, color: Colors.purple),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Resetear Contraseña'),
                                          content: Text(
                                            '¿Resetear contraseña de ${admin['username']} a Abc123?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                _deleteAdmin(admin);
                                                Navigator.pop(context);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.purple,
                                              ),
                                              child: const Text('Resetear'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    tooltip: 'Resetear contraseña',
                                  ),
                                ],
                              ),
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

  Widget _buildSystemCard(
    String name,
    String emoji,
    Color color,
    String systemName,
  ) {
    final isActive = _systemsActive[systemName] ?? true;

    return GestureDetector(
      onTap: () => _toggleSystem(systemName),
      child: Card(
        color: isActive ? color : Colors.grey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isActive ? 'Activo' : 'Inactivo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
