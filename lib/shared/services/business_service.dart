import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/database_connection.dart';
import '../models/business_model.dart';

/// Servicio para manejar operaciones relacionadas con negocios
class BusinessService {

  /// Obtener datos simulados para web
  static List<BusinessModel> _getSimulatedBusinesses() {
    return [
      BusinessModel(
        id: 1,
        nombre: 'AutoRepuestos El Mecánico',
        tipo: 'repuestos',
        descripcion: 'Venta de repuestos automotrices y accesorios',
        propietarioId: 1,
        activo: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      BusinessModel(
        id: 2,
        nombre: 'ElectroHogar Premium',
        tipo: 'electrodomesticos',
        descripcion: 'Electrodomésticos y tecnología para el hogar',
        propietarioId: 2,
        activo: true,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
      ),
      BusinessModel(
        id: 3,
        nombre: 'Préstamos Rápidos Plus',
        tipo: 'prestamos',
        descripcion: 'Servicios financieros y préstamos personales',
        propietarioId: 3,
        activo: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
  
  /// Obtener todos los negocios activos
  static Future<List<BusinessModel>> getAllActiveBusinesses() async {
    try {
      AppConfig.logger.d('Getting all active businesses');
      
      // Si estamos en web, usar datos simulados
      if (kIsWeb) {
        AppConfig.logger.d('Web platform - using simulated businesses');
        return _getSimulatedBusinesses();
      }
      
      const query = '''
        SELECT id, nombre, tipo, descripcion, propietario_id, activo, created_at, updated_at
        FROM negocios 
        WHERE activo = true
        ORDER BY nombre ASC
      ''';
      
      final result = await DatabaseConnection.query(query);
      
      return result.map((row) {
        final businessMap = {
          'id': row[0],
          'nombre': row[1],
          'tipo': row[2],
          'descripcion': row[3],
          'propietario_id': row[4],
          'activo': row[5],
          'created_at': row[6].toString(),
          'updated_at': row[7].toString(),
        };
        return BusinessModel.fromMap(businessMap);
      }).toList();
      
    } catch (e) {
      AppConfig.logger.e('Error getting active businesses: $e');
      return kIsWeb ? _getSimulatedBusinesses() : [];
    }
  }

  /// Obtener negocios que puede administrar un usuario específico
  static Future<List<BusinessModel>> getBusinessesForUser(int userId) async {
    try {
      AppConfig.logger.d('Getting businesses for user: $userId');
      
      // Si estamos en web, usar datos simulados filtrados por usuario
      if (kIsWeb) {
        AppConfig.logger.d('Web platform - using simulated businesses for user: $userId');
        final allBusinesses = _getSimulatedBusinesses();
        // Super Admin (ID: 4) puede ver todos los negocios
        if (userId == 4) {
          return allBusinesses;
        }
        return allBusinesses.where((business) => business.propietarioId == userId).toList();
      }
      
      const query = '''
        SELECT id, nombre, tipo, descripcion, propietario_id, activo, created_at, updated_at
        FROM negocios 
        WHERE (propietario_id = \$1 OR \$1 IN (
          SELECT id FROM usuarios WHERE rol_sistema = 'super_admin'
        )) AND activo = true
        ORDER BY nombre ASC
      ''';
      
      final result = await DatabaseConnection.query(query, parameters: [userId]);
      
      return result.map((row) {
        final businessMap = {
          'id': row[0],
          'nombre': row[1],
          'tipo': row[2],
          'descripcion': row[3],
          'propietario_id': row[4],
          'activo': row[5],
          'created_at': row[6].toString(),
          'updated_at': row[7].toString(),
        };
        return BusinessModel.fromMap(businessMap);
      }).toList();
      
    } catch (e) {
      AppConfig.logger.e('Error getting businesses for user $userId: $e');
      return kIsWeb ? _getSimulatedBusinesses() : [];
    }
  }

  /// Obtener un negocio por ID
  static Future<BusinessModel?> getBusinessById(int businessId) async {
    try {
      AppConfig.logger.d('Getting business by ID: $businessId');
      
      // Si estamos en web, usar datos simulados
      if (kIsWeb) {
        AppConfig.logger.d('Web platform - using simulated business by ID');
        final businesses = _getSimulatedBusinesses();
        return businesses.where((b) => b.id == businessId).firstOrNull;
      }
      
      const query = '''
        SELECT id, nombre, tipo, descripcion, propietario_id, activo, created_at, updated_at
        FROM negocios 
        WHERE id = \$1
      ''';
      
      final result = await DatabaseConnection.query(query, parameters: [businessId]);
      
      if (result.isEmpty) {
        return null;
      }
      
      final row = result.first;
      final businessMap = {
        'id': row[0],
        'nombre': row[1],
        'tipo': row[2],
        'descripcion': row[3],
        'propietario_id': row[4],
        'activo': row[5],
        'created_at': row[6].toString(),
        'updated_at': row[7].toString(),
      };
      
      return BusinessModel.fromMap(businessMap);
      
    } catch (e) {
      AppConfig.logger.e('Error getting business by ID $businessId: $e');
      if (kIsWeb) {
        final businesses = _getSimulatedBusinesses();
        return businesses.where((b) => b.id == businessId).firstOrNull;
      }
      return null;
    }
  }

  /// Verificar si un usuario puede administrar un negocio
  static Future<bool> canUserManageBusiness(int userId, int businessId) async {
    try {
      AppConfig.logger.d('Checking if user $userId can manage business $businessId');
      
      const query = '''
        SELECT COUNT(*) as count FROM negocios n
        LEFT JOIN usuarios u ON n.propietario_id = u.id
        WHERE n.id = \$1 AND (
          n.propietario_id = \$2 OR 
          EXISTS (SELECT 1 FROM usuarios WHERE id = \$2 AND rol_sistema = 'super_admin')
        )
      ''';
      
      final result = await DatabaseConnection.query(query, parameters: [businessId, userId]);
      final count = result.first[0] as int;
      
      return count > 0;
      
    } catch (e) {
      AppConfig.logger.e('Error checking user business permissions: $e');
      return false;
    }
  }

  /// Crear un nuevo negocio
  static Future<BusinessModel?> createBusiness({
    required String nombre,
    required String tipo,
    String? descripcion,
    int? propietarioId,
  }) async {
    try {
      AppConfig.logger.d('Creating new business: $nombre');
      
      const insertQuery = '''
        INSERT INTO negocios (nombre, tipo, descripcion, propietario_id, activo)
        VALUES (\$1, \$2, \$3, \$4, \$5)
        RETURNING id, nombre, tipo, descripcion, propietario_id, activo, created_at, updated_at
      ''';
      
      final result = await DatabaseConnection.query(insertQuery, parameters: [
        nombre,
        tipo,
        descripcion,
        propietarioId,
        true,
      ]);
      
      if (result.isEmpty) {
        return null;
      }
      
      final row = result.first;
      final businessMap = {
        'id': row[0],
        'nombre': row[1],
        'tipo': row[2],
        'descripcion': row[3],
        'propietario_id': row[4],
        'activo': row[5],
        'created_at': row[6].toString(),
        'updated_at': row[7].toString(),
      };
      
      AppConfig.logger.i('Business created successfully: $nombre');
      return BusinessModel.fromMap(businessMap);
      
    } catch (e) {
      AppConfig.logger.e('Error creating business: $e');
      return null;
    }
  }
}