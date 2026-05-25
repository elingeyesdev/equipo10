import 'dart:async';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import '../models/evidencia_model.dart';

/// Servicio para la gestión de evidencias fotográficas.
/// Maneja la captura de cámara, el GPS simultáneo y la subida al servidor.
class EvidenciaService {
  static final EvidenciaService _instance = EvidenciaService._internal();
  factory EvidenciaService() => _instance;
  EvidenciaService._internal();

  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  // ──────────────────────────────────────────────
  // Captura de cámara
  // ──────────────────────────────────────────────

  /// Abre la cámara del dispositivo y devuelve el archivo capturado.
  /// Retorna null si el usuario cancela.
  Future<XFile?> abrirCamara() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,       // Buena calidad sin peso excesivo
        maxWidth: 1920,
        maxHeight: 1080,
        preferredCameraDevice: CameraDevice.rear,
      );
    } catch (e) {
      return null;
    }
  }

  /// Abre la galería para seleccionar una imagen existente.
  /// Retorna null si el usuario cancela.
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

  // ──────────────────────────────────────────────
  // GPS
  // ──────────────────────────────────────────────

  /// Obtiene la posición GPS actual. Solicita permisos si son necesarios.
  /// Retorna null si no tiene permisos o el GPS falla.
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

  // ──────────────────────────────────────────────
  // Upload de imagen
  // ──────────────────────────────────────────────

  /// Sube una imagen al Laravel Storage y retorna la URL pública.
  /// Lanza Exception si el servidor responde con error.
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

  // ──────────────────────────────────────────────
  // CRUD de evidencias (Respuestas tipo avistamiento)
  // ──────────────────────────────────────────────

  /// Crea una evidencia fotográfica vinculada a un reporte.
  /// [fotoUrl] es la URL pública retornada por [subirFoto].
  /// [lat] y [lng] son las coordenadas de captura.
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

  /// Obtiene todas las evidencias (avistamientos con imagen) de un reporte.
  Future<List<EvidenciaModel>> obtenerEvidencias(String reporteId) async {
    final response = await _api.client.get('/respuestas/reporte/$reporteId');
    if (response.statusCode == 200 && response.data['success'] == true) {
      final List respuestas = response.data['data']['respuestas'] ?? [];
      // Filtramos solo avistamientos que tengan imagen
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
