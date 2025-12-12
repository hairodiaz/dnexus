import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../../core/config/app_config.dart';

/// Cliente HTTP para Supabase (alternativa para web)
class SupabaseHttpClient {
  static final SupabaseHttpClient _instance = SupabaseHttpClient._internal();
  
  factory SupabaseHttpClient() => _instance;
  SupabaseHttpClient._internal();

  static const String supabaseUrl = 'https://xmoqjehicmqkseejreng.supabase.co';
  static const String anonKey = 'sb_publ1shabie_z1tR014T72qwqsCRF_8yg_rI13g1s';

  /// Headers requeridos para todas las peticiones
  Map<String, String> get _headers {
    return {
      'Authorization': 'Bearer $anonKey',
      'apikey': anonKey,
      'Content-Type': 'application/json',
    };
  }

  /// Login user
  Future<UserModel?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/users?select=*'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return UserModel.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      AppConfig.logger.e('Login error: $e');
      return null;
    }
  }

  /// Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/users?username=eq.$username&select=*'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return UserModel.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      AppConfig.logger.e('Get user error: $e');
      return null;
    }
  }

  /// Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/users?select=*'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((user) => UserModel.fromJson(user)).toList();
      }
      return [];
    } catch (e) {
      AppConfig.logger.e('Get all users error: $e');
      return [];
    }
  }

  /// Get clients from database
  Future<List<Map<String, dynamic>>> getClients() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/clientes?select=*'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      AppConfig.logger.e('Get clients error: $e');
      return [];
    }
  }

  /// Get products from database
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/productos?select=*'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      AppConfig.logger.e('Get products error: $e');
      return [];
    }
  }

  /// Get transactions from database
  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/transacciones?select=*'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      AppConfig.logger.e('Get transactions error: $e');
      return [];
    }
  }

  /// Create client
  Future<bool> createClient(Map<String, dynamic> clientData) async {
    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/clientes'),
        headers: _headers,
        body: jsonEncode(clientData),
      );

      return response.statusCode == 201;
    } catch (e) {
      AppConfig.logger.e('Create client error: $e');
      return false;
    }
  }

  /// Create product
  Future<bool> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/productos'),
        headers: _headers,
        body: jsonEncode(productData),
      );

      return response.statusCode == 201;
    } catch (e) {
      AppConfig.logger.e('Create product error: $e');
      return false;
    }
  }

  /// Create transaction
  Future<bool> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/transacciones'),
        headers: _headers,
        body: jsonEncode(transactionData),
      );

      return response.statusCode == 201;
    } catch (e) {
      AppConfig.logger.e('Create transaction error: $e');
      return false;
    }
  }

  /// Update client
  Future<bool> updateClient(String id, Map<String, dynamic> clientData) async {
    try {
      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/clientes?id=eq.$id'),
        headers: _headers,
        body: jsonEncode(clientData),
      );

      return response.statusCode == 200;
    } catch (e) {
      AppConfig.logger.e('Update client error: $e');
      return false;
    }
  }

  /// Update product
  Future<bool> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/productos?id=eq.$id'),
        headers: _headers,
        body: jsonEncode(productData),
      );

      return response.statusCode == 200;
    } catch (e) {
      AppConfig.logger.e('Update product error: $e');
      return false;
    }
  }

  /// Delete client (soft delete - set activo to false)
  Future<bool> deleteClient(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/clientes?id=eq.$id'),
        headers: _headers,
        body: jsonEncode({'activo': false}),
      );

      return response.statusCode == 200;
    } catch (e) {
      AppConfig.logger.e('Delete client error: $e');
      return false;
    }
  }

  /// Delete product (soft delete - set activo to false)
  Future<bool> deleteProduct(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/productos?id=eq.$id'),
        headers: _headers,
        body: jsonEncode({'activo': false}),
      );

      return response.statusCode == 200;
    } catch (e) {
      AppConfig.logger.e('Delete product error: $e');
      return false;
    }
  }

  /// Search clients by name
  Future<List<Map<String, dynamic>>> searchClients(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/clientes?or=(nombre_completo.ilike.%$query%,cedula.ilike.%$query%)'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      AppConfig.logger.e('Search clients error: $e');
      return [];
    }
  }

  /// Search products by name
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/productos?or=(nombre.ilike.%$query%,codigo.ilike.%$query%)'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      AppConfig.logger.e('Search products error: $e');
      return [];
    }
  }

  /// Get clients by business ID
  Future<List<Map<String, dynamic>>> getClientsByBusiness(String negocioId) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/clientes?negocio_id=eq.$negocioId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      AppConfig.logger.e('Get clients by business error: $e');
      return [];
    }
  }

  /// Get products by business ID
  Future<List<Map<String, dynamic>>> getProductsByBusiness(String negocioId) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/productos?negocio_id=eq.$negocioId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      AppConfig.logger.e('Get products by business error: $e');
      return [];
    }
  }

  /// Get transactions by business ID
  Future<List<Map<String, dynamic>>> getTransactionsByBusiness(String negocioId) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/transacciones?negocio_id=eq.$negocioId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      AppConfig.logger.e('Get transactions by business error: $e');
      return [];
    }
  }
}
