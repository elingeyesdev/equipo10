import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/evidencia_model.dart';
import '../models/evidencia_offline_model.dart';
import '../services/evidencia_service.dart';

enum EvidenciaEstado {
  idle,
  capturando,
  subiendo,
  guardando,
  listo,
  listoOffline,
  error
}

class EvidenciaViewModel extends ChangeNotifier {
  final EvidenciaService _service = EvidenciaService();
  StreamSubscription? _colaSub;

  List<EvidenciaModel> _evidencias = [];
  List<EvidenciaOfflineModel> _pendientes = [];

  EvidenciaEstado _estado = EvidenciaEstado.idle;
  String? _errorMessage;
  bool _cargando = false;
  bool _esCreador = false;
  bool get esCreador => _esCreador;

  // Datos de la captura en progreso
  XFile? _fotoTemporal;
  Position? _posicionTemporal;
  List<int>? _bytesPreview;

  EvidenciaViewModel() {
    _pendientes = _service.colaOffline;
    _colaSub = _service.colaStream.listen((cola) {
      _pendientes = cola;
      notifyListeners();
      // Si la cola se vacía y estábamos en idle o listo, podríamos querer recargar las evidencias online
      // pero por ahora solo actualizamos la UI para quitar las pendientes.
    });
  }

  @override
  void dispose() {
    _colaSub?.cancel();
    super.dispose();
  }

  List<EvidenciaModel> get evidencias => _evidencias;
  List<EvidenciaOfflineModel> get pendientes => _pendientes;
  EvidenciaEstado get estado => _estado;
  String? get errorMessage => _errorMessage;
  bool get cargando => _cargando;
  List<int>? get bytesPreview => _bytesPreview;
  bool get tieneFotoTemporal => _fotoTemporal != null;

  void _setState(EvidenciaEstado s) {
    _estado = s;
    notifyListeners();
  }

  /// Carga las evidencias. Si esCreador=true carga todas (incluyendo pending);
  /// si es voluntario carga solo las approved para no mostrar las rechazadas.
  Future<void> cargarEvidencias(String reporteId,
      {bool esCreador = false}) async {
    _esCreador = esCreador;
    _cargando = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final todas = await _service.obtenerEvidencias(reporteId);
      if (esCreador) {
        _evidencias = todas;
      } else {
        _evidencias = todas.where((e) => e.estado == 'approved').toList();
      }
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

  /// Sube la foto y crea la evidencia en el servidor, o la encola si hay fallo de red.
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

      // 3. Insertar al inicio de la lista local (solo si es creador o está aprobada)
      if (_esCreador || nueva.estado == 'approved') {
        _evidencias = [nueva, ..._evidencias];
      }
      _fotoTemporal = null;
      _bytesPreview = null;
      _posicionTemporal = null;

      _setState(EvidenciaEstado.listo);
      return true;
    } catch (e) {
      final msg = e.toString();

      // Si es un error de red (no se pudo subir la foto o guardar la evidencia),
      // lo encolamos para después
      final isNetworkError = msg.toLowerCase().contains('error de conexión') ||
          msg.toLowerCase().contains('error al subir') ||
          msg.toLowerCase().contains('connection error') ||
          msg.toLowerCase().contains('network is unreachable') ||
          msg.toLowerCase().contains('socket');

      if (isNetworkError) {
        await _service.encolarEvidencia(
          reporteId: reporteId,
          usuarioId: usuarioId,
          descripcion: descripcion,
          xFile: _fotoTemporal!,
          lat: _posicionTemporal?.latitude,
          lng: _posicionTemporal?.longitude,
        );

        _fotoTemporal = null;
        _bytesPreview = null;
        _posicionTemporal = null;

        _setState(EvidenciaEstado.listoOffline);
        return true;
      }

      _errorMessage = msg.replaceFirst('Exception: ', '');
      _setState(EvidenciaEstado.error);
      return false;
    }
  }

  bool get tienePosicion => _posicionTemporal != null;
  double? get latTemporal => _posicionTemporal?.latitude;
  double? get lngTemporal => _posicionTemporal?.longitude;

  /// Aprobar una evidencia: cambia su estado localmente y llama al backend.
  Future<bool> aprobarEvidencia(String evidenciaId, String reporteId) async {
    try {
      await _service.aprobarEvidencia(evidenciaId);
      // Recargar para reflejar el cambio
      final todas = await _service.obtenerEvidencias(reporteId);
      _evidencias = todas;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Rechazar una evidencia: cambia su estado localmente y llama al backend.
  Future<bool> rechazarEvidencia(String evidenciaId, String reporteId) async {
    try {
      await _service.rechazarEvidencia(evidenciaId);
      final todas = await _service.obtenerEvidencias(reporteId);
      _evidencias = todas;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Eliminar una evidencia: la borra del backend y recarga la lista.
  Future<bool> eliminarEvidencia(String evidenciaId, String reporteId) async {
    try {
      await _service.eliminarEvidencia(evidenciaId);
      final todas = await _service.obtenerEvidencias(reporteId);
      _evidencias = todas;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
