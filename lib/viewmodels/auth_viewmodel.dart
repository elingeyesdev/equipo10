import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get currentUserId => _authService.currentUserId;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  /// Intenta registrar un usuario. Retorna true si fue exitoso.
  Future<bool> registrar({
    required String email,
    required String password,
    required String nombreCompleto,
    required String telefono,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.registrar(
        email: email,
        password: password,
        nombreCompleto: nombreCompleto,
        telefono: telefono,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Intenta iniciar sesión. Retorna true si fue exitoso.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.login(email: email, password: password);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cierra la sesión actual.
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
