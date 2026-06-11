import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/reporte_model.dart';
import '../models/perfil_model.dart';
import '../services/reporte_service.dart';
import '../services/vinculacion_service.dart';
import '../services/evidencia_service.dart';
import '../models/evidencia_model.dart';

class RutaVoluntario {
  final String nombre;
  final List<LatLng> puntos;
  final String? usuarioId;
  final String? estadoBusqueda;

  RutaVoluntario({
    required this.nombre,
    required this.puntos,
    this.usuarioId,
    this.estadoBusqueda,
  });
}

class PistaMapa {
  final LatLng punto;
  final String etiqueta;
  final DateTime? createdAt;
  PistaMapa({required this.punto, required this.etiqueta, this.createdAt});
}

class PanelControlViewModel extends ChangeNotifier {
  final ReporteService _reporteService = ReporteService();
  final VinculacionService _vinculacionService = VinculacionService();
  final EvidenciaService _evidenciaService = EvidenciaService();

  Timer? _pollingTimer;

  ReporteModel? _ficha;
  List<PerfilModel> _voluntarios = [];
  List<dynamic> _recorridosData = [];
  List<RutaVoluntario> _rutasVoluntarios = [];
  List<PistaMapa> _pistas = [];
  List<EvidenciaModel> _evidencias = [];
  List<Map<String, dynamic>> _galeria = [];
  bool _isLoading = false;
  bool _isChangingState = false; // solo true durante cambiarEstado()
  String? _errorMessage;
  String? _filtroNombreVoluntario;

  ReporteModel? get ficha => _ficha;
  List<PerfilModel> get voluntarios => _voluntarios;
  List<dynamic> get recorridosData => _recorridosData;
  List<PistaMapa> get pistas => _pistas;
  List<EvidenciaModel> get evidencias => _evidencias;
  List<Map<String, dynamic>> get galeria => _galeria;

  List<RutaVoluntario> get rutasVoluntarios {
    if (_filtroNombreVoluntario == null) return _rutasVoluntarios;
    return _rutasVoluntarios
        .where((r) => r.nombre == _filtroNombreVoluntario)
        .toList();
  }

  List<RutaVoluntario> get todasLasRutas => _rutasVoluntarios;
  String? get filtroNombreVoluntario => _filtroNombreVoluntario;

  void setFiltroVoluntario(String? nombre) {
    _filtroNombreVoluntario = nombre;
    notifyListeners();
  }

  // Mantenemos getter recorridosMap por compatibilidad temporal o si se necesita la lista cruda
  List<List<LatLng>> get recorridosMap =>
      rutasVoluntarios.map((r) => r.puntos).toList();

  bool get isLoading => _isLoading;
  bool get isChangingState => _isChangingState;
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

  Future<bool> cambiarEstado(String fichaId, String nuevoEstado,
      {String? justificacion}) async {
    _isChangingState = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (nuevoEstado == 'cerrado' || nuevoEstado == 'resuelto') {
        await _reporteService.marcarResuelto(fichaId,
            justificacion: justificacion);
      } else if (nuevoEstado == 'pausado') {
        await _reporteService.pausarReporte(fichaId,
            justificacion: justificacion);
      } else if (nuevoEstado == 'activo') {
        await _reporteService.reabrirReporte(fichaId);
      }

      // Recargar para estado actualizado
      _ficha = await _reporteService.obtenerReportePorId(fichaId);

      _isChangingState = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al cambiar el estado: $e';
      _isChangingState = false;
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
      _evidencias = await _evidenciaService.obtenerEvidencias(fichaId);
      _galeria = await _reporteService.obtenerGaleria(fichaId);
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
          final decoded =
              r['puntos'] is String ? jsonDecode(r['puntos']) : r['puntos'];
          if (decoded is List) {
            List<LatLng> points = [];
            for (var p in decoded) {
              if (p is Map && p.containsKey('lat') && p.containsKey('lng')) {
                points.add(LatLng(p['lat'].toDouble(), p['lng'].toDouble()));
              }
            }
            if (points.isNotEmpty) {
              String nombreVoluntario = 'Voluntario';
              String? uId;
              if (r['usuario'] != null) {
                if (r['usuario']['nombre'] != null) {
                  nombreVoluntario = r['usuario']['nombre'];
                }
                if (r['usuario']['id'] != null) {
                  uId = r['usuario']['id'].toString();
                }
              }
              if (uId == null && r['usuario_id'] != null) {
                uId = r['usuario_id'].toString();
              }

              String? estadoB = r['estado_busqueda']?.toString();

              _rutasVoluntarios.add(RutaVoluntario(
                nombre: nombreVoluntario,
                puntos: points,
                usuarioId: uId,
                estadoBusqueda: estadoB,
              ));
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
          createdAt: p['created_at'] != null
              ? DateTime.tryParse(
                  p['created_at'].toString().replaceAll(' ', 'T'))
              : null,
        ));
      }
    }
  }

  Future<bool> enviarAlertaMasiva(String fichaId, String mensaje) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success =
          await _reporteService.enviarAlertaMasiva(fichaId, mensaje);
      if (!success) {
        _errorMessage = 'No se pudo enviar la alerta masiva';
      }
      return success;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> enviarMensajeDirecto(
      String fichaId, String usuarioId, String mensaje) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _reporteService.enviarMensajeDirecto(
          fichaId, usuarioId, mensaje);
      if (!success) {
        _errorMessage = 'No se pudo enviar el mensaje directo';
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

      _evidencias = await _evidenciaService.obtenerEvidencias(fichaId);

      notifyListeners();
    } catch (e) {
      // Ignorar errores en segundo plano para no interrumpir UI
    }
  }
}
