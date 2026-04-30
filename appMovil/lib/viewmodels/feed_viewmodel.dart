import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/reporte_model.dart';
import '../services/reporte_service.dart';

class FeedViewModel extends ChangeNotifier {
  final ReporteService _reporteService = ReporteService();

  List<ReporteModel> _reportes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _query = '';
  Position? _posicionActual;

  List<ReporteModel> get reportes => _reportes;
  List<ReporteModel> get fichas => _reportes; // compatibilidad
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  Position? get posicionActual => _posicionActual;

  // ── Filtrado por búsqueda ───────────────────────────────────────────
  List<ReporteModel> get fichasFiltradas {
    if (_query.trim().isEmpty) return _reportes;
    final q = _query.toLowerCase();
    return _reportes.where((f) {
      return f.titulo.toLowerCase().contains(q) ||
          f.descripcion.toLowerCase().contains(q) ||
          (f.nombreCategoria?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void actualizarQuery(String q) {
    _query = q;
    notifyListeners();
  }

  // ── Alertas activas (notificaciones de tipo alerta_masiva en 24h) ───
  /// Reportes activos publicados en las últimas 24 horas
  List<ReporteModel> get alertas24h {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _reportes.where((r) {
      if (r.estado.toLowerCase() != 'activo') return false;
      final fecha = r.createdAt;
      if (fecha == null) return false;
      return fecha.isAfter(cutoff);
    }).toList();
  }

  // ── Reportes cercanos al usuario ───────────────────────────────────
  List<ReporteModel> get reportesCercanos {
    if (_posicionActual == null) return [];
    const double radioKm = 5.0;
    return _reportes.where((r) {
      if (r.latitud == null || r.longitud == null) return false;
      final distancia = _distanciaKm(
        _posicionActual!.latitude,
        _posicionActual!.longitude,
        r.latitud!,
        r.longitud!,
      );
      return distancia <= radioKm;
    }).toList()
      ..sort((a, b) {
        final da = _distanciaKm(_posicionActual!.latitude, _posicionActual!.longitude, a.latitud!, a.longitud!);
        final db = _distanciaKm(_posicionActual!.latitude, _posicionActual!.longitude, b.latitud!, b.longitud!);
        return da.compareTo(db);
      });
  }

  double distanciaKmDesde(ReporteModel r) {
    if (_posicionActual == null || r.latitud == null || r.longitud == null) return double.infinity;
    return _distanciaKm(_posicionActual!.latitude, _posicionActual!.longitude, r.latitud!, r.longitud!);
  }

  double _distanciaKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  // ── Estadísticas del feed ──────────────────────────────────────────
  int get totalActivos => _reportes.where((r) => r.estado.toLowerCase() == 'activo').length;

  // ── Carga datos ────────────────────────────────────────────────────
  Future<void> cargarFichas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _reportes = await _reporteService.obtenerReportes();
      await _obtenerUbicacion();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _obtenerUbicacion() async {
    try {
      // Verificar si el servicio de localización está activo
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      // Revisar y solicitar permiso si hace falta
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      // Obtener posición — en web no se usa LocationSettings sino desiredAccuracy
      _posicionActual = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      notifyListeners();
    } catch (_) {
      // Silencioso: si no hay permiso o no funciona en plataforma, la sección "Cerca" no aparece
    }
  }
}
