import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ficha_service.dart';

class CrearFichaViewModel extends ChangeNotifier {
  final FichaService _fichaService = FichaService();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _xFile;
  Uint8List? _imageBytes; // Usado para preview en web y mobile
  bool _isLoading = false;
  String? _errorMessage;

  Uint8List? get imageBytes => _imageBytes;
  bool get tieneImagen => _xFile != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Abre la galería y convierte la imagen a bytes (compatible web + mobile).
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
    notifyListeners();
  }

  /// Crea la ficha: sube imagen si existe, luego guarda en BD.
  Future<bool> crearFicha({
    required String creadoPor,
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
      String? fotoUrl;
      if (_xFile != null) {
        fotoUrl = await _fichaService.subirImagen(_xFile!);
      }

      await _fichaService.crearFicha(
        creadoPor: creadoPor,
        titulo: titulo.trim(),
        descripcion: descripcion.trim(),
        fotoUrl: fotoUrl,
      );

      _xFile = null;
      _imageBytes = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
