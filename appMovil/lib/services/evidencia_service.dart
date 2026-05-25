import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'api_service.dart';
import '../models/evidencia_model.dart';
import '../models/evidencia_offline_model.dart';

/// Servicio para la gestión de evidencias fotográficas.
/// Maneja la captura, la subida, y la cola offline con reintentos automáticos.
class EvidenciaService {
  static final EvidenciaService _instance = EvidenciaService._internal();
  factory EvidenciaService() => _instance;

  EvidenciaService._internal() {
    _initOfflineQueue();
  }

  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // ── Cola Offline ──────────────────────────────────────────────
  static const String _prefsKey = 'evidencias_offline_queue';
  final List<EvidenciaOfflineModel> _colaOffline = [];
  Timer? _syncTimer;
  bool _isSyncing = false;

  // Stream para notificar a los ViewModels cuando la cola cambia
  final _colaController = StreamController<List<EvidenciaOfflineModel>>.broadcast();
  Stream<List<EvidenciaOfflineModel>> get colaStream => _colaController.stream;
  List<EvidenciaOfflineModel> get colaOffline => List.unmodifiable(_colaOffline);

  Future<void> _initOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_prefsKey) ?? [];
    
    _colaOffline.clear();
    for (final jsonStr in jsonList) {
      try {
        _colaOffline.add(EvidenciaOfflineModel.fromJson(jsonStr));
      } catch (e) {
        // Ignorar items corruptos
      }
    }
    
    _colaController.add(_colaOffline);

    // Iniciar timer de sincronización (cada 30 segundos)
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      sincronizarColaOffline();
    });
    
    // Intentar subir inmediatamente si hay algo
    sincronizarColaOffline();
  }

  Future<void> _guardarCola() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _colaOffline.map((e) => e.toJson()).toList();
    await prefs.setStringList(_prefsKey, jsonList);
    _colaController.add(_colaOffline);
  }

  /// Pone una evidencia en la cola offline y la guarda en el almacenamiento local.
  Future<void> encolarEvidencia({
    required String reporteId,
    required String usuarioId,
    required String descripcion,
    required XFile xFile,
    double? lat,
    double? lng,
  }) async {
    // 1. Copiar el archivo a un directorio seguro (Application Documents)
    // porque el XFile de image_picker está en caché temporal y podría borrarse.
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${_uuid.v4()}.jpg';
    final savedImage = File('${dir.path}/$fileName');
    
    final bytes = await xFile.readAsBytes();
    await savedImage.writeAsBytes(bytes);

    // 2. Crear modelo offline
    final offlineEvidencia = EvidenciaOfflineModel(
      id: _uuid.v4(),
      reporteId: reporteId,
      usuarioId: usuarioId,
      descripcion: descripcion,
      lat: lat,
      lng: lng,
      imagePath: savedImage.path,
      creadoEn: DateTime.now(),
    );

    // 3. Agregar a la cola y persistir
    _colaOffline.add(offlineEvidencia);
    await _guardarCola();
  }

  /// Intenta subir todos los elementos pendientes en la cola.
  Future<void> sincronizarColaOffline() async {
    if (_isSyncing || _colaOffline.isEmpty) return;
    _isSyncing = true;

    // Copiamos la lista para iterar seguros
    final pendientes = List<EvidenciaOfflineModel>.from(_colaOffline);

    for (final offline in pendientes) {
      try {
        final file = File(offline.imagePath);
        if (!await file.exists()) {
          // Si el archivo físico ya no existe, no podemos hacer nada, lo sacamos de la cola
          _colaOffline.removeWhere((e) => e.id == offline.id);
          await _guardarCola();
          continue;
        }

        final xFile = XFile(file.path);
        
        // Intentamos subir
        final fotoUrl = await subirFoto(xFile);
        
        // Intentamos crear la evidencia
        await crearEvidencia(
          reporteId: offline.reporteId,
          usuarioId: offline.usuarioId,
          descripcion: offline.descripcion,
          fotoUrl: fotoUrl,
          lat: offline.lat,
          lng: offline.lng,
        );

        // Si tuvo éxito, lo quitamos de la cola y borramos el archivo local
        _colaOffline.removeWhere((e) => e.id == offline.id);
        await _guardarCola();
        
        try {
          await file.delete();
        } catch (_) {}
      } catch (_) {
        // Si falla (ej. sigue sin red), simplemente lo dejamos en la cola para el próximo timer
      }
    }

    _isSyncing = false;
  }

  // ── Captura de cámara ─────────────────────────────────────────

  Future<XFile?> abrirCamara() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
        preferredCameraDevice: CameraDevice.rear,
      );
    } catch (e) {
      return null;
    }
  }

  Future<XFile?> abrirGaleria() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
    } catch (e) {
      return null;
    }
  }

  // ── GPS ───────────────────────────────────────────────────────

  Future<Position?> obtenerPosicionActual() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Upload de imagen ──────────────────────────────────────────

  Future<String> subirFoto(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    final fileName = xFile.name.isNotEmpty ? xFile.name : 'evidencia.jpg';
    final String ext = fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';

    final formData = FormData.fromMap({
      'imagen': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType('image', ext),
      ),
    });

    final response = await _api.client.post(
      '/reportes/upload-image',
      data: formData,
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['url'] as String;
    }
    throw Exception('Error al subir la imagen al servidor.');
  }

  // ── CRUD de evidencias ────────────────────────────────────────

  Future<EvidenciaModel> crearEvidencia({
    required String reporteId,
    required String usuarioId,
    required String descripcion,
    required String fotoUrl,
    double? lat,
    double? lng,
  }) async {
    final Map<String, dynamic> data = {
      'reporte_id': reporteId,
      'usuario_id': usuarioId,
      'tipo_respuesta': 'avistamiento',
      'mensaje': descripcion,
      'imagenes': [fotoUrl],
    };

    if (lat != null) data['ubicacion_lat'] = lat;
    if (lng != null) data['ubicacion_lng'] = lng;

    try {
      final response = await _api.client.post('/respuestas', data: data);
      if (response.statusCode == 201 && response.data['success'] == true) {
        return EvidenciaModel.fromMap(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Error al guardar la evidencia.');
    } on DioException catch (e) {
      final body = e.response?.data;
      final errors = body?['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstMsg = (errors.values.first as List?)?.first?.toString();
        throw Exception(firstMsg ?? 'Datos inválidos.');
      }
      throw Exception(body?['message'] ?? 'Error de conexión.');
    }
  }

  Future<List<EvidenciaModel>> obtenerEvidencias(String reporteId) async {
    final response = await _api.client.get('/respuestas/reporte/$reporteId');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List respuestas = response.data['data']['respuestas'] ?? [];
      return respuestas
          .where((r) =>
              r['tipo_respuesta'] == 'avistamiento' &&
              (r['imagenes'] as List?)?.isNotEmpty == true)
          .map((r) => EvidenciaModel.fromMap(r))
          .toList();
    }
    return [];
  }
}
