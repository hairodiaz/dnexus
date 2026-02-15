import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Servicio para persistir y restaurar la sesión del usuario
class SessionService {
  static const String _userSessionKey = 'dnexus_user_session';
  
  /// Guardar sesión del usuario
  static Future<void> saveSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userMap = user.toMap();
      final userJson = jsonEncode(userMap);
      await prefs.setString(_userSessionKey, userJson);
    } catch (e) {
      // Silenciar errores
    }
  }
  
  /// Restaurar sesión del usuario
  static Future<UserModel?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userSessionKey);
      
      if (userJson == null) {
        return null;
      }
      
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = UserModel.fromMap(userMap);
      return user;
    } catch (e) {
      return null;
    }
  }
  
  /// Limpiar sesión del usuario
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userSessionKey);
    } catch (e) {
      // Silenciar errores
    }
  }
  
  /// Verificar si hay sesión activa
  static Future<bool> hasSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userSessionKey);
    } catch (e) {
      return false;
    }
  }
}
