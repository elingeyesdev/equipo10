import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../main.dart'; // Para apiUrl

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  String? _currentUserToken;
  String? _currentUserId;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Agregar Interceptor para enviar el token en cada petición automáticamente
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
        // Aquí podrías cerrar sesión si es 401
        return handler.next(e);
      }
    ));
    
    _initLocalSession();
  }

  Dio get client => _dio;
  
  String? get currentUserId => _currentUserId;

  Future<void> _initLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserToken = prefs.getString('auth_token');
    _currentUserId = prefs.getString('auth_userid');
  }

  Future<void> saveSession(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_userid', userId);
    _currentUserToken = token;
    _currentUserId = userId;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_userid');
    _currentUserToken = null;
    _currentUserId = null;
  }
}
