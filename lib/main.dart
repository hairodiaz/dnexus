import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/database_initializer.dart';
import 'core/config/app_config.dart';
import 'features/auth/pages/splash_page.dart';
import 'features/auth/pages/system_selection_page.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/prestamos_login_page.dart';
import 'features/auth/pages/inmuebles_login_page.dart';
import 'features/auth/pages/owner_login_page.dart';
import 'features/auth/pages/user_management_login_page.dart';
import 'features/auth/pages/admin_panel_page.dart';
import 'features/auth/pages/owner_dashboard_page.dart';
import 'features/auth/pages/super_admin_panel_page.dart';
import 'features/dashboard/pages/dashboard_with_permissions.dart';
import 'shared/models/user_model.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    AppConfig.logger.i('Starting D-Nexus application...');
    
    // Inicializar SharedPreferences para persistencia de sesión
    await SharedPreferences.getInstance();
    AppConfig.logger.i('SharedPreferences initialized successfully');
    
    // Inicializar Supabase
    await Supabase.initialize(
      url: 'https://xmoqjehicmqkseejreng.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhtb3FqZWhpY21xa3NlZWpyZW5nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1MDQwNTQsImV4cCI6MjA4MTA4MDA1NH0.mUFFIKDPI-M8wXILW4FNmSwxCRODDdU_cAq36wMNoHs',
    );
    
    AppConfig.logger.i('Supabase initialized successfully');
    
    // Inicializar la base de datos automáticamente
    await DatabaseInitializer.initialize();
    
    AppConfig.logger.i('D-Nexus ready to start!');
    
    runApp(const DNexusApp());
    
  } catch (e) {
    AppConfig.logger.e('Failed to initialize D-Nexus: $e');
    
    // Mostrar pantalla de error
    runApp(DNexusErrorApp(error: e.toString()));
  }
}

/// Aplicación principal de D-Nexus
class DNexusApp extends StatelessWidget {
  const DNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2), // Azul empresarial
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashPage(),
        '/': (context) => const SystemSelectionPage(),
        '/system_selection': (context) => const SystemSelectionPage(),
        '/login': (context) => const LoginPage(),
        '/prestamos_login': (context) => const PrestamosLoginPage(),
        '/inmuebles_login': (context) => const InmueblesLoginPage(),
        '/owner_login': (context) => const OwnerLoginPage(),
        '/user_management_login': (context) => const UserManagementLoginPage(),
        '/user_management_panel': (context) {
          final user = ModalRoute.of(context)?.settings.arguments as UserModel?;
          if (user == null) {
            return const SystemSelectionPage();
          }
          return AdminPanelPage(currentUser: user);
        },
        '/owner_dashboard': (context) {
          final user = ModalRoute.of(context)?.settings.arguments as UserModel?;
          if (user == null) {
            return const SystemSelectionPage();
          }
          return OwnerDashboardPage(currentUser: user);
        },
        '/super_admin_panel': (context) {
          final user = ModalRoute.of(context)?.settings.arguments as UserModel?;
          if (user == null) {
            return const SystemSelectionPage();
          }
          return SuperAdminPanelPage(currentUser: user);
        },
        '/dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          
          if (args is UserModel) {
            // Para compatibilidad con la ruta antigua
            return DashboardPageWithPermissions(user: args);
          } else if (args is Map<String, dynamic>) {
            // Nuevo formato con system type
            final user = args['user'] as UserModel;
            return DashboardPageWithPermissions(user: user);
          } else {
            return const SystemSelectionPage();
          }
        },
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const SystemSelectionPage(),
        );
      },
    );
  }
}

/// Aplicación de error para cuando falla la inicialización
class DNexusErrorApp extends StatelessWidget {
  final String error;
  
  const DNexusErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D-Nexus Error',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('D-Nexus - Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Error de Inicialización',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo inicializar la base de datos.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verificar:\n• PostgreSQL instalado y ejecutándose\n• Base de datos "dnexus_db" creada\n• Credenciales correctas en AppConfig',
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
