import 'package:flutter/material.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/config/app_config.dart';

/// Pantalla de login de D-Nexus optimizada para presentación al cliente
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  String? _errorMessage;
  
  // Modo desarrollo solo para presentación
  UserModel? _selectedUser;
  List<UserModel> _developmentUsers = [];

  @override
  void initState() {
    super.initState();
    _loadDevelopmentUsers();
  }

  /// Cargar usuarios de desarrollo para presentación
  Future<void> _loadDevelopmentUsers() async {
    try {
      // Usuarios de desarrollo para presentación al cliente
      _developmentUsers = [
        UserModel(
          id: 1,
          username: 'repuestos_user',
          email: 'repuestos@dnexus.com',
          fullName: 'Negocio de Repuestos',
          role: 'admin_negocio',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 2,
          username: 'electrodomesticos_user',
          email: 'electrodomesticos@dnexus.com',
          fullName: 'Tienda de Electrodomésticos',
          role: 'admin_negocio',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 3,
          username: 'prestamos_user',
          email: 'prestamos@dnexus.com',
          fullName: 'Casa de Préstamos',
          role: 'admin_negocio',
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];
      setState(() {});
    } catch (e) {
      print('Error cargando usuarios de desarrollo: $e');
    }
  }

  /// Login rápido para desarrollo
  Future<void> _developmentLogin() async {
    if (_selectedUser == null) {
      setState(() {
        _errorMessage = 'Por favor selecciona un usuario';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simular login exitoso con el usuario seleccionado
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // Navegar al dashboard con el usuario seleccionado
        Navigator.of(context).pushReplacementNamed('/dashboard', arguments: _selectedUser);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error en login de desarrollo';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo y título
                      Icon(
                        Icons.business_center,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'D-Nexus',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sistema de Gestión Multi-Negocios',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Sección de desarrollo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.developer_mode,
                                  color: Colors.orange[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Modo Desarrollo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[800],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Dropdown de usuarios
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<UserModel>(
                                  value: _selectedUser,
                                  isExpanded: true,
                                  hint: Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Seleccionar Usuario',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  selectedItemBuilder: (BuildContext context) {
                                    return _developmentUsers.map((user) {
                                      return Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              user.fullName ?? user.username,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList();
                                  },
                                  items: _developmentUsers.map((user) {
                                    return DropdownMenuItem<UserModel>(
                                      value: user,
                                      child: Container(
                                        width: double.infinity,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              user.fullName ?? user.username,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              user.role,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _isLoading ? null : (user) {
                                    setState(() {
                                      _selectedUser = user;
                                      _errorMessage = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _developmentLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Acceso Rápido (Demo)',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Información de credenciales
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue[600], size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Credenciales de prueba:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[800],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Selecciona un negocio de la lista para acceder\na la demostración del sistema.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Mostrar error si existe
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}