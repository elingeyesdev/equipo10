import 'package:flutter/material.dart';
import '../models/reporte_model.dart';
import '../models/perfil_model.dart';
import '../services/reporte_service.dart';
import '../services/vinculacion_service.dart';

class PanelControlViewModel extends ChangeNotifier {
  final ReporteService _reporteService = ReporteService();
  final VinculacionService _vinculacionService = VinculacionService();

  ReporteModel? _ficha;
  List<PerfilModel> _voluntarios = [];
  bool _isLoading = false;
  String? _errorMessage;

  ReporteModel? get ficha => _ficha;
  List<PerfilModel> get voluntarios => _voluntarios;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarDatos(String fichaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ficha = await _reporteService.obtenerReportePorId(fichaId);
      if (_ficha != null) {
        _voluntarios = await _vinculacionService.obtenerVoluntarios(fichaId);
      }
    } catch (e) {
      _errorMessage = 'Error al cargar el panel de control: $e';
    } finally {
      if (hasListeners) {
          _isLoading = false;
          notifyListeners();
      }
    }
  }

  Future<bool> cambiarEstado(String fichaId, String nuevoEstado, {String? justificacion}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (nuevoEstado == 'cerrado' || nuevoEstado == 'resuelto') {
        await _reporteService.marcarResuelto(fichaId, justificacion: justificacion);
      } else if (nuevoEstado == 'pausado') {
        await _reporteService.pausarReporte(fichaId, justificacion: justificacion);
      } else if (nuevoEstado == 'activo') {
        await _reporteService.reabrirReporte(fichaId);
      }
      
      // Recargar para estado actualizado
      _ficha = await _reporteService.obtenerReportePorId(fichaId);
      
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
