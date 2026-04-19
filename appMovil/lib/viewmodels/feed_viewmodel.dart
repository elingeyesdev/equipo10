import 'package:flutter/material.dart';
import '../models/reporte_model.dart';
import '../services/reporte_service.dart';

class FeedViewModel extends ChangeNotifier {
  final ReporteService _reporteService = ReporteService();

  List<ReporteModel> _reportes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReporteModel> get reportes => _reportes;
  
  // Para compatibilidad visual si los views usan la propiedad fichas
  List<ReporteModel> get fichas => _reportes;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Carga todos los reportes desde Laravel API.
  Future<void> cargarFichas() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _reportes = await _reporteService.obtenerReportes();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }
}
