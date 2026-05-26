import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        throw Exception(response.data['message'] ?? 'Error al registrarse');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (statusCode == 422) {
        // Errores de validación (correo ya existe, teléfono inválido, etc.)
        final errors = data?['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstField = errors.values.first;
          final firstMsg = firstField is List ? firstField.first : firstField.toString();
          throw Exception(firstMsg.toString());
        }
        throw Exception('Datos inválidos. Verifica que tu correo no esté ya registrado.');
      }

      throw Exception(data?['message'] ?? 'Error de conexión. Intenta nuevamente.');
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
        throw Exception(response.data['message'] ?? 'Credenciales incorrectas');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (statusCode == 401) {
        throw Exception('Correo o contraseña incorrectos. Verifica tus datos e intenta de nuevo.');
      }
      if (statusCode == 403) {
        throw Exception('Tu cuenta está desactivada. Contacta al administrador.');
      }

      throw Exception(data?['message'] ?? 'Error de conexión. Intenta nuevamente.');
    }
  }

  /// Cierra la sesión (Limpia tokens locales).
  Future<void> logout() async {
    // Si tuviéramos un endpoint /auth/logout en Laravel, lo llamaríamos aquí.
    await _api.clearSession();
  }

  /// Cambia la contraseña del usuario.
  Future<bool> cambiarContrasena(String contrasenaActual, String nuevaContrasena) async {
    final id = currentUserId;
    if (id == null) throw Exception('No hay sesión activa.');

    try {
      final response = await _api.client.put('/auth/perfil/$id/password', data: {
        'contrasena_actual': contrasenaActual,
        'nueva_contrasena': nuevaContrasena,
      });
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('La contraseña actual es incorrecta.');
      }
      throw Exception(e.response?.data?['message'] ?? 'Error de conexión. Intenta nuevamente.');
    }
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

  /// Actualiza los datos del perfil (incluyendo habilidades)
  Future<bool> actualizarPerfil(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.client.put('/auth/perfil/$id', data: data);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Sube la imagen de avatar directamente al servidor Laravel.
  Future<String?> subirAvatarDirecto(String userId, String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'id': userId,
        'avatar': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _api.client.post(
        '/subir-avatar-directo',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['avatar_url'];
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[ERROR] Error subiendo avatar: ${e.response?.statusCode} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[ERROR] Error inesperado: $e');
      return null;
    }
  }
}
