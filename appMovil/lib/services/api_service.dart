import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

const String _kApiUrl = 'http://10.26.12.209:8081';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _kApiUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Interceptor que inyecta el token JWT en cada petición
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Asegurar que todas las peticiones lleven el prefijo /api
        if (!options.path.startsWith('/api/')) {
          String path = options.path;
          if (!path.startsWith('/')) path = '/$path';
          options.path = '/api$path';
        }

        final fullUrl = '${options.baseUrl}${options.path}';
        debugPrint(' API Request: [${options.method}] $fullUrl');
        
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        final fullUrl = '${e.requestOptions.baseUrl}${e.requestOptions.path}';
        debugPrint(' API_ERROR [${e.response?.statusCode}]: $fullUrl');
        return handler.next(e);
      },
    ));
  }

  Dio get client => _dio;
  String get baseUrl => _kApiUrl;

  /// Retorna solo el host (ej: http://192.168.1.10:8081) sin el /api
  String get apiHost {
    final uri = Uri.parse(_kApiUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

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
