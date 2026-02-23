import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/business_model_new.dart';
import '../../shared/models/contact_model.dart';
import '../../shared/models/address_model.dart';

/// Repositorio para gestionar negocios en Supabase
class BusinessRepository {
  final SupabaseClient client;

  BusinessRepository({required this.client});

  /// Obtener todos los negocios del admin actual
  Future<List<BusinessModel>> getBusinessesByAdmin(int adminId) async {
    try {
      final response = await client
          .from('negocios')
          .select()
          .eq('created_by', adminId)
          .order('nombre');

      final businesses =
          (response as List).map((b) => BusinessModel.fromJson(b)).toList();

      // Cargar contactos y direcciones para cada negocio
      for (var business in businesses) {
        business.contactos = await getContactos(business.id);
        business.direcciones = await getDirecciones(business.id);
      }

      return businesses;
    } catch (e) {
      print('Error fetching businesses: $e');
      rethrow;
    }
  }

  /// Obtener un negocio por ID
  Future<BusinessModel?> getBusinessById(int businessId) async {
    try {
      final response =
          await client.from('negocios').select().eq('id', businessId).single();

      final business = BusinessModel.fromJson(response);
      business.contactos = await getContactos(businessId);
      business.direcciones = await getDirecciones(businessId);

      return business;
    } catch (e) {
      print('Error fetching business by id: $e');
      return null;
    }
  }

  /// Crear un nuevo negocio
  Future<BusinessModel?> createBusiness({
    required String nombre,
    String? nit,
    DateTime? fechaRegistro,
    required int adminId,
    String sistema = 'Repuesto',
    List<ContactModel> contactos = const [],
    List<AddressModel> direcciones = const [],
  }) async {
    try {
      // 1. Crear negocio
      final businessData = {
        'nombre': nombre,
        'nit': nit,
        'fecha_registro':
            fechaRegistro?.toIso8601String().split('T').first,
        'estado': true,
        'created_by': adminId,
        'sistema': sistema,
      };

      final businessResponse =
          await client.from('negocios').insert(businessData).select().single();

      final businessId = businessResponse['id'] as int;

      // 2. Crear contactos si existen
      if (contactos.isNotEmpty) {
        for (var contact in contactos) {
          await client.from('negocio_contactos').insert({
            'negocio_id': businessId,
            'tipo': contact.tipo,
            'valor': contact.valor,
            'principal': contact.principal,
          });
        }
      }

      // 3. Crear direcciones si existen
      if (direcciones.isNotEmpty) {
        for (var address in direcciones) {
          await client.from('negocio_direcciones').insert({
            'negocio_id': businessId,
            'tipo': address.tipo,
            'calle': address.calle,
            'ciudad': address.ciudad,
            'departamento': address.departamento,
            'codigo_postal': address.codigoPostal,
            'principal': address.principal,
          });
        }
      }

      // 4. Crear relación admin-negocio
      await client.from('admin_negocio').insert({
        'admin_id': adminId,
        'negocio_id': businessId,
        'rol': 'propietario',
      });

      return await getBusinessById(businessId);
    } catch (e) {
      print('Error creating business: $e');
      rethrow;
    }
  }

  /// Actualizar un negocio
  Future<bool> updateBusiness({
    required int businessId,
    required String nombre,
    String? nit,
    DateTime? fechaRegistro,
    String? sistema,
  }) async {
    try {
      final updateData = {
        'nombre': nombre,
        'nit': nit,
        'fecha_registro': fechaRegistro?.toIso8601String().split('T').first,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (sistema != null) {
        updateData['sistema'] = sistema;
      }

      await client.from('negocios').update(updateData).eq('id', businessId);

      return true;
    } catch (e) {
      print('Error updating business: $e');
      return false;
    }
  }

  /// Desactivar/Activar un negocio (soft delete)
  Future<bool> toggleBusinessStatus(int businessId, bool newStatus) async {
    try {
      await client.from('negocios').update({
        'estado': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', businessId);

      return true;
    } catch (e) {
      print('Error toggling business status: $e');
      return false;
    }
  }

  /// Obtener contactos de un negocio
  Future<List<ContactModel>> getContactos(int businessId) async {
    try {
      final response = await client
          .from('negocio_contactos')
          .select()
          .eq('negocio_id', businessId);

      return (response as List)
          .map((c) => ContactModel.fromJson(c))
          .toList();
    } catch (e) {
      print('Error fetching contacts: $e');
      return [];
    }
  }

  /// Agregar contacto a un negocio
  Future<bool> addContact({
    required int businessId,
    required String tipo,
    required String valor,
    required bool principal,
  }) async {
    try {
      // Si este contacto es principal, desmarcar otros del mismo tipo
      if (principal) {
        await client
            .from('negocio_contactos')
            .update({'principal': false})
            .eq('negocio_id', businessId)
            .eq('tipo', tipo);
      }

      await client.from('negocio_contactos').insert({
        'negocio_id': businessId,
        'tipo': tipo,
        'valor': valor,
        'principal': principal,
      });

      return true;
    } catch (e) {
      print('Error adding contact: $e');
      return false;
    }
  }

  /// Eliminar contacto
  Future<bool> deleteContact(int contactId) async {
    try {
      await client.from('negocio_contactos').delete().eq('id', contactId);
      return true;
    } catch (e) {
      print('Error deleting contact: $e');
      return false;
    }
  }

  /// Obtener direcciones de un negocio
  Future<List<AddressModel>> getDirecciones(int businessId) async {
    try {
      final response = await client
          .from('negocio_direcciones')
          .select()
          .eq('negocio_id', businessId);

      return (response as List)
          .map((d) => AddressModel.fromJson(d))
          .toList();
    } catch (e) {
      print('Error fetching addresses: $e');
      return [];
    }
  }

  /// Agregar dirección a un negocio
  Future<bool> addAddress({
    required int businessId,
    required String tipo,
    required String calle,
    String? ciudad,
    String? departamento,
    String? codigoPostal,
    required bool principal,
  }) async {
    try {
      // Si esta dirección es principal, desmarcar otras
      if (principal) {
        await client
            .from('negocio_direcciones')
            .update({'principal': false})
            .eq('negocio_id', businessId);
      }

      await client.from('negocio_direcciones').insert({
        'negocio_id': businessId,
        'tipo': tipo,
        'calle': calle,
        'ciudad': ciudad,
        'departamento': departamento,
        'codigo_postal': codigoPostal,
        'principal': principal,
      });

      return true;
    } catch (e) {
      print('Error adding address: $e');
      return false;
    }
  }

  /// Eliminar dirección
  Future<bool> deleteAddress(int addressId) async {
    try {
      await client.from('negocio_direcciones').delete().eq('id', addressId);
      return true;
    } catch (e) {
      print('Error deleting address: $e');
      return false;
    }
  }
}
