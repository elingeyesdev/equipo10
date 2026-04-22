import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// URL base de la API de Laravel (definida en main.dart)
const String _kApiUrl = 'http://localhost:8081/api';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _kApiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Interceptor que inyecta el token JWT en cada petición
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        debugPrint('API_ERROR: ${e.response?.statusCode} - ${e.message}');
        return handler.next(e);
      },
    ));
  }

  Dio get client => _dio;

  /// Siempre lee el userId fresco desde SharedPreferences
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_userid');
  }

  /// Getter sincrónico para compatibilidad (lee desde cache en memoria)
  String? get currentUserId => _cachedUserId;
  String? _cachedUserId;

  Future<void> saveSession(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_userid', userId);
    _cachedUserId = userId;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_userid');
    _cachedUserId = null;
  }

  /// Carga el userId desde disco al iniciar la app
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = prefs.getString('auth_userid');
  }
}
