import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../../shared/models/user_model.dart';
import '../../../core/config/app_config.dart';

/// Pantalla obligatoria de cambio de contraseña
/// Se muestra cuando un admin hace login por primera vez
class ForceChangePasswordPage extends StatefulWidget {
  final UserModel user;

  const ForceChangePasswordPage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<ForceChangePasswordPage> createState() => _ForceChangePasswordPageState();
}

class _ForceChangePasswordPageState extends State<ForceChangePasswordPage> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  
  late TextEditingController _passwordCtrl;
  late TextEditingController _confirmCtrl;

  @override
  void initState() {
    super.initState();
    _passwordCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_passwordCtrl.text.isEmpty || _confirmCtrl.text.isEmpty) {
      setState(() {
        _errorMessage = 'Completa todos los campos';
      });
      return;
    }

    if (_passwordCtrl.text.length < 8) {
      setState(() {
        _errorMessage = 'La contraseña debe tener al menos 8 caracteres';
      });
      return;
    }

    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Hash de la nueva contraseña
      final newPasswordHash = sha256
          .convert(utf8.encode(_passwordCtrl.text))
          .toString();

      // Actualizar contraseña y marcar como que no necesita cambio
      await Supabase.instance.client
          .from('users')
          .update({
            'password': newPasswordHash,
            'password_needs_change': false,
          })
          .eq('id', widget.user.id);

      if (!mounted) return;

      AppConfig.logger.i('Admin ${widget.user.username} cambió contraseña exitosamente');

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Contraseña cambiada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Ir al Admin Dashboard
      Navigator.of(context).pushReplacementNamed('/admin_dashboard', arguments: widget.user);
    } catch (e, stackTrace) {
      AppConfig.logger.e('Error cambiando contraseña: $e', error: e, stackTrace: stackTrace);
      setState(() {
        _errorMessage = 'Error al cambiar contraseña: $e';
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
    const primaryColor = Color(0xFF1a237e); // Deep Purple

    return WillPopScope(
      onWillPop: () async => false, // No permitir ir hacia atrás
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor,
                primaryColor.withOpacity(0.8),
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
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icono de advertencia
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.security,
                            size: 48,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Título
                        Text(
                          'Cambio de Contraseña Obligatorio',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtítulo
                        Text(
                          'Como es tu primer acceso, debes cambiar tu contraseña antes de continuar.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Info box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Usuario: ${widget.user.username}\nContraseña anterior: A1234567',
                                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nueva contraseña
                        TextField(
                          controller: _passwordCtrl,
                          enabled: !_isLoading,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Nueva Contraseña',
                            hintText: 'Mínimo 8 caracteres',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirmar contraseña
                        TextField(
                          controller: _confirmCtrl,
                          enabled: !_isLoading,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirmar Contraseña',
                            hintText: 'Repite la contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Mostrar error si existe
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_errorMessage != null) const SizedBox(height: 24),

                        // Botón de cambio
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Cambiar Contraseña',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
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
      ),
    );
  }
}
