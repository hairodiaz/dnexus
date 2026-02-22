import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/user_model.dart';

/// Dashboard del Owner - Panel principal de administración del sistema
class OwnerDashboardPage extends StatefulWidget {
  final UserModel currentUser;

  const OwnerDashboardPage({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _administradores = [];
  bool _loadingAdmins = false;

  @override
  void initState() {
    super.initState();
    _cargarAdministradores();
  }

  Future<void> _cargarAdministradores() async {
    setState(() => _loadingAdmins = true);
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('rol', 'admin_negocio')
          .order('created_at', ascending: false);
      
      setState(() {
        _administradores = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar administradores: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAdmins = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Menú lateral
          _buildSidebar(context),
          // Contenido principal
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final menuItems = [
      {'icon': Icons.home, 'label': 'Dashboard', 'index': 0},
      {'icon': Icons.admin_panel_settings, 'label': 'Administradores', 'index': 1},
      {'icon': Icons.dashboard, 'label': 'Módulos del Sistema', 'index': 2},
      {'icon': Icons.history, 'label': 'Auditoría', 'index': 3},
    ];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.deepPurple[800],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del menú
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple[900],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.business_center,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'D-NEXUS',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Panel Owner',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.currentUser.fullName ?? widget.currentUser.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Menú items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = _selectedIndex == item['index'];

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      item['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    title: Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = item['index'] as int;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          // Footer con logout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple[900],
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.white70,
              ),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              onTap: () {
                Navigator.of(context).pushReplacementNamed('/system_selection');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOwnerHome();
      case 1:
        return _buildAdministratorsSection();
      case 2:
        return _buildSystemModulesSection();
      case 3:
        return _buildAuditSection();
      default:
        return const Center(child: Text('Selecciona una opción'));
    }
  }

  Widget _buildOwnerHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Panel Owner',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bienvenido, ${widget.currentUser.fullName ?? widget.currentUser.username}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          // Tarjetas de resumen
          GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                title: 'Administradores',
                value: '0',
                icon: Icons.admin_panel_settings,
                color: Colors.blue,
              ),
              _buildStatCard(
                title: 'Módulos',
                value: '6',
                icon: Icons.dashboard,
                color: Colors.green,
              ),
              _buildStatCard(
                title: 'Auditoría',
                value: '0',
                icon: Icons.history,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdministratorsSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Administradores',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea y administra los usuarios administradores del sistema',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _mostrarDialogoCrearAdmin,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Administrador'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Tabla de administradores
          if (_loadingAdmins)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_administradores.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay administradores',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea el primer administrador haciendo clic en el botón "Nuevo Administrador"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Usuario')),
                  DataColumn(label: Text('Nombre Completo')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Fecha Creación')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: _administradores.map((admin) {
                  final createdAt = DateTime.parse(admin['created_at'] as String);
                  final fechaFormato = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
                  final estado = admin['activo'] == true ? 'Activo' : 'Inactivo';
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(admin['username'] as String)),
                      DataCell(Text(admin['nombre_completo'] as String? ?? 'N/A')),
                      DataCell(Text(admin['email'] as String? ?? 'N/A')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: admin['activo'] == true ? Colors.green[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              fontSize: 12,
                              color: admin['activo'] == true ? Colors.green[900] : Colors.red[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(fechaFormato)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => _mostrarDialogoEditarAdmin(admin),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: Icon(
                                admin['activo'] == true 
                                    ? Icons.block 
                                    : Icons.check_circle,
                                size: 18,
                                color: admin['activo'] == true ? Colors.red : Colors.green,
                              ),
                              onPressed: () => _toggleAdminEstado(admin),
                              tooltip: admin['activo'] == true ? 'Deshabilitar' : 'Habilitar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.vpn_key, size: 18, color: Colors.orange),
                              onPressed: () => _resetPassword(admin),
                              tooltip: 'Resetear Contraseña',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrearAdmin() {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Crear Nuevo Administrador'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Contraseña predeterminada: A1234567\nEl admin deberá cambiarla al primer login',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameCtrl,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Nombre de Usuario',
                    hintText: 'Ej: admin_tienda',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'admin@example.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nombreCtrl,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    hintText: 'Ej: Juan Pérez',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (usernameCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ingresa el nombre de usuario'),
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        // Contraseña predeterminada: A1234567
                        final passwordHash = sha256
                            .convert(utf8.encode('A1234567'))
                            .toString();

                        await Supabase.instance.client.from('users').insert({
                          'username': usernameCtrl.text,
                          'password': passwordHash,
                          'email': emailCtrl.text.isEmpty ? null : emailCtrl.text,
                          'nombre_completo': nombreCtrl.text.isEmpty ? null : nombreCtrl.text,
                          'rol': 'admin_negocio',
                          'activo': true,
                          'password_needs_change': true,
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Admin creado - Contraseña: A1234567 (debe cambiarla al login)'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 4),
                            ),
                          );
                          Navigator.pop(context);
                          _cargarAdministradores();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('❌ Error: $e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => isLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEditarAdmin(Map<String, dynamic> admin) {
    final usernameCtrl = TextEditingController(text: admin['username'] as String);
    final emailCtrl = TextEditingController(text: admin['email'] as String? ?? '');
    final nombreCtrl = TextEditingController(text: admin['nombre_completo'] as String? ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Administrador'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameCtrl,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Nombre de Usuario',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nombreCtrl,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);

                      try {
                        await Supabase.instance.client
                            .from('users')
                            .update({
                              'email': emailCtrl.text.isEmpty ? null : emailCtrl.text,
                              'nombre_completo': nombreCtrl.text.isEmpty ? null : nombreCtrl.text,
                            })
                            .eq('id', admin['id']);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Administrador actualizado exitosamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                          _cargarAdministradores();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('❌ Error: $e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => isLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAdminEstado(Map<String, dynamic> admin) {
    final nuevoEstado = !(admin['activo'] as bool? ?? true);
    final accion = nuevoEstado ? 'Habilitar' : 'Deshabilitar';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$accion Administrador'),
        content: Text(
          '¿Estás seguro de que deseas ${accion.toLowerCase()} al administrador "${admin['username']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('users')
                    .update({'activo': nuevoEstado})
                    .eq('id', admin['id']);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Administrador ${accion.toLowerCase()} exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _cargarAdministradores();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: nuevoEstado ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(accion),
          ),
        ],
      ),
    );
  }

  void _resetPassword(Map<String, dynamic> admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetear Contraseña'),
        content: Text(
          '¿Estás seguro de que deseas resetear la contraseña de "${admin['username']}"?\n\nContraseña nueva: A1234567',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Hash de "A1234567"
                final newPasswordHash = sha256
                    .convert(utf8.encode('A1234567'))
                    .toString();

                await Supabase.instance.client
                    .from('users')
                    .update({'password': newPasswordHash})
                    .eq('id', admin['id']);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Contraseña restablecida a: A1234567'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _cargarAdministradores();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resetear'),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemModulesSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Módulos del Sistema',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Sección en desarrollo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Auditoría del Sistema',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Sección en desarrollo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
