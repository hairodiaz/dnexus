import 'package:postgres/postgres.dart';
import '../../config/app_config.dart';

/// Clase base abstracta para todas las migrations de D-Nexus
abstract class Migration {
  /// Número de versión de esta migration
  int get version;
  
  /// Descripción de lo que hace esta migration
  String get description;
  
  /// Ejecutar la migration (crear tablas, índices, etc.)
  Future<void> up(TxSession ctx);
  
  /// Revertir la migration (rollback)
  Future<void> down(TxSession ctx);
  
  /// Método helper para ejecutar SQL dentro de una transacción
  Future<void> execute(TxSession ctx, String sql) async {
    AppConfig.logger.d('Executing migration SQL: $description');
    AppConfig.logger.d('Executing SQL: $sql');
    await ctx.execute(sql);
  }
  
  /// Método helper para verificar si una tabla existe
  Future<bool> tableExists(TxSession ctx, String tableName) async {
    const sql = '''
      SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = \$1
      );
    ''';
    
    try {
      final result = await ctx.execute(sql, parameters: [tableName]);
      return result.first[0] as bool;
    } catch (e) {
      AppConfig.logger.e('Error checking if table $tableName exists: $e');
      return false;
    }
  }
  
  /// Método helper para crear índice de manera segura
  Future<void> createIndexIfNotExists(TxSession ctx, String indexName, String sql) async {
    try {
      await execute(ctx, sql);
      AppConfig.logger.d('Index $indexName created successfully');
    } catch (e) {
      if (e.toString().contains('already exists')) {
        AppConfig.logger.d('Index $indexName already exists, skipping');
      } else {
        rethrow;
      }
    }
  }
}