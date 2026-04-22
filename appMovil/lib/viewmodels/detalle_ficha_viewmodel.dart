import 'package:flutter/material.dart';
import '../models/reporte_model.dart';
import '../services/reporte_service.dart';
import '../services/vinculacion_service.dart';

class DetalleFichaViewModel extends ChangeNotifier {
  final ReporteService _reporteService = ReporteService();
  final VinculacionService _vinculacionService = VinculacionService();

  ReporteModel? _ficha;
  bool _isLoading = false;
  bool _yaVinculado = false;
  String? _errorMessage;
  String? _successMessage;

  ReporteModel? get ficha => _ficha;
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
      _ficha = await _reporteService.obtenerReportePorId(fichaId);
      _yaVinculado = await _vinculacionService.estaVinculado(
        fichaId: fichaId,
        usuarioId: usuarioId,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (hasListeners) {
          _setLoading(false);
      }
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
      if (hasListeners) {
          _setLoading(false);
      }
    }
  }

  /// Cierra la búsqueda (solo el creador). Actualiza localmente sin navegar.
  Future<bool> cerrarBusqueda(String fichaId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _reporteService.marcarResuelto(fichaId);
      if (_ficha != null) {
        _ficha = _ficha!.copyWith(estado: 'resuelto');
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

  /// Reabre la búsqueda (solo el creador). 
  /// Si el API no tiene endpoint explícito para reabrir, este método podría no estar soportado.
  Future<bool> reabrirBusqueda(String fichaId) async {
    _errorMessage = 'Función no disponible en el nuevo sistema web. Comunícate con un administrador.';
    notifyListeners();
    return false;
  }
}

