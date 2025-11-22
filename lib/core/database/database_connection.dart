import 'package:postgres/postgres.dart';
import '../config/app_config.dart';

/// Administrador de conexiones a PostgreSQL para D-Nexus
class DatabaseConnection {
  static Connection? _connection;
  static bool _isInitialized = false;

  /// Obtener la conexión activa a la base de datos
  static Connection get connection {
    if (_connection == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _connection!;
  }

  /// Inicializar la conexión a PostgreSQL
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppConfig.logger.i('Connecting to PostgreSQL database...');
      
      final endpoint = Endpoint(
        host: AppConfig.dbHost,
        port: AppConfig.dbPort,
        database: AppConfig.dbName,
        username: AppConfig.dbUsername,
        password: AppConfig.dbPassword,
      );

      _connection = await Connection.open(
        endpoint,
        settings: const ConnectionSettings(
          sslMode: SslMode.disable, // Para desarrollo local
        ),
      );

      _isInitialized = true;
      AppConfig.logger.i('Database connection established successfully');
      
    } catch (e) {
      AppConfig.logger.e('Failed to connect to database: $e');
      rethrow;
    }
  }

  /// Cerrar la conexión a la base de datos
  static Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      _isInitialized = false;
      AppConfig.logger.i('Database connection closed');
    }
  }

  /// Verificar si la conexión está activa
  static bool get isConnected => _connection != null && _isInitialized;

  /// Ejecutar una consulta SQL
  static Future<Result> query(
    String sql, {
    List<dynamic>? parameters,
    bool logQuery = false,
  }) async {
    if (!isConnected) {
      throw Exception('Database not connected');
    }

    if (logQuery) {
      AppConfig.logger.d('Executing SQL: $sql');
      if (parameters != null) {
        AppConfig.logger.d('Parameters: $parameters');
      }
    }

    try {
      final Result result;
      if (parameters != null && parameters.isNotEmpty) {
        result = await _connection!.execute(
          sql,
          parameters: parameters,
        );
      } else {
        result = await _connection!.execute(sql);
      }
      
      if (logQuery) {
        AppConfig.logger.d('Query executed successfully, ${result.length} rows affected');
      }
      
      return result;
    } catch (e) {
      AppConfig.logger.e('SQL Error: $e');
      AppConfig.logger.e('Query: $sql');
      rethrow;
    }
  }

  /// Ejecutar múltiples consultas en una transacción
  static Future<T> transaction<T>(
    Future<T> Function(TxSession ctx) operation,
  ) async {
    if (!isConnected) {
      throw Exception('Database not connected');
    }

    AppConfig.logger.d('Starting database transaction');
    
    try {
      final result = await _connection!.runTx((ctx) async {
        return await operation(ctx);
      });
      
      AppConfig.logger.d('Transaction completed successfully');
      return result;
    } catch (e) {
      AppConfig.logger.e('Transaction failed: $e');
      rethrow;
    }
  }

  /// Ejecutar un comando SQL (alias de query para compatibilidad)
  static Future<Result> execute(
    String sql, {
    List<dynamic>? parameters,
    bool logQuery = false,
  }) async {
    return await query(sql, parameters: parameters, logQuery: logQuery);
  }

  /// Verificar si una tabla existe
  static Future<bool> tableExists(String tableName) async {
    const sql = '''
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = \$1
      );
    ''';
    
    final result = await query(sql, parameters: [tableName]);
    return result.first[0] as bool;
  }
}