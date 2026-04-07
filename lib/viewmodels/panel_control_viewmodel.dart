import 'package:flutter/material.dart';
import '../models/ficha_model.dart';
import '../models/perfil_model.dart';
import '../services/ficha_service.dart';
import '../services/vinculacion_service.dart';

class PanelControlViewModel extends ChangeNotifier {
  final FichaService _fichaService = FichaService();
  final VinculacionService _vinculacionService = VinculacionService();

  FichaModel? _ficha;
  List<PerfilModel> _voluntarios = [];
  bool _isLoading = false;
  String? _errorMessage;

  FichaModel? get ficha => _ficha;
  List<PerfilModel> get voluntarios => _voluntarios;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarDatos(String fichaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ficha = await _fichaService.obtenerFichaPorId(fichaId);
      if (_ficha != null) {
        _voluntarios = await _vinculacionService.obtenerVoluntarios(fichaId);
      }
    } catch (e) {
      _errorMessage = 'Error al cargar el panel de control: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cambiarEstado(String fichaId, String nuevoEstado, {String? justificacion}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (nuevoEstado == 'cerrado') {
        await _fichaService.cerrarFicha(fichaId, justificacion: justificacion);
      } else if (nuevoEstado == 'pausado') {
        await _fichaService.pausarFicha(fichaId, justificacion: justificacion);
      } else if (nuevoEstado == 'activo') {
        await _fichaService.reabrirFicha(fichaId);
      }
      
      // Recargar para estado actualizado
      _ficha = await _fichaService.obtenerFichaPorId(fichaId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al cambiar el estado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
