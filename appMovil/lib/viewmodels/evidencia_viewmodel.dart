import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/evidencia_model.dart';
import '../services/evidencia_service.dart';

enum EvidenciaEstado { idle, capturando, subiendo, guardando, listo, error }

class EvidenciaViewModel extends ChangeNotifier {
  final EvidenciaService _service = EvidenciaService();

  List<EvidenciaModel> _evidencias = [];
  EvidenciaEstado _estado = EvidenciaEstado.idle;
  String? _errorMessage;
  bool _cargando = false;

  // Datos de la captura en progreso
  XFile? _fotoTemporal;
  Position? _posicionTemporal;
  List<int>? _bytesPreview;

  List<EvidenciaModel> get evidencias => _evidencias;
  EvidenciaEstado get estado => _estado;
  String? get errorMessage => _errorMessage;
  bool get cargando => _cargando;
  List<int>? get bytesPreview => _bytesPreview;
  bool get tieneFotoTemporal => _fotoTemporal != null;

  void _setState(EvidenciaEstado s) {
    _estado = s;
    notifyListeners();
  }

  /// Carga las evidencias existentes de un reporte.
  Future<void> cargarEvidencias(String reporteId) async {
    _cargando = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _evidencias = await _service.obtenerEvidencias(reporteId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Abre la cámara y guarda el archivo temporal + preview.
  Future<bool> capturarFoto() async {
    _setState(EvidenciaEstado.capturando);
    _fotoTemporal = null;
    _bytesPreview = null;
    _posicionTemporal = null;

    final xFile = await _service.abrirCamara();
    if (xFile == null) {
      _setState(EvidenciaEstado.idle);
      return false;
    }

    _fotoTemporal = xFile;
    _bytesPreview = await xFile.readAsBytes();

    // Obtener GPS en paralelo a la captura
    _posicionTemporal = await _service.obtenerPosicionActual();

    _setState(EvidenciaEstado.idle);
    return true;
  }

  /// Abre la galería como alternativa a la cámara.
  Future<bool> seleccionarDeGaleria() async {
    _setState(EvidenciaEstado.capturando);
    _fotoTemporal = null;
    _bytesPreview = null;
    _posicionTemporal = null;

    final xFile = await _service.abrirGaleria();
    if (xFile == null) {
      _setState(EvidenciaEstado.idle);
      return false;
    }

    _fotoTemporal = xFile;
    _bytesPreview = await xFile.readAsBytes();
    _posicionTemporal = await _service.obtenerPosicionActual();

    _setState(EvidenciaEstado.idle);
    return true;
  }

  /// Descarta la foto temporal sin publicar.
  void descartarFoto() {
    _fotoTemporal = null;
    _bytesPreview = null;
    _posicionTemporal = null;
    _errorMessage = null;
    _setState(EvidenciaEstado.idle);
  }

  /// Sube la foto y crea la evidencia en el servidor.
  Future<bool> publicarEvidencia({
    required String reporteId,
    required String usuarioId,
    required String descripcion,
  }) async {
    if (_fotoTemporal == null) return false;

    _errorMessage = null;

    try {
      // 1. Subir imagen
      _setState(EvidenciaEstado.subiendo);
      final fotoUrl = await _service.subirFoto(_fotoTemporal!);

      // 2. Crear respuesta en el servidor
      _setState(EvidenciaEstado.guardando);
      final nueva = await _service.crearEvidencia(
        reporteId: reporteId,
        usuarioId: usuarioId,
        descripcion: descripcion,
        fotoUrl: fotoUrl,
        lat: _posicionTemporal?.latitude,
        lng: _posicionTemporal?.longitude,
      );

      // 3. Insertar al inicio de la lista local
      _evidencias = [nueva, ..._evidencias];
      _fotoTemporal = null;
      _bytesPreview = null;
      _posicionTemporal = null;

      _setState(EvidenciaEstado.listo);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setState(EvidenciaEstado.error);
      return false;
    }
  }

  /// Indica si se capturó GPS junto a la foto.
  bool get tienePosicion => _posicionTemporal != null;

  /// Coordenadas de la foto temporal (para mostrar en UI).
  double? get latTemporal => _posicionTemporal?.latitude;
  double? get lngTemporal => _posicionTemporal?.longitude;
}
