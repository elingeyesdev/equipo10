import 'dart:async';
import 'package:dio/dio.dart';
import '../models/perfil_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  String? get currentUserId => _api.currentUserId;

  // En Laravel, la autenticación vía token no persiste un "stream" activo como Firebase/Supabase,
  // se basa en que el token siga vivo y guardado.

  /// Registra un usuario nuevo en Laravel.
  Future<void> registrar({
    required String email,
    required String password,
    required String nombreCompleto,
    required String telefono,
  }) async {
    try {
      final response = await _api.client.post('/auth/register', data: {
        'nombre': nombreCompleto,
        'email': email,
        'contrasena': password,
        'telefono': telefono,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        final token = response.data['data']['token'];
        final user = response.data['data']['usuario'];
        await _api.saveSession(token, user['id']);
      } else {
        throw Exception(response.data['message'] ?? 'Error desconocido');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  /// Inicia sesión enviando credenciales a Laravel.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.client.post('/auth/login', data: {
        'email': email,
        'contrasena': password,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['data']['token'];
        final user = response.data['data']['usuario'];
        await _api.saveSession(token, user['id']);
      } else {
        throw Exception(response.data['message'] ?? 'Logueo fallido');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  /// Cierra la sesión (Limpia tokens locales).
  Future<void> logout() async {
    // Si tuviéramos un endpoint /auth/logout en Laravel, lo llamaríamos aquí.
    await _api.clearSession();
  }

  /// Obtiene el perfil del usuario utilizando desde Laravel.
  Future<PerfilModel?> obtenerPerfilActual() async {
    final id = currentUserId;
    if (id == null) return null;

    try {
      final response = await _api.client.get('/auth/perfil/$id');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data'];
        return PerfilModel.fromMap(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
