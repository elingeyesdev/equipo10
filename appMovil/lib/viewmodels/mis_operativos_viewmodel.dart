import 'package:flutter/material.dart';
import '../models/ficha_model.dart';
import '../services/ficha_service.dart';

class MisOperativosViewModel extends ChangeNotifier {
  final FichaService _fichaService = FichaService();

  List<FichaModel> _fichas = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FichaModel> get fichas => _fichas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarMisFichas(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _fichas = await _fichaService.obtenerMisFichas(userId);
    } catch (e) {
      _errorMessage = 'Error al cargar tus operativos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
