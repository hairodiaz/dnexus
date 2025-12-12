import 'package:logger/logger.dart';

/// Configuración central de la aplicación D-Nexus
class AppConfig {
  static final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // Configuración de base de datos - Supabase
  static const String dbHost = 'xmoqjehicmqkseejreng.supabase.co';
  static const int dbPort = 5432;
  static const String dbName = 'postgres';
  static const String dbUsername = 'postgres';
  static const String dbPassword = 'Hernandez14'; // Cambiar en producción
  
  // Versión actual de la base de datos para migrations
  static const int currentDbVersion = 1;
  
  // Configuración de la aplicación
  static const String appName = 'D-Nexus';
  static const String appVersion = '1.0.0';
  
  // Configuración de sesiones
  static const String sessionTokenKey = 'dnexus_session_token';
  static const String currentUserKey = 'dnexus_current_user';
  static const String selectedBusinessKey = 'dnexus_selected_business';
  
  // Configuración de seguridad
  static const int sessionTimeoutHours = 24;
  static const int passwordMinLength = 6;
  
  // Configuración de UI
  static const int defaultPageSize = 20;
  static const int maxItemsPerPage = 100;
}