import 'package:flutter/material.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/config/app_config.dart';

/// Pantalla de login de D-Nexus
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  
  // Modo desarrollo
  bool _isDevelopmentMode = true; // Cambiar a false para producción
  UserModel? _selectedUser;
  List<UserModel> _developmentUsers = [];

  @override
  void initState() {
    super.initState();
    if (_isDevelopmentMode) {
      _loadDevelopmentUsers();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Cargar usuarios de desarrollo
  Future<void> _loadDevelopmentUsers() async {
    try {
      // Usuarios de desarrollo para pruebas rápidas
      _developmentUsers = [
        UserModel(
          id: 1,
          username: 'admin',
          email: 'admin@dnexus.com',
          fullName: 'Administrador Sistema',
          role: 'admin',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 2,
          username: 'usuario1',
          email: 'usuario1@dnexus.com',
          fullName: 'Juan Pérez',
          role: 'user',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 3,
          username: 'usuario2',
          email: 'usuario2@dnexus.com',
          fullName: 'María García',
          role: 'user',
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];
      setState(() {});
    } catch (e) {
      print('Error cargando usuarios de desarrollo: $e');
    }
  }

  /// Maneja el proceso de login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      
      final user = await AuthService.login(username, password);
      
      if (user != null) {
        if (mounted) {
          // Login exitoso - navegar al dashboard
          Navigator.of(context).pushReplacementNamed('/dashboard', arguments: user);
        }
      } else {
        setState(() {
          _errorMessage = 'Usuario o contraseña incorrectos';
        });
      }
    } catch (e) {
      AppConfig.logger.e('Login error: $e');
      setState(() {
        _errorMessage = 'Error de conexión. Intente nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Login rápido para desarrollo
  Future<void> _developmentLogin() async {
    if (_selectedUser == null) {
      setState(() {
        _errorMessage = 'Seleccione un usuario para continuar';
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
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo y título
                      Icon(
                        Icons.business_center,
                        size: 80,
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
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Modo desarrollo - Selector de usuario
                      if (_isDevelopmentMode) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
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
                                  Icon(Icons.developer_mode, color: Colors.orange[700], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Modo Desarrollo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<UserModel>(
                                value: _selectedUser,
                                decoration: InputDecoration(
                                  labelText: 'Seleccionar Usuario',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: _developmentUsers.map((user) {
                                  return DropdownMenuItem<UserModel>(
                                    value: user,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          user.fullName ?? user.username,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '${user.username} • ${user.role}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
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
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _developmentLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('Acceso Rápido (Dev)'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'O usar login tradicional',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Formulario de login tradicional
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Campo de usuario
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Usuario',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabled: !_isLoading,
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingrese su usuario';
                                }
                                if (!AuthService.isValidUsername(value.trim())) {
                                  return 'Usuario inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Campo de contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabled: !_isLoading,
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su contraseña';
                                }
                                if (!AuthService.isValidPassword(value)) {
                                  return 'Contraseña muy corta';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Mensaje de error
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Botón de login
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Ingresar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Información de credenciales de prueba
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Credenciales de prueba:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Usuario: superadmin',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'Contraseña: admin123',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
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