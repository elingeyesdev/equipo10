import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

/// Un punto del recorrido GPS grabado localmente.
class PuntoRecorrido {
  final double lat;
  final double lng;
  final int ts; // timestamp en milisegundos

  const PuntoRecorrido({required this.lat, required this.lng, required this.ts});

  Map<String, dynamic> toMap() => {'lat': lat, 'lng': lng, 'ts': ts};
}

/// Servicio de tracking GPS.
/// Graba el recorrido localmente mientras el usuario busca y
/// lo sube al API al terminar.
class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  final ApiService _api = ApiService();

  // Estado interno
  bool _isTracking = false;
  bool _isPaused = false;
  final List<PuntoRecorrido> _puntos = [];
  StreamSubscription<Position>? _positionSub;

  // Configuración del stream de GPS
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Solo registra si se movió más de 5 metros
  );

  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  List<PuntoRecorrido> get puntos => List.unmodifiable(_puntos);
  int get totalPuntos => _puntos.length;

  /// Solicita permisos de ubicación. Retorna true si fueron concedidos.
  Future<bool> solicitarPermisos() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Obtiene la posición actual una sola vez.
  Future<Position?> obtenerPosicionActual() async {
    try {
      final permitted = await solicitarPermisos();
      if (!permitted) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  /// Inicia la grabación del recorrido localmente Y notifica al backend.
  Future<bool> iniciarTracking({
    required String reporteId,
    required String usuarioId,
  }) async {
    if (_isTracking) return true;

    final permitted = await solicitarPermisos();
    if (!permitted) return false;

    // Notificar al backend
    try {
      await _api.client.put('/reportes/$reporteId/voluntarios/iniciar/$usuarioId');
    } catch (_) {
      // Continuar de todas formas — modo offline-first
    }

    _puntos.clear();
    _isTracking = true;
    _isPaused = false;

    // Iniciar stream de posición
    _positionSub = Geolocator.getPositionStream(locationSettings: _locationSettings)
        .listen((pos) {
      if (!_isPaused) {
        _puntos.add(PuntoRecorrido(
          lat: pos.latitude,
          lng: pos.longitude,
          ts: pos.timestamp.millisecondsSinceEpoch,
        ));
      }
    });

    return true;
  }

  /// Pausa temporalmente la grabación (no detiene el stream, solo ignora puntos).
  Future<void> pausarTracking({
    required String reporteId,
    required String usuarioId,
  }) async {
    if (!_isTracking) return;
    _isPaused = true;
    try {
      await _api.client.put('/reportes/$reporteId/voluntarios/pausar/$usuarioId');
    } catch (_) {}
  }

  /// Reanuda la grabación si estaba pausada.
  void reanudarTracking() {
    _isPaused = false;
  }

  /// Detiene la grabación, sube el recorrido al backend y limpia el estado.
  Future<bool> terminarTracking({
    required String reporteId,
    required String usuarioId,
  }) async {
    if (!_isTracking) return false;

    _isTracking = false;
    _isPaused = false;
    await _positionSub?.cancel();
    _positionSub = null;

    if (_puntos.isEmpty) return false;

    try {
      final payload = {'puntos': _puntos.map((p) => p.toMap()).toList()};
      await _api.client.put(
        '/reportes/$reporteId/voluntarios/terminar/$usuarioId',
        data: payload,
      );
      _puntos.clear();
      return true;
    } catch (_) {
      // Guardar localmente para retry posterior (simplificado por ahora)
      return false;
    }
  }

  /// Limpia el estado sin subir nada (uso interno).
  void reset() {
    _positionSub?.cancel();
    _positionSub = null;
    _isTracking = false;
    _isPaused = false;
    _puntos.clear();
  }
}
