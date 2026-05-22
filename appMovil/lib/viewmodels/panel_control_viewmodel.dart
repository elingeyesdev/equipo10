import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/reporte_model.dart';
import '../models/perfil_model.dart';
import '../services/reporte_service.dart';
import '../services/vinculacion_service.dart';

class RutaVoluntario {
  final String nombre;
  final List<LatLng> puntos;
  
  RutaVoluntario({required this.nombre, required this.puntos});
}

class PistaMapa {
  final LatLng punto;
  final String etiqueta;
  PistaMapa({required this.punto, required this.etiqueta});
}

class PanelControlViewModel extends ChangeNotifier {
  final ReporteService _reporteService = ReporteService();
  final VinculacionService _vinculacionService = VinculacionService();

  Timer? _pollingTimer;

  ReporteModel? _ficha;
  List<PerfilModel> _voluntarios = [];
  List<dynamic> _recorridosData = [];
  List<RutaVoluntario> _rutasVoluntarios = [];
  List<PistaMapa> _pistas = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _filtroNombreVoluntario;

  ReporteModel? get ficha => _ficha;
  List<PerfilModel> get voluntarios => _voluntarios;
  List<dynamic> get recorridosData => _recorridosData;
  List<PistaMapa> get pistas => _pistas;
  
  List<RutaVoluntario> get rutasVoluntarios {
    if (_filtroNombreVoluntario == null) return _rutasVoluntarios;
    return _rutasVoluntarios.where((r) => r.nombre == _filtroNombreVoluntario).toList();
  }
  
  List<RutaVoluntario> get todasLasRutas => _rutasVoluntarios;
  String? get filtroNombreVoluntario => _filtroNombreVoluntario;

  void setFiltroVoluntario(String? nombre) {
    _filtroNombreVoluntario = nombre;
    notifyListeners();
  }

  // Mantenemos getter recorridosMap por compatibilidad temporal o si se necesita la lista cruda
  List<List<LatLng>> get recorridosMap => rutasVoluntarios.map((r) => r.puntos).toList();

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
        await cargarRecorridosYPistas(fichaId);
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

  Future<void> cargarRecorridosYPistas(String fichaId) async {
    try {
      final newData = await _reporteService.obtenerRecorridos(fichaId);
      _procesarRecorridos(newData);
      final pistasData = await _reporteService.obtenerPistas(fichaId);
      _procesarPistas(pistasData);
    } catch (e) {
      _errorMessage = 'Error al cargar datos del mapa: $e';
    }
  }

  void _procesarRecorridos(List<dynamic> newData) {
    _recorridosData = newData;
    _rutasVoluntarios.clear();
    
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
              String nombreVoluntario = 'Voluntario';
              if (r['usuario'] != null && r['usuario']['nombre'] != null) {
                nombreVoluntario = r['usuario']['nombre'];
              }
              _rutasVoluntarios.add(RutaVoluntario(nombre: nombreVoluntario, puntos: points));
            }
          }
        } catch (e) {
          // Ignorar parse error para un recorrido específico
        }
      }
    }
  }

  void _procesarPistas(List<dynamic> pistasData) {
    _pistas.clear();
    for (var p in pistasData) {
      double lat = double.tryParse(p['ubicacion_lat']?.toString() ?? '0') ?? 0;
      double lng = double.tryParse(p['ubicacion_lng']?.toString() ?? '0') ?? 0;
      if (lat != 0 && lng != 0) {
        _pistas.add(PistaMapa(
          punto: LatLng(lat, lng),
          etiqueta: p['mensaje']?.toString() ?? 'Pista',
        ));
      }
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
      _cargarDatosFondo(fichaId);
    });
  }

  void detenerPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _cargarDatosFondo(String fichaId) async {
    try {
      final newData = await _reporteService.obtenerRecorridos(fichaId);
      _procesarRecorridos(newData);
      
      final pistasData = await _reporteService.obtenerPistas(fichaId);
      _procesarPistas(pistasData);
      
      notifyListeners();
    } catch (e) {
      // Ignorar errores en segundo plano para no interrumpir UI
    }
  }
}
