import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/reporte_model.dart';
import '../services/reporte_service.dart';

class EditarFichaViewModel extends ChangeNotifier {
  final ReporteService _fichaService = ReporteService();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _xFile;
  Uint8List? _imageBytes;
  String? _fotoUrlExistente;
  bool _fotoEliminada = false;
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, dynamic> caracteristicas = {};

  Uint8List? get imageBytes => _imageBytes;
  String? get fotoUrlExistente => _fotoUrlExistente;
  bool get tieneImagenNueva => _xFile != null;
  bool get tieneImagen =>
      _xFile != null || (_fotoUrlExistente?.isNotEmpty == true);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Inicializa el VM con los datos actuales de la ficha.
  void inicializar(ReporteModel ficha) {
    _fotoUrlExistente = ficha.fotoUrl;
    _xFile = null;
    _imageBytes = null;
    _fotoEliminada = false;
    caracteristicas.clear();
    if (ficha.caracteristicas != null) {
      caracteristicas.addAll(ficha.caracteristicas!);
    }
    notifyListeners();
  }

  void setCaracteristica(String clave, dynamic valor) {
    if (valor == null || (valor is String && valor.trim().isEmpty)) {
      caracteristicas.remove(clave);
    } else {
      caracteristicas[clave] = valor;
    }
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
    if (_fotoUrlExistente != null || _xFile != null) {
      _fotoEliminada = true;
    }
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
    String? telefonoContacto,
    double? recompensa,
    String? direccionReferencia,
    String? fechaPerdida,
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
        removerFoto: _fotoEliminada && _xFile == null,
        telefonoContacto: telefonoContacto,
        recompensa: recompensa,
        direccionReferencia: direccionReferencia,
        fechaPerdida: fechaPerdida,
        caracteristicasExtra: caracteristicas.isNotEmpty
            ? Map<String, dynamic>.from(caracteristicas)
            : null,
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
