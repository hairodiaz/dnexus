import '../models/client_model.dart';

/// Servicio para gestionar clientes unificados
/// Maneja el CRUD y búsquedas de clientes compartidos entre negocios
class ClientService {
  static final ClientService _instance = ClientService._internal();
  factory ClientService() => _instance;
  ClientService._internal();

  // Base de datos simulada de clientes
  final List<ClientModel> _clients = [];
  int _nextId = 1;
  bool _isInitialized = false;

  /// Inicializa el servicio con datos de ejemplo
  void _initializeIfNeeded() {
    if (_isInitialized) return;

    _clients.addAll([
      ClientModel(
        id: 'CLI${_nextId++}',
        cedula: '001-1234567-8',
        nombreCompleto: 'Juan Pérez Martínez',
        telefono: '809-555-0001',
        email: 'juan.perez@email.com',
        direccion: 'Calle Principal #123, Santo Domingo',
        activo: true,
        fechaRegistro: DateTime.now().subtract(const Duration(days: 30)),
        negociosAsociados: ['repuestos', 'electrodomesticos'],
      ),
      ClientModel(
        id: 'CLI${_nextId++}',
        cedula: '001-2345678-9',
        nombreCompleto: 'María García López',
        telefono: '809-555-0002',
        email: 'maria.garcia@email.com',
        direccion: 'Av. Independencia #456, Santo Domingo',
        activo: true,
        fechaRegistro: DateTime.now().subtract(const Duration(days: 25)),
        negociosAsociados: ['electrodomesticos'],
      ),
      ClientModel(
        id: 'CLI${_nextId++}',
        cedula: '001-3456789-0',
        nombreCompleto: 'Carlos Martínez Rodríguez',
        telefono: '809-555-0003',
        email: 'carlos.martinez@email.com',
        direccion: 'Calle Duarte #789, Santiago',
        activo: true,
        fechaRegistro: DateTime.now().subtract(const Duration(days: 20)),
        negociosAsociados: ['repuestos'],
      ),
      ClientModel(
        id: 'CLI${_nextId++}',
        cedula: '001-4567890-1',
        nombreCompleto: 'Ana López Fernández',
        telefono: '809-555-0004',
        email: 'ana.lopez@email.com',
        direccion: 'Av. 27 de Febrero #321, Santo Domingo',
        activo: true,
        fechaRegistro: DateTime.now().subtract(const Duration(days: 15)),
        negociosAsociados: ['prestamos'],
      ),
      ClientModel(
        id: 'CLI${_nextId++}',
        cedula: '001-5678901-2',
        nombreCompleto: 'Pedro Rodríguez Santos',
        telefono: '809-555-0005',
        email: 'pedro.rodriguez@email.com',
        direccion: 'Calle Mella #654, La Romana',
        activo: true,
        fechaRegistro: DateTime.now().subtract(const Duration(days: 10)),
        negociosAsociados: ['repuestos', 'electrodomesticos', 'prestamos'],
      ),
    ]);

    _isInitialized = true;
  }

  /// Obtiene todos los clientes activos
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

  /// Obtiene clientes de un negocio específico
  List<ClientModel> getClientsByBusiness(String business) {
    return _clients.where((client) =>
      client.activo && client.estaEnNegocio(business)
    ).toList();
  }

  /// Registra un nuevo cliente
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
    if (_clients.isNotEmpty) return;

    // Clientes de ejemplo para cada negocio
    final defaultClients = [
      {
        'cedula': '12345678901',
        'nombre': 'Juan Carlos Pérez',
        'telefono': '809-555-0101',
        'email': 'juan.perez@email.com',
        'direccion': 'Calle Principal #123, Santiago',
        'negocio': 'repuestos',
      },
      {
        'cedula': '10987654321',
        'nombre': 'María José González',
        'telefono': '829-555-0202',
        'email': 'maria.gonzalez@email.com',
        'direccion': 'Av. Independencia #456, Santo Domingo',
        'negocio': 'electrodomesticos',
      },
      {
        'cedula': '45678912345',
        'nombre': 'Roberto Antonio Martínez',
        'telefono': '849-555-0303',
        'direccion': 'Sector Los Alcarrizos #789',
        'negocio': 'repuestos',
      },
      {
        'cedula': '32165498701',
        'nombre': 'Carmen Rosa Jiménez',
        'telefono': '809-555-0404',
        'email': 'carmen.jimenez@email.com',
        'negocio': 'prestamos',
      },
      {
        'cedula': '78912345603',
        'nombre': 'Luis Fernando Rodríguez',
        'telefono': '829-555-0505',
        'direccion': 'Calle Duarte #321, La Vega',
        'negocio': 'electrodomesticos',
      },
    ];

    for (final clientData in defaultClients) {
      try {
        registerClient(
          cedula: clientData['cedula']!,
          nombreCompleto: clientData['nombre']!,
          telefono: clientData['telefono']!,
          email: clientData['email'],
          direccion: clientData['direccion'],
          negocioInicial: clientData['negocio'],
        );
      } catch (e) {
        // Ignorar duplicados
      }
    }
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