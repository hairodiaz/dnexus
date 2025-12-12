import '../models/client_model.dart';
import '../../core/utils/platform_detector.dart';
import 'supabase_http_client.dart';

/// Servicio para gestionar clientes unificados
/// Maneja el CRUD y búsquedas de clientes compartidos entre negocios
class ClientService {
  static final ClientService _instance = ClientService._internal();
  factory ClientService() => _instance;
  ClientService._internal();

  // Base de datos simulada de clientes (para nativo)
  final List<ClientModel> _clients = [];
  int _nextId = 1;
  bool _isInitialized = false;
  
  // Cliente HTTP Supabase
  final SupabaseHttpClient _supabaseClient = SupabaseHttpClient();

  /// Inicializa el servicio con datos de ejemplo
  void _initializeIfNeeded() {
    if (_isInitialized) return;

    _clients.addAll([
      // Sample clients disabled - clean system mode
    ]);

    _isInitialized = true;
  }

  /// Obtiene todos los clientes activos
  Future<List<ClientModel>> getAllClientsAsync() async {
    // En web, obtener de Supabase
    if (PlatformDetector.isWeb) {
      try {
        final data = await _supabaseClient.getClients();
        return data.map((json) => ClientModel.fromJson(json)).toList();
      } catch (e) {
        return [];
      }
    }

    // En nativo, usar lista en memoria
    _initializeIfNeeded();
    return _clients.where((client) => client.activo).toList();
  }

  /// Obtiene todos los clientes (versión sincrónica para compatibilidad)
  List<ClientModel> getAllClients() {
    _initializeIfNeeded();
    return _clients.where((client) => client.activo).toList();
  }

  /// Busca clientes por cédula (exacta)
  ClientModel? findByCedula(String cedula) {
    _initializeIfNeeded();
    try {
      return _clients.firstWhere(
        (client) => client.cedula == cedula && client.activo,
      );
    } catch (e) {
      return null;
    }
  }

  /// Busca clientes por nombre (parcial, case-insensitive)
  List<ClientModel> searchByName(String query) {
    _initializeIfNeeded();
    if (query.isEmpty) return getAllClients();
    
    final queryLower = query.toLowerCase();
    return _clients.where((client) =>
      client.activo &&
      client.nombreCompleto.toLowerCase().contains(queryLower)
    ).toList();
  }

  /// Busca clientes por teléfono (parcial)
  List<ClientModel> searchByPhone(String phone) {
    _initializeIfNeeded();
    if (phone.isEmpty) return [];
    
    return _clients.where((client) =>
      client.activo &&
      client.telefono.contains(phone)
    ).toList();
  }

  /// Búsqueda general (cédula, nombre o teléfono)
  List<ClientModel> search(String query) {
    if (query.isEmpty) return getAllClients();

    final queryLower = query.toLowerCase();
    return _clients.where((client) =>
      client.activo && (
        client.cedula.contains(queryLower) ||
        client.nombreCompleto.toLowerCase().contains(queryLower) ||
        client.telefono.contains(query)
      )
    ).toList();
  }

  /// Búsqueda asincrónica (usa Supabase en web)
  Future<List<ClientModel>> searchAsync(String query) async {
    if (query.isEmpty) return getAllClientsAsync();

    // En web, usar Supabase
    if (PlatformDetector.isWeb) {
      try {
        final data = await _supabaseClient.searchClients(query);
        return data.map((json) => ClientModel.fromJson(json)).toList();
      } catch (e) {
        return [];
      }
    }

    // En nativo, usar búsqueda local
    return search(query);
  }

  /// Obtiene clientes de un negocio específico
  List<ClientModel> getClientsByBusiness(String business) {
    return _clients.where((client) =>
      client.activo && client.estaEnNegocio(business)
    ).toList();
  }

  /// Obtiene clientes de un negocio específico (asincrónico, usa Supabase en web)
  Future<List<ClientModel>> getClientsByBusinessAsync(String negocioId) async {
    // En web, usar Supabase
    if (PlatformDetector.isWeb) {
      try {
        final data = await _supabaseClient.getClientsByBusiness(negocioId);
        return data.map((json) => ClientModel.fromJson(json)).toList();
      } catch (e) {
        return [];
      }
    }

    // En nativo, usar búsqueda local
    return getClientsByBusiness(negocioId);
  }

  /// Registra un nuevo cliente
  Future<ClientModel?> registerClientAsync({
    required String cedula,
    required String nombreCompleto,
    required String telefono,
    String? email,
    String? direccion,
    String? negocioInicial,
  }) async {
    // En web, usar Supabase
    if (PlatformDetector.isWeb) {
      try {
        final success = await _supabaseClient.createClient({
          'cedula': cedula,
          'nombre_completo': nombreCompleto,
          'telefono': telefono,
          'email': email,
          'direccion': direccion,
        });
        
        if (success) {
          return ClientModel(
            id: (_nextId++).toString(),
            cedula: cedula,
            nombreCompleto: nombreCompleto,
            telefono: telefono,
            email: email,
            direccion: direccion,
            fechaRegistro: DateTime.now(),
            activo: true,
          );
        }
      } catch (e) {
        return null;
      }
    }

    // En nativo, usar lista en memoria
    return registerClient(
      cedula: cedula,
      nombreCompleto: nombreCompleto,
      telefono: telefono,
      email: email,
      direccion: direccion,
      negocioInicial: negocioInicial,
    );
  }

  /// Registra un nuevo cliente (sincrónico para compatibilidad)
  ClientModel registerClient({
    required String cedula,
    required String nombreCompleto,
    required String telefono,
    String? email,
    String? direccion,
    String? negocioInicial,
  }) {
    // Validar que no exista la cédula
    if (findByCedula(cedula) != null) {
      throw Exception('Ya existe un cliente con la cédula $cedula');
    }

    // Crear nuevo cliente
    final client = ClientModel(
      id: _nextId.toString(),
      cedula: cedula,
      nombreCompleto: nombreCompleto,
      telefono: telefono,
      email: email,
      direccion: direccion,
      fechaRegistro: DateTime.now(),
      negociosAsociados: negocioInicial != null ? [negocioInicial] : [],
    );

    _clients.add(client);
    _nextId++;
    
    return client;
  }

  /// Actualiza un cliente existente
  ClientModel updateClient(String cedula, {
    String? nombreCompleto,
    String? telefono,
    String? email,
    String? direccion,
  }) {
    final client = findByCedula(cedula);
    if (client == null) {
      throw Exception('Cliente con cédula $cedula no encontrado');
    }

    final updatedClient = client.copyWith(
      nombreCompleto: nombreCompleto,
      telefono: telefono,
      email: email,
      direccion: direccion,
    );

    final index = _clients.indexWhere((c) => c.cedula == cedula);
    _clients[index] = updatedClient;
    
    return updatedClient;
  }

  /// Asocia un cliente a un nuevo negocio
  ClientModel addClientToBusiness(String cedula, String business) {
    final client = findByCedula(cedula);
    if (client == null) {
      throw Exception('Cliente con cédula $cedula no encontrado');
    }

    final updatedClient = client.agregarNegocio(business);
    final index = _clients.indexWhere((c) => c.cedula == cedula);
    _clients[index] = updatedClient;
    
    return updatedClient;
  }

  /// Actualiza la última compra del cliente
  ClientModel updateLastPurchase(String cedula, {
    DateTime? fecha,
    double? monto,
  }) {
    final client = findByCedula(cedula);
    if (client == null) {
      throw Exception('Cliente con cédula $cedula no encontrado');
    }

    final updatedClient = client.copyWith(
      ultimaCompra: fecha ?? DateTime.now(),
      totalCompras: monto != null 
        ? (client.totalCompras ?? 0) + monto 
        : client.totalCompras,
    );

    final index = _clients.indexWhere((c) => c.cedula == cedula);
    _clients[index] = updatedClient;
    
    return updatedClient;
  }

  /// Desactiva un cliente (soft delete)
  void deactivateClient(String cedula) {
    final client = findByCedula(cedula);
    if (client == null) {
      throw Exception('Cliente con cédula $cedula no encontrado');
    }

    final updatedClient = client.copyWith(activo: false);
    final index = _clients.indexWhere((c) => c.cedula == cedula);
    _clients[index] = updatedClient;
  }

  /// Desactiva un cliente de forma asincrónica (usa Supabase en web)
  Future<bool> deactivateClientAsync(String clientId) async {
    // En web, usar Supabase
    if (PlatformDetector.isWeb) {
      try {
        return await _supabaseClient.deleteClient(clientId);
      } catch (e) {
        return false;
      }
    }

    // En nativo, usar desactivación local
    try {
      final client = _clients.firstWhere((c) => c.id == clientId);
      deactivateClient(client.cedula);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Actualiza un cliente de forma asincrónica (usa Supabase en web)
  Future<bool> updateClientAsync(String clientId, {
    String? nombreCompleto,
    String? telefono,
    String? email,
    String? direccion,
  }) async {
    // En web, usar Supabase
    if (PlatformDetector.isWeb) {
      try {
        final updateData = <String, dynamic>{};
        if (nombreCompleto != null) updateData['nombre_completo'] = nombreCompleto;
        if (telefono != null) updateData['telefono'] = telefono;
        if (email != null) updateData['email'] = email;
        if (direccion != null) updateData['direccion'] = direccion;
        
        return await _supabaseClient.updateClient(clientId, updateData);
      } catch (e) {
        return false;
      }
    }

    // En nativo, usar actualización local
    try {
      final client = _clients.firstWhere((c) => c.id == clientId);
      updateClient(client.cedula,
        nombreCompleto: nombreCompleto,
        telefono: telefono,
        email: email,
        direccion: direccion,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Valida formato de cédula (básico)
  bool isValidCedula(String cedula) {
    // Remover espacios y guiones
    final cleaned = cedula.replaceAll(RegExp(r'[\s-]'), '');
    
    // Debe tener entre 7 y 11 dígitos
    return RegExp(r'^\d{7,11}$').hasMatch(cleaned);
  }

  /// Formatea cédula para mostrar
  String formatCedula(String cedula) {
    final cleaned = cedula.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length >= 8) {
      return '${cleaned.substring(0, cleaned.length - 3)}-${cleaned.substring(cleaned.length - 3)}';
    }
    return cleaned;
  }

  /// Inicializa datos de ejemplo
  void initializeDefaultClients() {
    // Sample clients disabled - clean system mode
    // All clients must be created manually
  }

  /// Obtiene estadísticas de clientes
  Map<String, dynamic> getClientStats() {
    final activeClients = getAllClients();
    
    return {
      'total_clientes': activeClients.length,
      'clientes_repuestos': getClientsByBusiness('repuestos').length,
      'clientes_electrodomesticos': getClientsByBusiness('electrodomesticos').length,
      'clientes_prestamos': getClientsByBusiness('prestamos').length,
      'clientes_multiples': activeClients.where((c) => c.negociosAsociados.length > 1).length,
    };
  }

  /// Actualizar información de última compra del cliente
  static Future<void> updateClientPurchase(String clientId, double amount, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final service = ClientService();
    final clientIndex = service._clients.indexWhere((c) => c.id == int.parse(clientId));
    
    if (clientIndex != -1) {
      // Actualizar cliente con nueva compra
      // En una implementación real, esto actualizaría campos como:
      // - ultimaCompra: date
      // - totalCompras: amount + previousTotal
      // Por ahora es solo simulación
      print('Cliente $clientId actualizado - Compra: \$${amount.toStringAsFixed(0)} en $date');
    }
  }
}