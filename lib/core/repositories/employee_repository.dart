import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/employee_model.dart';
import '../../shared/models/role_model.dart';

/// Repositorio para gestionar empleados en Supabase
class EmployeeRepository {
  final SupabaseClient client;

  EmployeeRepository({required this.client});

  /// Obtener todos los empleados de un negocio
  Future<List<EmployeeModel>> getEmployeesByBusiness(int businessId) async {
    try {
      final response = await client
          .from('empleados')
          .select()
          .eq('negocio_id', businessId)
          .order('nombre');

      final employees = (response as List)
          .map((e) => EmployeeModel.fromJson(e))
          .toList();

      // Cargar roles para cada empleado
      for (var employee in employees) {
        employee.roles = await getRolesForEmployee(employee.id);
        employee.tieneUsuarioSistema = await _checkIfHasSystemUser(employee.id);
      }

      return employees;
    } catch (e) {
      print('Error fetching employees: $e');
      rethrow;
    }
  }

  /// Obtener un empleado por ID
  Future<EmployeeModel?> getEmployeeById(int employeeId) async {
    try {
      final response = await client
          .from('empleados')
          .select()
          .eq('id', employeeId)
          .single();

      final employee = EmployeeModel.fromJson(response);
      employee.roles = await getRolesForEmployee(employeeId);
      employee.tieneUsuarioSistema = await _checkIfHasSystemUser(employeeId);

      return employee;
    } catch (e) {
      print('Error fetching employee by id: $e');
      return null;
    }
  }

  /// Obtener roles asignados a un empleado
  Future<List<RoleModel>> getRolesForEmployee(int employeeId) async {
    try {
      final response = await client
          .from('empleado_roles')
          .select('role_id, roles(*)')
          .eq('empleado_id', employeeId);

      final roles = <RoleModel>[];
      for (var item in response as List) {
        final roleData = item['roles'];
        if (roleData != null) {
          final role = RoleModel.fromJson(roleData as Map<String, dynamic>);
          // Cargar módulos del rol
          role.moduloIds = await getModulosForRole(role.id);
          roles.add(role);
        }
      }

      return roles;
    } catch (e) {
      print('Error fetching roles for employee: $e');
      return [];
    }
  }

  /// Obtener módulos permitidos para un rol
  Future<List<int>> getModulosForRole(int roleId) async {
    try {
      final response = await client
          .from('role_modulos')
          .select('modulo_id')
          .eq('role_id', roleId);

      return (response as List)
          .map((m) => m['modulo_id'] as int)
          .toList();
    } catch (e) {
      print('Error fetching modulos for role: $e');
      return [];
    }
  }

  /// Crear un nuevo empleado
  Future<EmployeeModel?> createEmployee({
    required int businessId,
    required String nombre,
    String? numeroDocumento,
    String? email,
    String? telefono,
    String? cargo,
    List<int> roleIds = const [],
  }) async {
    try {
      // 1. Crear empleado
      final employeeData = {
        'negocio_id': businessId,
        'nombre': nombre,
        'numero_documento': numeroDocumento,
        'email': email,
        'telefono': telefono,
        'cargo': cargo,
        'estado': true,
      };

      final employeeResponse = await client
          .from('empleados')
          .insert(employeeData)
          .select()
          .single();

      final employeeId = employeeResponse['id'] as int;

      // 2. Asignar roles si existen
      if (roleIds.isNotEmpty) {
        for (var roleId in roleIds) {
          await client.from('empleado_roles').insert({
            'empleado_id': employeeId,
            'role_id': roleId,
          });
        }
      }

      return await getEmployeeById(employeeId);
    } catch (e) {
      print('Error creating employee: $e');
      rethrow;
    }
  }

  /// Actualizar un empleado
  Future<bool> updateEmployee({
    required int employeeId,
    required String nombre,
    String? numeroDocumento,
    String? email,
    String? telefono,
    String? cargo,
  }) async {
    try {
      await client.from('empleados').update({
        'nombre': nombre,
        'numero_documento': numeroDocumento,
        'email': email,
        'telefono': telefono,
        'cargo': cargo,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', employeeId);

      return true;
    } catch (e) {
      print('Error updating employee: $e');
      return false;
    }
  }

  /// Actualizar roles de un empleado
  Future<bool> updateEmployeeRoles({
    required int employeeId,
    required List<int> newRoleIds,
  }) async {
    try {
      // 1. Eliminar roles existentes
      await client
          .from('empleado_roles')
          .delete()
          .eq('empleado_id', employeeId);

      // 2. Agregar nuevos roles
      if (newRoleIds.isNotEmpty) {
        final rolesData = newRoleIds
            .map((roleId) => {
              'empleado_id': employeeId,
              'role_id': roleId,
            })
            .toList();

        await client.from('empleado_roles').insert(rolesData);
      }

      return true;
    } catch (e) {
      print('Error updating employee roles: $e');
      return false;
    }
  }

  /// Desactivar/Activar empleado
  Future<bool> toggleEmployeeStatus(int employeeId, bool newStatus) async {
    try {
      await client.from('empleados').update({
        'estado': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', employeeId);

      return true;
    } catch (e) {
      print('Error toggling employee status: $e');
      return false;
    }
  }

  /// Crear usuario del sistema para un empleado
  Future<bool> createSystemUserForEmployee({
    required int employeeId,
    required int userId,
  }) async {
    try {
      await client.from('empleado_usuarios').insert({
        'empleado_id': employeeId,
        'usuario_id': userId,
      });

      return true;
    } catch (e) {
      print('Error creating system user for employee: $e');
      return false;
    }
  }

  /// Remover usuario del sistema de un empleado
  Future<bool> removeSystemUserFromEmployee(int employeeId) async {
    try {
      await client
          .from('empleado_usuarios')
          .delete()
          .eq('empleado_id', employeeId);

      return true;
    } catch (e) {
      print('Error removing system user from employee: $e');
      return false;
    }
  }

  /// Verificar si un empleado tiene usuario del sistema
  Future<bool> _checkIfHasSystemUser(int employeeId) async {
    try {
      final response = await client
          .from('empleado_usuarios')
          .select()
          .eq('empleado_id', employeeId);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtener todos los roles de un negocio
  Future<List<RoleModel>> getRolesByBusiness(int businessId) async {
    try {
      final response = await client
          .from('roles')
          .select()
          .eq('negocio_id', businessId)
          .eq('estado', true)
          .order('nombre');

      final roles = <RoleModel>[];
      for (var roleData in response as List) {
        final role = RoleModel.fromJson(roleData);
        role.moduloIds = await getModulosForRole(role.id);
        roles.add(role);
      }

      return roles;
    } catch (e) {
      print('Error fetching roles by business: $e');
      return [];
    }
  }

  /// Crear un nuevo rol en un negocio
  Future<RoleModel?> createRole({
    required int businessId,
    required String nombre,
    String? descripcion,
    List<int> moduloIds = const [],
  }) async {
    try {
      // 1. Crear rol
      final roleData = {
        'negocio_id': businessId,
        'nombre': nombre,
        'descripcion': descripcion,
        'estado': true,
      };

      final roleResponse = await client
          .from('roles')
          .insert(roleData)
          .select()
          .single();

      final roleId = roleResponse['id'] as int;

      // 2. Asignar módulos si existen
      if (moduloIds.isNotEmpty) {
        final modulosData = moduloIds
            .map((moduloId) => {
              'role_id': roleId,
              'modulo_id': moduloId,
            })
            .toList();

        await client.from('role_modulos').insert(modulosData);
      }

      final role = RoleModel.fromJson(roleResponse);
      role.moduloIds = moduloIds;
      return role;
    } catch (e) {
      print('Error creating role: $e');
      rethrow;
    }
  }

  /// Obtener todos los módulos del sistema por sistema
  Future<List<Map<String, dynamic>>> getModulesBySistema(String sistema) async {
    try {
      final response = await client
          .from('system_modules')
          .select()
          .eq('sistema', sistema)
          .eq('estado', true)
          .order('nombre');

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error fetching modules by sistema: $e');
      return [];
    }
  }
}
