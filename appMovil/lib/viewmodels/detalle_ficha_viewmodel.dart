import 'package:flutter/material.dart';
import '../models/ficha_model.dart';
import '../services/ficha_service.dart';
import '../services/vinculacion_service.dart';

class DetalleFichaViewModel extends ChangeNotifier {
  final FichaService _fichaService = FichaService();
  final VinculacionService _vinculacionService = VinculacionService();

  FichaModel? _ficha;
  bool _isLoading = false;
  bool _yaVinculado = false;
  String? _errorMessage;
  String? _successMessage;

  FichaModel? get ficha => _ficha;
  bool get isLoading => _isLoading;
  bool get yaVinculado => _yaVinculado;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Carga la ficha y verifica si el usuario ya está vinculado.
  Future<void> cargarFicha(String fichaId, String usuarioId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _ficha = await _fichaService.obtenerFichaPorId(fichaId);
      _yaVinculado = await _vinculacionService.estaVinculado(
        fichaId: fichaId,
        usuarioId: usuarioId,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Une el usuario a la búsqueda. Retorna true si fue exitoso.
  Future<bool> unirseABusqueda(String fichaId, String usuarioId) async {
    _setLoading(true);
    _errorMessage = null;
    _successMessage = null;
    try {
      await _vinculacionService.unirseABusqueda(
        fichaId: fichaId,
        usuarioId: usuarioId,
      );
      _yaVinculado = true;
      _successMessage = '¡Te has unido a la búsqueda exitosamente!';
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cierra la búsqueda (solo el creador). Actualiza localmente sin navegar.
  Future<bool> cerrarBusqueda(String fichaId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _fichaService.cerrarFicha(fichaId);
      if (_ficha != null) {
        _ficha = FichaModel(
          id: _ficha!.id,
          creadoPor: _ficha!.creadoPor,
          titulo: _ficha!.titulo,
          descripcion: _ficha!.descripcion,
          fotoUrl: _ficha!.fotoUrl,
          latitud: _ficha!.latitud,
          longitud: _ficha!.longitud,
          estado: 'cerrado',
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reabre la búsqueda (solo el creador). Actualiza localmente sin navegar.
  Future<bool> reabrirBusqueda(String fichaId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _fichaService.reabrirFicha(fichaId);
      if (_ficha != null) {
        _ficha = FichaModel(
          id: _ficha!.id,
          creadoPor: _ficha!.creadoPor,
          titulo: _ficha!.titulo,
          descripcion: _ficha!.descripcion,
          fotoUrl: _ficha!.fotoUrl,
          latitud: _ficha!.latitud,
          longitud: _ficha!.longitud,
          estado: 'activo',
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}

