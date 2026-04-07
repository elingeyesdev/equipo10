import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ficha_model.dart';
import '../services/ficha_service.dart';

class EditarFichaViewModel extends ChangeNotifier {
  final FichaService _fichaService = FichaService();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _xFile;
  Uint8List? _imageBytes;
  String? _fotoUrlExistente;
  bool _isLoading = false;
  String? _errorMessage;

  Uint8List? get imageBytes => _imageBytes;
  String? get fotoUrlExistente => _fotoUrlExistente;
  bool get tieneImagenNueva => _xFile != null;
  bool get tieneImagen => _xFile != null || (_fotoUrlExistente?.isNotEmpty == true);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Inicializa el VM con los datos actuales de la ficha.
  void inicializar(FichaModel ficha) {
    _fotoUrlExistente = ficha.fotoUrl;
    _xFile = null;
    _imageBytes = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> seleccionarImagen() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        _xFile = picked;
        _imageBytes = await picked.readAsBytes();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error al seleccionar imagen: $e';
      notifyListeners();
    }
  }

  void limpiarImagen() {
    _xFile = null;
    _imageBytes = null;
    _fotoUrlExistente = null;
    notifyListeners();
  }

  /// Edita la ficha. Sube nueva imagen si fue seleccionada.
  Future<bool> editarFicha({
    required String fichaId,
    required String titulo,
    required String descripcion,
  }) async {
    if (titulo.trim().isEmpty || descripcion.trim().isEmpty) {
      _errorMessage = 'El título y la descripción son obligatorios.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      String? fotoUrl = _fotoUrlExistente;

      // Si se seleccionó nueva imagen, la sube
      if (_xFile != null) {
        fotoUrl = await _fichaService.subirImagen(_xFile!);
      }

      await _fichaService.editarFicha(
        id: fichaId,
        titulo: titulo.trim(),
        descripcion: descripcion.trim(),
        fotoUrl: fotoUrl,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Elimina la ficha permanentemente.
  Future<bool> eliminarFicha(String fichaId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _fichaService.eliminarFicha(fichaId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
