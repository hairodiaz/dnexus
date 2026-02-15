import 'package:flutter/material.dart';
import '../../../shared/services/session_service.dart';
import '../../../shared/models/user_model.dart';

/// Página de splash/verificación de sesión
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _statusMessage = 'Verificando sesión...';

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      // Esperar a que SharedPreferences esté completamente inicializado
      await Future.delayed(const Duration(seconds: 2));
      
      final hasSession = await SessionService.hasSession();
      
      if (!mounted) return;

      if (hasSession) {
        final user = await SessionService.getSession();
        
        if (user != null && mounted) {
          _navigateToDashboard(user);
        } else {
          _navigateToSystemSelection();
        }
      } else {
        _navigateToSystemSelection();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: $e';
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _navigateToSystemSelection();
        }
      }
    }
  }

  void _navigateToDashboard(UserModel user) {
    try {
      final route = switch (user.role) {
        'owner' => '/owner_dashboard',
        'super_admin' => '/super_admin_panel',
        'admin_negocio' => '/dashboard',
        'admin_repuestos' => '/dashboard',
        'admin_prestamos' => '/dashboard',
        'admin_inmuebles' => '/dashboard',
        _ => '/system_selection',
      };

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          route,
          (route) => false,
          arguments: user,
        );
      }
    } catch (e) {
      if (mounted) {
        _navigateToSystemSelection();
      }
    }
  }

  void _navigateToSystemSelection() {
    try {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/system_selection',
          (route) => false,
        );
      }
    } catch (e) {
      // Ignorar errores de navegación
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1976D2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'D-Nexus',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
