import 'database_connection.dart';
import 'migrations/migration_manager.dart';
import 'seeds/seed_manager.dart';
import '../config/app_config.dart';

/// Servicio de inicialización automática de la base de datos
class DatabaseInitializer {
  static bool _isInitialized = false;

  /// Inicializar toda la base de datos automáticamente
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppConfig.logger.i('Starting D-Nexus database initialization...');
      
      // 1. Conectar a la base de datos
      await DatabaseConnection.initialize();
      
      // 2. Ejecutar migrations
      await MigrationManager.runMigrations();
      
      // 3. Ejecutar seeds (datos iniciales)
      await SeedManager.runSeeds();
      
      _isInitialized = true;
      AppConfig.logger.i('D-Nexus database initialization completed successfully');
      
    } catch (e) {
      AppConfig.logger.e('Database initialization failed: $e');
      rethrow;
    }
  }

  /// Verificar si la base de datos está inicializada
  static bool get isInitialized => _isInitialized && DatabaseConnection.isConnected;

  /// Reinicializar la base de datos (útil para testing)
  static Future<void> reset() async {
    AppConfig.logger.w('Resetting database...');
    
    await DatabaseConnection.close();
    _isInitialized = false;
    
    // Reinicializar desde cero
    await initialize();
  }

  /// Verificar el estado de la base de datos
  static Future<void> healthCheck() async {
    if (!isInitialized) {
      throw Exception('Database not initialized');
    }

    try {
      // Verificar conexión
      await DatabaseConnection.query('SELECT 1 as health_check;');
      
      // Verificar migrations
      await MigrationManager.status();
      
      AppConfig.logger.i('Database health check passed');
    } catch (e) {
      AppConfig.logger.e('Database health check failed: $e');
      rethrow;
    }
  }
}