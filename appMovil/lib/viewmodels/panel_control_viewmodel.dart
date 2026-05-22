import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/reporte_model.dart';
import '../models/perfil_model.dart';
import '../services/reporte_service.dart';
import '../services/vinculacion_service.dart';

class PanelControlViewModel extends ChangeNotifier {
  final ReporteService _reporteService = ReporteService();
  final VinculacionService _vinculacionService = VinculacionService();

  Timer? _pollingTimer;

  ReporteModel? _ficha;
  List<PerfilModel> _voluntarios = [];
  List<dynamic> _recorridosData = [];
  List<List<LatLng>> _recorridosMap = [];
  bool _isLoading = false;
  String? _errorMessage;

  ReporteModel? get ficha => _ficha;
  List<PerfilModel> get voluntarios => _voluntarios;
  List<dynamic> get recorridosData => _recorridosData;
  List<List<LatLng>> get recorridosMap => _recorridosMap;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarDatos(String fichaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ficha = await _reporteService.obtenerReportePorId(fichaId);
      if (_ficha != null) {
        _voluntarios = await _vinculacionService.obtenerVoluntarios(fichaId);
        await cargarRecorridos(fichaId);
      }
    } catch (e) {
      _errorMessage = 'Error al cargar el panel de control: $e';
    } finally {
      if (hasListeners) {
          _isLoading = false;
          notifyListeners();
      }
    }
  }

  Future<bool> cambiarEstado(String fichaId, String nuevoEstado, {String? justificacion}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (nuevoEstado == 'cerrado' || nuevoEstado == 'resuelto') {
        await _reporteService.marcarResuelto(fichaId, justificacion: justificacion);
      } else if (nuevoEstado == 'pausado') {
        await _reporteService.pausarReporte(fichaId, justificacion: justificacion);
      } else if (nuevoEstado == 'activo') {
        await _reporteService.reabrirReporte(fichaId);
      }
      
      // Recargar para estado actualizado
      _ficha = await _reporteService.obtenerReportePorId(fichaId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al cambiar el estado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> cargarRecorridos(String fichaId) async {
    try {
      _recorridosData = await _reporteService.obtenerRecorridos(fichaId);
      _recorridosMap.clear();
      
      for (var r in _recorridosData) {
        if (r['puntos'] != null) {
          try {
            final decoded = r['puntos'] is String ? jsonDecode(r['puntos']) : r['puntos'];
            if (decoded is List) {
              List<LatLng> points = [];
              for (var p in decoded) {
                if (p is Map && p.containsKey('lat') && p.containsKey('lng')) {
                  points.add(LatLng(p['lat'].toDouble(), p['lng'].toDouble()));
                }
              }
              if (points.isNotEmpty) {
                _recorridosMap.add(points);
              }
            }
          } catch (e) {
            // Ignorar parse error para un recorrido específico
          }
        }
      }
    } catch (e) {
      _errorMessage = 'No se pudieron cargar los recorridos: $e';
    }
  }

  Future<bool> enviarAlertaMasiva(String fichaId, String mensaje) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _reporteService.enviarAlertaMasiva(fichaId, mensaje);
      if (!success) {
        _errorMessage = 'No se pudo enviar la alerta masiva';
      }
      return success;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void iniciarPolling(String fichaId) {
    detenerPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _cargarRecorridosFondo(fichaId);
    });
  }

  void detenerPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _cargarRecorridosFondo(String fichaId) async {
    try {
      final newData = await _reporteService.obtenerRecorridos(fichaId);
      _recorridosData = newData;
      _recorridosMap.clear();
      
      for (var r in _recorridosData) {
        if (r['puntos'] != null) {
          try {
            final decoded = r['puntos'] is String ? jsonDecode(r['puntos']) : r['puntos'];
            if (decoded is List) {
              List<LatLng> points = [];
              for (var p in decoded) {
                if (p is Map && p.containsKey('lat') && p.containsKey('lng')) {
                  points.add(LatLng(p['lat'].toDouble(), p['lng'].toDouble()));
                }
              }
              if (points.isNotEmpty) {
                _recorridosMap.add(points);
              }
            }
          } catch (e) {
            // Ignorar
          }
        }
      }
      notifyListeners();
    } catch (e) {
      // Ignorar errores en segundo plano para no interrumpir UI
    }
  }
}
