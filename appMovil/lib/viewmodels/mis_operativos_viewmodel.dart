import 'package:flutter/material.dart';
import '../models/reporte_model.dart';
import '../services/reporte_service.dart';

class MisOperativosViewModel extends ChangeNotifier {
  final ReporteService _reporteService = ReporteService();

  List<ReporteModel> _reportes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReporteModel> get reportes => _reportes;
  List<ReporteModel> get fichas => _reportes; // alias
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarMisFichas(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reportes = await _reporteService.obtenerMisReportes(userId);
    } catch (e) {
      _errorMessage = 'Error al cargar tus operativos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
