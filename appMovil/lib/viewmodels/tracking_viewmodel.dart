import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/tracking_service.dart';

enum TrackingEstado { inactivo, activo, pausado, terminado }

class TrackingViewModel extends ChangeNotifier {
  final TrackingService _trackingService = TrackingService();

  TrackingEstado _estado = TrackingEstado.inactivo;
  bool _isLoading = false;
  String? _errorMessage;
  Position? _posicionActual;
  Timer? _refreshTimer;

  String? _reporteId;
  String? _usuarioId;

  TrackingEstado get estado => _estado;
  bool get isLoading => _isLoading;
  bool get isTracking => _trackingService.isTracking;
  bool get isPaused => _trackingService.isPaused;
  String? get errorMessage => _errorMessage;
  Position? get posicionActual => _posicionActual;
  int get totalPuntos => _trackingService.totalPuntos;
  List<PuntoRecorrido> get puntosActuales => _trackingService.puntos;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? msg) { _errorMessage = msg; notifyListeners(); }

  /// Verifica si el usuario está dentro del cuadrante. Retorna la posición si sí.
  Future<Position?> verificarGeofencing({
    required double latMin,
    required double latMax,
    required double lngMin,
    required double lngMax,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final pos = await _trackingService.obtenerPosicionActual();
      if (pos == null) {
        _setError('No se pudo obtener tu ubicación. Activa el GPS e intenta de nuevo.');
        return null;
      }
      _posicionActual = pos;
      final dentroDeCuadrante =
          pos.latitude >= latMin && pos.latitude <= latMax &&
          pos.longitude >= lngMin && pos.longitude <= lngMax;

      if (!dentroDeCuadrante) {
        _setError('Debes estar dentro del cuadrante asignado para iniciar la búsqueda.');
        notifyListeners();
        return null;
      }
      notifyListeners();
      return pos;
    } catch (e) {
      _setError('Error al obtener ubicación: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Inicia el tracking GPS.
  Future<bool> iniciarBusqueda({
    required String reporteId,
    required String usuarioId,
  }) async {
    _setLoading(true);
    _setError(null);
    _reporteId = reporteId;
    _usuarioId = usuarioId;
    try {
      final ok = await _trackingService.iniciarTracking(
        reporteId: reporteId,
        usuarioId: usuarioId,
      );
      if (!ok) {
        _setError('No se pudo iniciar el tracking. Revisa los permisos de ubicación.');
        return false;
      }
      _estado = TrackingEstado.activo;
      // Refresca el contador de puntos cada 3 segundos en la UI
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => notifyListeners());
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Pausa el tracking sin perder el recorrido.
  Future<void> pausarBusqueda() async {
    if (_reporteId == null || _usuarioId == null) return;
    await _trackingService.pausarTracking(
      reporteId: _reporteId!,
      usuarioId: _usuarioId!,
    );
    _estado = TrackingEstado.pausado;
    notifyListeners();
  }

  /// Reanuda el tracking pausado.
  void reanudarBusqueda() {
    _trackingService.reanudarTracking();
    _estado = TrackingEstado.activo;
    notifyListeners();
  }

  /// Termina el tracking y sube el recorrido al API.
  Future<bool> terminarBusqueda() async {
    if (_reporteId == null || _usuarioId == null) return false;
    _setLoading(true);
    _refreshTimer?.cancel();
    try {
      final ok = await _trackingService.terminarTracking(
        reporteId: _reporteId!,
        usuarioId: _usuarioId!,
      );
      _estado = TrackingEstado.terminado;
      notifyListeners();
      return ok;
    } catch (e) {
      _setError('Error al guardar el recorrido: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _trackingService.reset();
    super.dispose();
  }
}
