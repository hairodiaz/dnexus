import '../database_connection.dart';
import '../../config/app_config.dart';
import 'migration.dart';
import '001_create_initial_tables.dart';

/// Administrador del sistema de migrations para D-Nexus
class MigrationManager {
  /// Lista ordenada de todas las migrations disponibles
  static final List<Migration> _migrations = [
    CreateInitialTablesMigration(),
    // Aquí se agregarán futuras migrations
  ];

  /// Ejecutar todas las migrations pendientes
  static Future<void> runMigrations() async {
    AppConfig.logger.i('Starting database migrations...');
    
    try {
      // Crear tabla de migrations si no existe
      await _ensureMigrationsTableExists();
      
      // Obtener versión actual de la BD
      final currentVersion = await _getCurrentVersion();
      AppConfig.logger.i('Current database version: $currentVersion');
      
      // Ejecutar migrations pendientes
      final pendingMigrations = _migrations.where((m) => m.version > currentVersion).toList();
      
      if (pendingMigrations.isEmpty) {
        AppConfig.logger.i('No pending migrations to run');
        return;
      }
      
      AppConfig.logger.i('Found ${pendingMigrations.length} pending migrations');
      
      for (final migration in pendingMigrations) {
        await _runMigration(migration);
      }
      
      AppConfig.logger.i('All migrations completed successfully');
      
    } catch (e) {
      AppConfig.logger.e('Migration failed: $e');
      rethrow;
    }
  }

  /// Crear la tabla de migrations si no existe
  static Future<void> _ensureMigrationsTableExists() async {
    const sql = '''
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        version INTEGER UNIQUE NOT NULL,
        description VARCHAR(255) NOT NULL,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''';
    
    await DatabaseConnection.query(sql);
    AppConfig.logger.d('Migrations table ensured');
  }

  /// Obtener la versión actual de la base de datos
  static Future<int> _getCurrentVersion() async {
    const sql = '''
      SELECT COALESCE(MAX(version), 0) as current_version 
      FROM migrations;
    ''';
    
    try {
      final result = await DatabaseConnection.query(sql);
      return result.first[0] as int;
    } catch (e) {
      AppConfig.logger.w('Could not get current version, assuming 0: $e');
      return 0;
    }
  }

  /// Ejecutar una migration específica
  static Future<void> _runMigration(Migration migration) async {
    AppConfig.logger.i('Running migration ${migration.version}: ${migration.description}');
    
    await DatabaseConnection.transaction((ctx) async {
      // Ejecutar la migration
      await migration.up(ctx);
      
      // Registrar en la tabla de migrations
      const sql = '''
        INSERT INTO migrations (version, description) 
        VALUES (\$1, \$2);
      ''';
      
      await ctx.execute(sql, parameters: [
        migration.version,
        migration.description,
      ]);
      
      AppConfig.logger.i('Migration ${migration.version} completed successfully');
    });
  }

  /// Revertir a una versión específica (rollback)
  static Future<void> rollbackTo(int targetVersion) async {
    AppConfig.logger.i('Rolling back to version $targetVersion');
    
    final currentVersion = await _getCurrentVersion();
    
    if (targetVersion >= currentVersion) {
      AppConfig.logger.w('Target version $targetVersion is not lower than current version $currentVersion');
      return;
    }
    
    final migrationsToRollback = _migrations
        .where((m) => m.version > targetVersion && m.version <= currentVersion)
        .toList()
      ..sort((a, b) => b.version.compareTo(a.version)); // Orden descendente
    
    for (final migration in migrationsToRollback) {
      AppConfig.logger.i('Rolling back migration ${migration.version}: ${migration.description}');
      
      await DatabaseConnection.transaction((ctx) async {
        await migration.down(ctx);
        
        const sql = 'DELETE FROM migrations WHERE version = \$1';
        await ctx.execute(sql, parameters: [migration.version]);
        
        AppConfig.logger.i('Migration ${migration.version} rolled back successfully');
      });
    }
    
    AppConfig.logger.i('Rollback to version $targetVersion completed');
  }

  /// Obtener el estado de todas las migrations
  static Future<void> status() async {
    final currentVersion = await _getCurrentVersion();
    
    AppConfig.logger.i('Migration Status:');
    AppConfig.logger.i('Current version: $currentVersion');
    AppConfig.logger.i('Available migrations:');
    
    for (final migration in _migrations) {
      final status = migration.version <= currentVersion ? 'APPLIED' : 'PENDING';
      AppConfig.logger.i('  ${migration.version}: ${migration.description} [$status]');
    }
  }
}