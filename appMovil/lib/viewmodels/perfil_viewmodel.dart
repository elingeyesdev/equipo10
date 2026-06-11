import 'package:flutter/material.dart';
import '../models/perfil_model.dart';
import '../services/auth_service.dart';

class PerfilViewModel extends ChangeNotifier {
  final AuthService _authService;

  PerfilViewModel(this._authService);

  PerfilModel? _perfil;
  bool _isLoading = false;
  String? _errorMessage;

  PerfilModel? get perfil => _perfil;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carga el perfil actual desde el backend
  Future<void> cargarPerfil() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final perfilCargado = await _authService.obtenerPerfilActual();
      if (perfilCargado != null) {
        _perfil = perfilCargado;
      } else {
        _errorMessage = 'No se pudo cargar el perfil.';
      }
    } catch (e) {
      _errorMessage = 'Error al cargar perfil: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Añade una habilidad a la lista existente y guarda en backend
  Future<bool> agregarHabilidad(String nuevaHabilidad) async {
    if (_perfil == null || _authService.currentUserId == null) return false;

    // Evitar duplicados
    if (_perfil!.habilidades.contains(nuevaHabilidad)) return true;

    final nuevasHabilidades = List<String>.from(_perfil!.habilidades)
      ..add(nuevaHabilidad);
    return await _guardarHabilidades(nuevasHabilidades);
  }

  /// Elimina una habilidad de la lista y guarda en backend
  Future<bool> eliminarHabilidad(String habilidad) async {
    if (_perfil == null || _authService.currentUserId == null) return false;

    final nuevasHabilidades = List<String>.from(_perfil!.habilidades)
      ..remove(habilidad);
    return await _guardarHabilidades(nuevasHabilidades);
  }

  /// Helper para enviar las habilidades al backend
  Future<bool> _guardarHabilidades(List<String> habilidades) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _authService.actualizarPerfil(
        _authService.currentUserId!,
        {'habilidades': habilidades},
      );

      if (success) {
        // Recargar perfil completo para tener datos frescos
        await cargarPerfil();
        return true;
      } else {
        _errorMessage = 'Error al guardar habilidades.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Excepción al guardar habilidades: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza los datos básicos (nombre, teléfono)
  Future<bool> actualizarDatosPersonales(
      String nombre, String? telefono) async {
    if (_authService.currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.actualizarPerfil(
        _authService.currentUserId!,
        {
          'nombre': nombre,
          'telefono': telefono ?? '',
        },
      );

      if (success) {
        await cargarPerfil();
        return true;
      } else {
        _errorMessage = 'Error al actualizar datos personales.';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cambia la contraseña
  Future<bool> cambiarContrasena(String actual, String nueva) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.cambiarContrasena(actual, nueva);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza el avatar del usuario
  Future<bool> actualizarAvatar(String filePath) async {
    if (_authService.currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final avatarUrl = await _authService.subirAvatarDirecto(
          _authService.currentUserId!, filePath);
      if (avatarUrl != null) {
        await cargarPerfil();
        return true;
      } else {
        _errorMessage = 'Error al subir la imagen.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado al subir la imagen: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
