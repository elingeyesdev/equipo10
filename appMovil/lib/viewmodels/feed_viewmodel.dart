import 'package:flutter/material.dart';
import '../models/ficha_model.dart';
import '../services/ficha_service.dart';

class FeedViewModel extends ChangeNotifier {
  final FichaService _fichaService = FichaService();

  List<FichaModel> _fichas = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FichaModel> get fichas => _fichas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Carga todas las fichas (activas y cerradas) desde Supabase.
  Future<void> cargarFichas() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _fichas = await _fichaService.obtenerFichas();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }
}
