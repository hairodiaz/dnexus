import 'package:dnexus/shared/models/system_module_model.dart';
import 'package:dnexus/shared/models/user_model.dart';
import 'supabase_http_client.dart';
import '../../core/utils/platform_detector.dart';

/// Servicio para operaciones exclusivas de SuperAdmin
class SuperAdminService {
  static final SuperAdminService _instance = SuperAdminService._internal();
  factory SuperAdminService() => _instance;
  SuperAdminService._internal();

  final SupabaseHttpClient _supabaseClient = SupabaseHttpClient();

  // Módulos del sistema (en memoria para desarrollo)
  final List<SystemModule> _modules = [
    SystemModule(
      id: '1',
      nombre: 'Cash Register',
      descripcion: 'Módulo de caja registradora',
      activo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SystemModule(
      id: '2',
      nombre: 'Inventario',
      descripcion: 'Gestión de productos e inventario',
      activo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SystemModule(
      id: '3',
      nombre: 'Facturas',
      descripcion: 'Creación y gestión de facturas',
      activo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SystemModule(
      id: '4',
      nombre: 'Empleados',
      descripcion: 'Gestión de empleados y permisos',
      activo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SystemModule(
      id: '5',
      nombre: 'Contabilidad',
      descripcion: 'Módulo contable y reportes',
      activo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SystemModule(
      id: '6',
      nombre: 'Reportes',
      descripcion: 'Reportes y análisis del sistema',
      activo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Obtiene todos los módulos del sistema
  Future<List<SystemModule>> getSystemModules() async {
    if (PlatformDetector.isWeb) {
      try {
        final data = await _supabaseClient.getSystemModules();
        return data.map((json) => SystemModule.fromJson(json)).toList();
      } catch (e) {
        return _modules; // Fallback a módulos en memoria
      }
    }
    return _modules;
  }

  /// Actualiza el estado de un módulo (activo/inactivo)
  Future<bool> toggleModule(String moduleId, bool activo) async {
    if (PlatformDetector.isWeb) {
      try {
        return await _supabaseClient.updateSystemModule(moduleId, {'activo': activo});
      } catch (e) {
        return false;
      }
    }

    // En memoria
    final index = _modules.indexWhere((m) => m.id == moduleId);
    if (index != -1) {
      _modules[index] = _modules[index].copyWith(activo: activo);
      return true;
    }
    return false;
  }

  /// Crea un nuevo usuario Administrador
  Future<UserModel?> createAdministrator({
    required String username,
    required String password,
    required String email,
    required String nombreCompleto,
  }) async {
    if (PlatformDetector.isWeb) {
      try {
        // Crear usuario en Supabase
        final success = await _supabaseClient.createUser({
          'username': username,
          'password': password,
          'email': email,
          'nombre_completo': nombreCompleto,
          'rol': 'admin',
          'activo': true,
        });

        if (success) {
          return UserModel(
            id: 0, // Se obtendrá de Supabase
            username: username,
            fullName: nombreCompleto,
            email: email,
            role: 'admin',
            isActive: true,
            password: password,
            createdAt: DateTime.now(),
          );
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Registra una acción en el audit log
  Future<bool> logAuditAction({
    required String usuarioId,
    required String nombreUsuario,
    required String tipo,
    required String descripcion,
    String? detalles,
    String estado = 'exitoso',
    String? motivo,
  }) async {
    final auditLog = AuditLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      usuarioId: usuarioId,
      nombreUsuario: nombreUsuario,
      tipo: tipo,
      descripcion: descripcion,
      detalles: detalles,
      estado: estado,
      motivo: motivo,
      fechaHora: DateTime.now(),
    );

    if (PlatformDetector.isWeb) {
      try {
        return await _supabaseClient.createAuditLog(auditLog.toJson());
      } catch (e) {
        return false;
      }
    }

    // En memoria (mock)
    return true;
  }

  /// Obtiene el historial de auditoría
  Future<List<AuditLog>> getAuditLog({
    int limit = 100,
    int offset = 0,
  }) async {
    if (PlatformDetector.isWeb) {
      try {
        final data = await _supabaseClient.getAuditLogs(limit: limit, offset: offset);
        return data.map((json) => AuditLog.fromJson(json)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Verifica si el usuario es SuperAdmin
  bool isSuperAdmin(UserModel? user) {
    return user != null && user.role == 'superadmin';
  }

  /// Verifica si el usuario es Administrador
  bool isAdministrator(UserModel? user) {
    return user != null && user.role == 'admin';
  }
}
