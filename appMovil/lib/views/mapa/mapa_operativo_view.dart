import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../models/reporte_model.dart';
import '../../services/api_service.dart';
import '../../services/tile_cache_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/local_database.dart';
import '../../widgets/map_tile_layer.dart';
import '../../widgets/lpp_marker.dart';
import '../../widgets/evidencia_marker.dart';
import '../widgets/full_screen_image_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/cuadrante_model.dart';
import '../../services/cuadrante_service.dart';
import '../../services/evidencia_service.dart';
import '../../models/evidencia_model.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Paleta de colores para los recorridos de distintos voluntarios
const List<Color> _coloresVoluntarios = [
  Color(0xFF2196F3), // azul
  Color(0xFFFF9800), // naranja
  Color(0xFF9C27B0), // morado
  Color(0xFFE91E63), // rosa
  AppTheme.info, // cyan
  Color(0xFF795548), // marrón
];

// Etiquetas disponibles para las pistas (NO incluye 'Visto por última vez',
// esa etiqueta es exclusiva del punto original LPP y no se puede reasignar)
const List<Map<String, String>> _etiquetasPista = [
  {'emoji': '[P]', 'label': 'Nueva pista'},
  {'emoji': '[S]', 'label': 'Ultima senal'},
  {'emoji': '[!]', 'label': 'Zona de interes'},
];

class MapaOperativoView extends StatefulWidget {
  final ReporteModel ficha;
  final bool esCreador;

  const MapaOperativoView({
    super.key,
    required this.ficha,
    required this.esCreador,
  });

  @override
  State<MapaOperativoView> createState() => _MapaOperativoViewState();
}

class _PistaInfo {
  final String? id; // ID de la BD para editar/borrar
  final LatLng punto;
  final String etiqueta;
  final String fecha;
  final String hora; // Añadimos la hora
  final String? descripcion;
  final String? cuadranteId;
  final int nivelExpansion;
  _PistaInfo({
    this.id,
    required this.punto, 
    required this.etiqueta, 
    required this.fecha, 
    required this.hora,
    this.descripcion,
    this.cuadranteId,
    this.nivelExpansion = 1,
  });
}

class _MapaOperativoViewState extends State<MapaOperativoView> {
  final MapController _mapController = MapController();
  final ApiService _api = ApiService();
  final CuadranteService _cuadranteService = CuadranteService();
  final EvidenciaService _evidenciaService = EvidenciaService();
  final LocalDatabase _localDb = LocalDatabase(); // E9.3

  LatLng? _lpp;
  List<_VoluntarioRecorrido> _recorridos = [];
  bool _cargandoRecorridos = true;
  bool _useSatellite = true;

  // Cuadrantes de la BD
  List<CuadranteModel> _cuadrantes = [];
  Map<String, List<LatLng>> _cuadrantePoints = {}; // Caché de puntos
  List<Polygon>? _cachedPolygons;

  // ── Estado de pistas ──────────────────────────────────────────────────────
  bool _modoPista = false;
  LatLng? _pinTemporal;
  CuadranteModel? _cuadranteTemporal; // Cuadrante donde cae el pin
  String _etiquetaSeleccionada = 'Nueva pista';
  final TextEditingController _descripcionPistaCtrl = TextEditingController();
  bool _guardandoPista = false;
  List<_PistaInfo> _pistas = [];
  List<EvidenciaModel> _evidencias = [];
  _PistaInfo? _pistaTooltip; // pista que está mostrando tooltip
  _PistaInfo? _pistaEnEdicion; // Pista que se está moviendo/editando
  bool _editandoPista = false; // Indica si estamos en modo edición

  // Polling
  Timer? _pollingTimer;

  // E9.2 — Caché de tiles: estado de la pre-descarga del área operativa
  final TileCacheService _tileCache = TileCacheService();
  bool _descargandoTiles = false;
  int _tilesCompletados = 0;
  int _tilesTotal = 0;
  bool _descargaCompletada = false;

  @override
  void initState() {
    super.initState();
    _parseData();
    _cargarCuadrantes();
    _cargarRecorridos();
    _cargarPistas();
    _cargarEvidencias();
    
    // Iniciar Smart Polling cada 15 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _recargarDatosSilencioso();
    });

    // E9.2 — Pre-descargar tiles del área operativa cuando haya conexión
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ConnectivityService().isOnline) _preDescargarTiles();
    });
  }

  Future<void> _recargarDatosSilencioso() async {
    // Cargamos pistas y recorridos en segundo plano sin mostrar spinners
    try {
      await Future.wait([
        _cargarPistas(),
        _cargarRecorridos(),
        _cargarEvidencias(),
      ]);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _descripcionPistaCtrl.dispose();
    super.dispose();
  }

  // ── E9.2: Pre-descarga de tiles del cuadrante asignado ──────────────────

  /// Descarga y almacena en disco los tiles del bounding box centrado
  /// en el LPP con un radio de ~2 km, para los zoom [13..17].
  Future<void> _preDescargarTiles() async {
    if (_descargandoTiles || !mounted) return;

    // Radio del bounding box en grados (~2 km latitudinal)
    const delta = 0.018;
    final center = _lpp ?? LatLng(widget.ficha.latitud ?? 0, widget.ficha.longitud ?? 0);

    final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    final useMapbox = mapboxToken.isNotEmpty && mapboxToken.startsWith('pk.');

    final urlTemplate = useMapbox
        ? 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    if (!mounted) return;
    setState(() {
      _descargandoTiles = true;
      _descargaCompletada = false;
    });

    try {
      await _tileCache.preDescargarAreaOperativa(
        latMin: center.latitude - delta,
        latMax: center.latitude + delta,
        lngMin: center.longitude - delta,
        lngMax: center.longitude + delta,
        urlTemplate: urlTemplate,
        additionalOptions: useMapbox ? {'accessToken': mapboxToken} : {},
        storeName: TileCacheService.defaultStore,
        onProgress: (completados, total) {
          if (mounted) {
            setState(() {
              _tilesCompletados = completados;
              _tilesTotal = total;
            });
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _descargandoTiles = false;
          _descargaCompletada = true;
        });
        // Ocultar el indicador de éxito después de 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _descargaCompletada = false);
        });
      }
    }
  }

  void _parseData() {
    if (widget.ficha.latitud != null && widget.ficha.longitud != null) {
      _lpp = LatLng(widget.ficha.latitud!, widget.ficha.longitud!);
    }
  }

  Future<void> _cargarCuadrantes() async {
    final resultados = await _cuadranteService.getCuadrantes();
    if (mounted) {
      setState(() {
        _cuadrantes = resultados;
        _cuadrantePoints.clear();
        for (var c in _cuadrantes) {
          if (c.geometria != null) {
            try {
              var geometryData = c.geometria;
              final geometry = geometryData!['type'] == 'Feature'
                  ? geometryData['geometry']
                  : geometryData;
              if (geometry['type'] == 'Polygon') {
                final coords = geometry['coordinates'][0] as List;
                _cuadrantePoints[c.id] = coords.map((coord) {
                  return LatLng(double.parse(coord[1].toString()), double.parse(coord[0].toString()));
                }).toList();
              }
            } catch (_) {
              // Fallback si falla el parseo de la geometría
              _usarBoundingBoxParaCuadrante(c);
            }
          } else {
            // Fallback si no hay geometría: usar lat_min, lat_max, etc.
            _usarBoundingBoxParaCuadrante(c);
          }
        }
        _actualizarCachePoligonos();
      });
    }
  }

  void _usarBoundingBoxParaCuadrante(CuadranteModel c) {
    if (c.latMin != null && c.latMax != null && c.lngMin != null && c.lngMax != null) {
      _cuadrantePoints[c.id] = [
        LatLng(c.latMin!, c.lngMin!),
        LatLng(c.latMin!, c.lngMax!),
        LatLng(c.latMax!, c.lngMax!),
        LatLng(c.latMax!, c.lngMin!),
        LatLng(c.latMin!, c.lngMin!), // Cerrar el polígono
      ];
    }
  }
  // ── Algoritmo Ray-Casting para detectar punto en polígono ───────────────
  bool _puntoEnPoligono(LatLng punto, List<LatLng> poligono) {
    if (poligono.isEmpty) return false;
    bool inside = false;
    int n = poligono.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      if (((poligono[i].latitude > punto.latitude) != (poligono[j].latitude > punto.latitude)) &&
          (punto.longitude < (poligono[j].longitude - poligono[i].longitude) * (punto.latitude - poligono[i].latitude) / (poligono[j].latitude - poligono[i].latitude) + poligono[i].longitude)) {
        inside = !inside;
      }
    }
    return inside;
  }



  void _actualizarCachePoligonos() {
    if (_cuadrantes.isEmpty) return;
    
    setState(() {
      final List<Polygon> finalPolygons = [];
      const double radioGrados = 0.0009; // Mismo tamaño que en la web

      // 1. Dibujar la cuadrícula base
      for (var c in _cuadrantes) {
        final points = _cuadrantePoints[c.id];
        if (points == null || points.isEmpty) continue;

        bool esOficial = widget.ficha.cuadranteId != null && widget.ficha.cuadranteId == c.id;
        
        // Rejilla base (MÁS FUERTE como pidió el usuario)
        finalPolygons.add(Polygon(
          points: points,
          color: Colors.transparent, // NUNCA rellenar de azul
          borderColor: Colors.blue.withOpacity(0.5), // Azul más fuerte y visible
          borderStrokeWidth: esOficial ? 2.5 : 1.5, // El oficial tiene un borde ligeramente más firme
        ));
      }

      // 2. Dibujar mini-cuadrantes verdes dinámicos con expansión CONTROLADA por la BD
      const double radioBase = 0.0007; // Reducido un poco para que no sea tan gigante
      
      // 2.1 Dibujar zona del LPP
      if (_lpp != null) {
        final int nivelLPP = widget.ficha.nivelExpansion;
        final double radioLPP = radioBase * nivelLPP;
        finalPolygons.add(Polygon(
          points: [
            LatLng(_lpp!.latitude - radioLPP, _lpp!.longitude - radioLPP),
            LatLng(_lpp!.latitude - radioLPP, _lpp!.longitude + radioLPP),
            LatLng(_lpp!.latitude + radioLPP, _lpp!.longitude + radioLPP),
            LatLng(_lpp!.latitude + radioLPP, _lpp!.longitude - radioLPP),
          ],
          color: const Color(0xFF10B981).withOpacity(0.25),
          borderColor: const Color(0xFF059669),
          borderStrokeWidth: 2.5,
        ));
      }

      // 2.2 Dibujar zonas de cada PISTA
      for (var p in _pistas) {
        final int nivelPista = p.nivelExpansion;
        final double radioPista = radioBase * nivelPista;

        finalPolygons.add(Polygon(
          points: [
            LatLng(p.punto.latitude - radioPista, p.punto.longitude - radioPista),
            LatLng(p.punto.latitude - radioPista, p.punto.longitude + radioPista),
            LatLng(p.punto.latitude + radioPista, p.punto.longitude + radioPista),
            LatLng(p.punto.latitude + radioPista, p.punto.longitude - radioPista),
          ],
          color: const Color(0xFF10B981).withOpacity(0.25),
          borderColor: const Color(0xFF059669),
          borderStrokeWidth: 2.5,
        ));
      }



      _cachedPolygons = finalPolygons;
    });
  }

  CuadranteModel? _encontrarCuadranteLocal(double lat, double lng) {
    for (var c in _cuadrantes) {
      // Prioridad 1: Geometría compleja (si existe)
      if (_cuadrantePoints.containsKey(c.id)) {
        if (_puntoEnPoligono(LatLng(lat, lng), _cuadrantePoints[c.id]!)) {
          return c;
        }
      } 
      // Prioridad 2: Bounding box (Rejilla base)
      else if (c.latMin != null && c.latMax != null && c.lngMin != null && c.lngMax != null) {
        if (lat >= c.latMin! && lat <= c.latMax! && lng >= c.lngMin! && lng <= c.lngMax!) {
          return c;
        }
      }
    }
    return null;
  }

  Future<void> _detectarCuadranteTemporal(double lat, double lng) async {
    // Primero intentamos detección local (Instantánea y sin internet)
    final localMatch = _encontrarCuadranteLocal(lat, lng);
    
    if (localMatch != null) {
      setState(() {
        _cuadranteTemporal = localMatch;
        _actualizarCachePoligonos();
      });
      return;
    }

    // Fallback a la API si lo local falla (para mayor seguridad)
    final res = await _cuadranteService.detectarCuadrante(lat, lng);
    if (mounted) {
      setState(() {
        _cuadranteTemporal = res;
        _actualizarCachePoligonos();
      });
    }
  }

  Future<void> _cargarRecorridos() async {
    try {
      final response = await _api.client
          .get('/reportes/${widget.ficha.id}/voluntarios/recorridos');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> raw = response.data['data'] ?? [];
        setState(() {
          _recorridos = raw.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value as Map<String, dynamic>;
            final puntos = (item['puntos'] as List?)
                    ?.map((p) => LatLng(
                        (p['lat'] as num).toDouble(),
                        (p['lng'] as num).toDouble()))
                    .toList() ??
                [];
            final nombre = item['usuario']?['nombre']?.toString() ?? 'Voluntario';
            final terminado = item['estado_busqueda'] == 'terminado';
            return _VoluntarioRecorrido(
              nombre: nombre,
              puntos: puntos,
              color: _coloresVoluntarios[idx % _coloresVoluntarios.length],
              terminado: terminado,
            );
          }).toList();
        });
      }
    } catch (_) {
    } finally {
      setState(() => _cargandoRecorridos = false);
    }
  }

  Future<void> _cargarPistas() async {
    // Sin red o latencia alta (E9.4): servir del caché local
    if (ConnectivityService().shouldUseCache) {
      try {
        final pistasLocales = await _localDb.getPistas(widget.ficha.id);
        if (pistasLocales.isNotEmpty && mounted) {
          setState(() {
            _pistas = pistasLocales.map((p) {
              return _PistaInfo(
                id: p['id']?.toString(),
                punto: LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ),
                etiqueta: p['etiqueta']?.toString() ?? 'Pista',
                fecha: p['fecha']?.toString() ?? '',
                hora: p['hora']?.toString() ?? '',
                descripcion: p['descripcion']?.toString(),
                cuadranteId: p['cuadrante_id']?.toString(),
                nivelExpansion: widget.ficha.nivelExpansion,
              );
            }).where((p) => p.punto.latitude != 0).toList();
            _actualizarCachePoligonos();
          });
        }
      } catch (e) {
        debugPrint('Error leyendo pistas locales: $e');
      }
      return;
    }

    // Con red: cargar del API y persistir
    try {
      final response = await _api.client.get('/reportes/${widget.ficha.id}/pistas');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> raw = response.data['data'] ?? [];

        // E9.3 — Persistir en SQLite para uso offline
        final pistasMaps = raw.map((p) {
          final lat = double.tryParse(p['ubicacion_lat']?.toString() ?? '0') ?? 0.0;
          final lng = double.tryParse(p['ubicacion_lng']?.toString() ?? '0') ?? 0.0;
          final fullDate = p['created_at']?.toString() ?? '';
          return {
            'id': p['id']?.toString(),
            'cuadrante_id': p['cuadrante_id']?.toString(),
            'etiqueta': p['mensaje']?.toString() ?? 'Pista',
            'descripcion': p['direccion_referencia']?.toString(),
            'lat': lat,
            'lng': lng,
            'fecha': fullDate.length >= 10 ? fullDate.substring(0, 10) : '',
            'hora': fullDate.length >= 19 ? fullDate.substring(11, 16) : '',
          };
        }).toList();

        if (pistasMaps.isNotEmpty) {
          await _localDb.upsertPistas(widget.ficha.id, pistasMaps);
        }

        if (mounted) {
          setState(() {
            _pistas = pistasMaps.map((p) {
              return _PistaInfo(
                id: p['id']?.toString(),
                punto: LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ),
                etiqueta: p['etiqueta']?.toString() ?? 'Pista',
                fecha: p['fecha']?.toString() ?? '',
                hora: p['hora']?.toString() ?? '',
                descripcion: p['descripcion']?.toString(),
                cuadranteId: p['cuadrante_id']?.toString(),
                nivelExpansion: widget.ficha.nivelExpansion,
              );
            }).where((p) => p.punto.latitude != 0).toList();
            _actualizarCachePoligonos();
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando pistas: $e');
      // Fallback al caché local si falla la red
      try {
        final pistasLocales = await _localDb.getPistas(widget.ficha.id);
        if (pistasLocales.isNotEmpty && mounted) {
          setState(() {
            _pistas = pistasLocales.map((p) {
              return _PistaInfo(
                id: p['id']?.toString(),
                punto: LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ),
                etiqueta: p['etiqueta']?.toString() ?? 'Pista',
                fecha: p['fecha']?.toString() ?? '',
                hora: p['hora']?.toString() ?? '',
                descripcion: p['descripcion']?.toString(),
                cuadranteId: p['cuadrante_id']?.toString(),
                nivelExpansion: widget.ficha.nivelExpansion,
              );
            }).where((p) => p.punto.latitude != 0).toList();
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _cargarEvidencias() async {
    try {
      final evi = await _evidenciaService.obtenerEvidencias(widget.ficha.id);
      final approved = evi.where((e) => e.estado == 'approved').toList();
      if (mounted) setState(() => _evidencias = approved);
    } catch (e) {
      debugPrint('Error cargando evidencias: $e');
    }
  }

  void _iniciarEdicionPista(_PistaInfo pista) {
    if (pista.id == 'LPP') {
      // Para el punto original, entrar directamente en modo de mover
      // sin abrir selectores de etiqueta ni descripción
      setState(() {
        _pistaEnEdicion = pista;
        _editandoPista = true;
        _modoPista = true;
        _pinTemporal = pista.punto;
        _etiquetaSeleccionada = pista.etiqueta; // Mantiene 'Visto por última vez'
        _pistaTooltip = null;
      });
      _detectarCuadranteTemporal(pista.punto.latitude, pista.punto.longitude);
      return;
    }
    setState(() {
      _pistaEnEdicion = pista;
      _editandoPista = true;
      _modoPista = true;
      _pinTemporal = pista.punto;
      _etiquetaSeleccionada = pista.etiqueta;
      _descripcionPistaCtrl.text = pista.descripcion ?? '';
      _pistaTooltip = null;
    });
    _detectarCuadranteTemporal(pista.punto.latitude, pista.punto.longitude);
  }

  void _confirmarEliminarPista(_PistaInfo pista) {
    if (pista.id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar pista?'),
        content: const Text('Esta acción quitará el punto de información del mapa definitivamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _eliminarPista(pista.id!);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarPista(String id) async {
    try {
      final response = await _api.client.delete('/reportes/pistas/$id');
      if (response.data['success'] == true) {
        setState(() {
          _pistas.removeWhere((p) => p.id == id);
          _pistaTooltip = null;
        });
        await _cargarPistas(); // Recargar para asegurar sincronización con el backend
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pista eliminada correctamente')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar la pista')),
      );
    }
  }

  Future<void> _guardarPista() async {
    if (_pinTemporal == null) return;

    // VALIDACIÓN DE SEGURIDAD: No permitir puntos fuera de la zona de búsqueda
    if (_cuadranteTemporal == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Ubicación fuera de límites. Debes colocar el punto dentro de la zona de cuadrantes.')),
            ],
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
      return;
    }

    setState(() => _guardandoPista = true);
    try {
      final userId = await _api.getCurrentUserId();

      // ── Caso especial: mover el punto original (LPP) ──────────────
      if (_editandoPista && _pistaEnEdicion?.id == 'LPP') {
        final lppData = {
          'ubicacion_exacta_lat': _pinTemporal!.latitude,
          'ubicacion_exacta_lng': _pinTemporal!.longitude,
          'cuadrante_id': _cuadranteTemporal?.id,
        };
        final response = await _api.client.put(
          '/reportes/${widget.ficha.id}',
          data: lppData,
        );
        if ((response.statusCode == 200) && response.data['success'] == true) {
          setState(() {
            _lpp = _pinTemporal;
            _pinTemporal = null;
            _cuadranteTemporal = null;
            _modoPista = false;
            _editandoPista = false;
            _pistaEnEdicion = null;
          });
          await _cargarPistas();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Punto original actualizado correctamente'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ));
          }
        } else {
          throw Exception(response.data['message'] ?? 'Error al mover el punto original');
        }
        return;
      }

      // ── Caso normal: crear o editar una pista ─────────────────────
      final desc = _descripcionPistaCtrl.text.trim();
      final data = {
        'usuario_id': userId,
        'lat': _pinTemporal!.latitude,
        'lng': _pinTemporal!.longitude,
        'etiqueta': _etiquetaSeleccionada,
        'descripcion': desc.isNotEmpty ? desc : null,
        'cuadrante_id': _cuadranteTemporal?.id,
      };

      final response = _editandoPista
        ? await _api.client.put('/reportes/pistas/${_pistaEnEdicion!.id}', data: data)
        : await _api.client.post('/reportes/${widget.ficha.id}/pistas', data: data);

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        setState(() {
          _pinTemporal = null;
          _cuadranteTemporal = null;
          _modoPista = false;
          _editandoPista = false;
          _pistaEnEdicion = null;
          _descripcionPistaCtrl.clear();
        });
        
        await _cargarPistas();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(_editandoPista ? 'Cambios guardados' : 'Nueva pista guardada')),
            ]),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      } else {
        throw Exception(response.data['message'] ?? response.data['error'] ?? 'Error al guardar');
      }
    } catch (e) {
      if (mounted) {
        String msg = 'No se pudo guardar la pista. Verifica tu conexión.';
        if (e is DioException && e.response?.data != null) {
          msg = e.response!.data['message'] ?? e.response!.data['error'] ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _guardandoPista = false);
    }
  }

  /// Muestra un diálogo de confirmación serio para mover el punto original (LPP).
  /// No se permite cambiar la etiqueta ni la descripción del LPP.
  void _mostrarConfirmacionMoverLPP() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
        title: const Text(
          '¿Mover punto original?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Estás a punto de cambiar la ubicación del punto original de la búsqueda '
              '(Último Punto Visto). Este es el punto más importante del operativo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nueva ubicación: ${_pinTemporal!.latitude.toStringAsFixed(5)}, '
                      '${_pinTemporal!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _guardarPista();
            },
            icon: const Icon(Icons.move_down, size: 18),
            label: const Text('Sí, mover punto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorParaEtiqueta(String etiqueta) {
    switch (etiqueta) {
      case 'Visto por última vez': return Colors.purple;
      case 'Nueva pista': return Colors.grey;
      case 'Última señal': return Colors.white;
      case 'Zona de interés': return Colors.yellow;
      default: return const Color(0xFFF59E0B);
    }
  }

  void _mostrarSelectorEtiqueta() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        String etiquetaLocal = _etiquetaSeleccionada;
        return StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ClipOval(
                        child: widget.ficha.fotoUrl != null
                            ? Image.network(
                                widget.ficha.fotoUrl!,
                                width: 44, height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                              )
                            : _avatarPlaceholder(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.ficha.titulo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(
                              _cuadranteTemporal != null
                                  ? 'Cuadrante: ${_cuadranteTemporal!.codigo}'
                                  : 'Lat: ${_pinTemporal!.latitude.toStringAsFixed(5)}, Lng: ${_pinTemporal!.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_editandoPista ? 'Editar información' : 'Tipo de pista o información',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.primary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _etiquetasPista.map((e) {
                      final label = e['label']!;
                      final selected = etiquetaLocal == label;
                      return FilterChip(
                        label: Text('${e['emoji']} $label',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        selected: selected,
                        onSelected: (_) => setModalState(() => etiquetaLocal = label),
                        selectedColor: AppTheme.primaryLight.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.primary,
                        backgroundColor: Colors.grey[100],
                        side: BorderSide(
                            color: selected
                                ? AppTheme.primary
                                : Colors.grey[300]!),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descripcionPistaCtrl,
                    decoration: InputDecoration(
                      labelText: 'Descripción o detalles (opcional)',
                      labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary)),
                    ),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            // Permanece en modoPista para poder mover el pin si quiere
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _etiquetaSeleccionada = etiquetaLocal);
                            Navigator.pop(ctx);
                            _guardarPista();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _guardandoPista
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _avatarPlaceholder() => Container(
        width: 44, height: 44,
        color: Colors.grey[200],
        child: const Icon(Icons.person, color: Colors.grey),
      );

  void _mostrarLeyendaVoluntarios() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.people_alt, color: AppTheme.primary),
                  SizedBox(width: 10),
                  Text(
                    'Voluntarios Activos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _recorridos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final r = _recorridos[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: r.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(r.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: r.terminado
                          ? const Icon(Icons.check_circle, color: AppTheme.success, size: 20)
                          : const Icon(Icons.radio_button_checked, color: Colors.orange, size: 20),
                      subtitle: Text(
                        r.terminado ? 'Búsqueda finalizada' : 'Buscando en vivo',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDetallesEvidencia(EvidenciaModel evidencia) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFF6F00),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              const Icon(Icons.photo_camera, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Evidencia Fotográfica',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (evidencia.fotoUrl != null && evidencia.fotoUrl!.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageView(
                          imageUrl: evidencia.fotoUrl!,
                          tag: 'map-ev-${evidencia.id}',
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'map-ev-${evidencia.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        evidencia.fotoUrl!,
                        height: 200,
                        width: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              // Info del voluntario
              if (evidencia.nombreUsuario != null)
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Color(0xFFFF6F00)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        evidencia.nombreUsuario!,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              if (evidencia.creadoEn != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${evidencia.creadoEn!.day}/${evidencia.creadoEn!.month}/${evidencia.creadoEn!.year} a las ${evidencia.creadoEn!.hour.toString().padLeft(2, '0')}:${evidencia.creadoEn!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              if (evidencia.descripcion.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Text(
                  evidencia.descripcion,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
              // Coordenadas GPS
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${evidencia.lat!.toStringAsFixed(5)}, ${evidencia.lng!.toStringAsFixed(5)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500], fontFamily: 'monospace'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_lpp == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mapa Operativo')),
        body: const Center(child: Text('La ficha no tiene un punto LPP establecido.')),
      );
    }

    // Unificamos todos los marcadores en una sola lista para evitar que se tapen
    final List<Marker> todosLosMarkers = [];

    // 1. Punto inicial (Pepe - LPP)
    final _PistaInfo lppInfo = _PistaInfo(
      id: 'LPP', // ID especial para identificar el punto original
      punto: _lpp!,
      etiqueta: 'Visto por última vez',
      fecha: widget.ficha.fechaPerdida ?? '',
      hora: '', // Opcional
      descripcion: 'Punto de inicio de la búsqueda (LPP)',
      cuadranteId: null,
      nivelExpansion: widget.ficha.nivelExpansion,
    );

    todosLosMarkers.add(
      Marker(
        point: _lpp!,
        width: 100,
        height: 100,
        alignment: Alignment.center,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _pistaTooltip = _pistaTooltip == lppInfo ? null : lppInfo);
              });
            });
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: LppMarker(
              fotoUrl: widget.ficha.fotoUrl,
              color: const Color(0xFFD32F2F), // Rojo para el original
            ),
          ),
        ),
      ),
    );

    // 2. Pistas de información
    for (var pista in _pistas) {
      todosLosMarkers.add(
        Marker(
          key: ValueKey('pista_${pista.punto.latitude}_${pista.punto.longitude}'),
          point: pista.punto,
          width: 80,
          height: 70,
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Future.delayed(const Duration(milliseconds: 150), () {
                if (!mounted) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _pistaTooltip = _pistaTooltip == pista ? null : pista);
                });
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: LppMarker(
                fotoUrl: widget.ficha.fotoUrl,
                nombre: pista.etiqueta,
                color: _getColorParaEtiqueta(pista.etiqueta),
              ),
            ),
          ),
        ),
      );
    }

    // 3. Pin temporal de edición
    if (_pinTemporal != null) {
      todosLosMarkers.add(
        Marker(
          point: _pinTemporal!,
          width: 50,
          height: 50,
          alignment: Alignment.center,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 50,
            shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
          ),
        ),
      );
    }

    // 4. Marcadores de posición actual de voluntarios
    for (var r in _recorridos) {
      if (r.puntos.isNotEmpty) {
        todosLosMarkers.add(
          Marker(
            point: r.puntos.last,
            width: 100,
            height: 60,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))
                    ],
                  ),
                  child: Text(
                    r.nombre,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: r.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(
                  Icons.person_pin_circle,
                  color: r.color,
                  size: 32,
                  shadows: const [Shadow(color: Colors.white, blurRadius: 2)],
                ),
              ],
            ),
          ),
        );
      }
    }

    // 5. Evidencias fotográficas (ícono personalizado de cámara)
    todosLosMarkers.addAll(_evidencias.where((e) => e.lat != null && e.lng != null).map((evidencia) {
      return Marker(
        key: ValueKey('evidencia_${evidencia.id}'),
        point: LatLng(evidencia.lat!, evidencia.lng!),
        width: 100,
        height: 100,
        alignment: Alignment.center,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _mostrarDetallesEvidencia(evidencia);
              });
            });
          },
          child: EvidenciaMarker(
            fotoUrl: evidencia.fotoUrl,
            nombreVoluntario: evidencia.nombreUsuario,
          ),
        ),
      );
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Operativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 24),
            tooltip: 'Recargar página',
            onPressed: () {
              _cargarCuadrantes();
              _cargarPistas();
              _cargarRecorridos();
            },
          ),
          if (widget.esCreador)
            Builder(
              builder: (context) => IconButton(
                icon: _evidencias.isNotEmpty
                    ? Badge(
                        label: Text('${_evidencias.length}'),
                        backgroundColor: const Color(0xFFFF6F00),
                        child: const Icon(Icons.photo_library_outlined, size: 24),
                      )
                    : const Icon(Icons.photo_library_outlined, size: 24),
                tooltip: 'Galería de evidencias',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          if (widget.esCreador)
            TextButton.icon(
              onPressed: () => setState(() {
                _modoPista = !_modoPista;
                if (!_modoPista) { 
                  _pinTemporal = null; 
                  _cuadranteTemporal = null; 
                  _actualizarCachePoligonos(); 
                }
              }),
              icon: Icon(_modoPista ? Icons.close : Icons.add_location_alt, 
                        color: _modoPista ? Colors.red : Colors.white),
              label: Text(_modoPista ? 'Cerrar' : 'Añadir', 
                         style: TextStyle(color: _modoPista ? Colors.red : Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      endDrawer: widget.esCreador
          ? Drawer(
              width: 320,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.primary.withOpacity(0.08),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_library, color: AppTheme.primary),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Galería de Evidencias',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                                ),
                                Text(
                                  'Orden cronológico (más reciente primero)',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _evidencias.isEmpty
                          ? const Center(
                              child: Text(
                                'Aún no hay evidencias aprobadas.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _evidencias.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final listaOrdenada = _evidencias.toList()
                                  ..sort((a, b) => (b.creadoEn ?? DateTime.now()).compareTo(a.creadoEn ?? DateTime.now()));
                                final evidencia = listaOrdenada[i];
                                return InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (evidencia.lat != null && evidencia.lng != null) {
                                      _mapController.move(LatLng(evidencia.lat!, evidencia.lng!), 16.5);
                                      Future.delayed(const Duration(milliseconds: 250), () {
                                        if (!mounted) return;
                                        _mostrarDetallesEvidencia(evidencia);
                                      });
                                    }
                                  },
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          if (evidencia.fotoUrl != null && evidencia.fotoUrl!.isNotEmpty)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: CachedNetworkImage(
                                                imageUrl: evidencia.fotoUrl!,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) => Container(width: 60, height: 60, color: Colors.grey[100]),
                                                errorWidget: (_, __, ___) => Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.photo_camera, color: Colors.orange, size: 24),
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  evidencia.nombreUsuario ?? 'Voluntario',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  evidencia.descripcion.isNotEmpty ? evidencia.descripcion : 'Sin descripción.',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.access_time, size: 10, color: Colors.grey),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      evidencia.creadoEn != null
                                                          ? '${evidencia.creadoEn!.day}/${evidencia.creadoEn!.month} a las ${evidencia.creadoEn!.hour.toString().padLeft(2, '0')}:${evidencia.creadoEn!.minute.toString().padLeft(2, '0')}'
                                                          : 'Hace un momento',
                                                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _lpp!,
              initialZoom: 15.5,
              onTap: (tapPosition, latLng) {
                if (!_modoPista || !widget.esCreador) return;
                setState(() => _pinTemporal = latLng);
                _detectarCuadranteTemporal(latLng.latitude, latLng.longitude);
              },
            ),
            children: [
              MapTileLayer(useSatellite: _useSatellite),
              if (_cachedPolygons != null) PolygonLayer(polygons: _cachedPolygons!),
              if (_recorridos.isNotEmpty)
                PolylineLayer(
                  polylines: _recorridos.map((r) => Polyline(
                    points: r.puntos,
                    color: r.color.withOpacity(r.terminado ? 0.8 : 0.4),
                    strokeWidth: r.terminado ? 4 : 3,
                  )).toList(),
                ),
              MarkerLayer(markers: todosLosMarkers),
            ],
          ),


          if (_modoPista && _pinTemporal == null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Toca el mapa para agregar una pista',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_recorridos.isNotEmpty)
            Positioned(
              top: _modoPista ? 70 : 12,
              right: 12,
              child: FloatingActionButton.extended(
                heroTag: 'btn_leyenda_voluntarios',
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                icon: const Icon(Icons.people_alt, size: 20),
                label: Text('Voluntarios (${_recorridos.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _mostrarLeyendaVoluntarios,
              ),
            ),

          Positioned(
            bottom: _modoPista ? 20 : 80,
            left: 20,
            child: MapLayerToggleButton(
              heroTag: null,
              useSatellite: _useSatellite,
              onToggle: () => setState(() => _useSatellite = !_useSatellite),
            ),
          ),

          // E9.2 — Indicador de estado del caché de tiles
          if (_descargandoTiles || _descargaCompletada)
            Positioned(
              bottom: _modoPista ? 68 : 128,
              left: 12,
              right: 80, // No solapar con los FABs de la derecha
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                    ],
                  ),
                  child: _descargaCompletada
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.offline_pin, color: Color(0xFF10B981), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Área guardada offline',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Guardando mapa offline... $_tilesCompletados/$_tilesTotal',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (_tilesTotal > 0)
                              LinearProgressIndicator(
                                value: _tilesTotal > 0 ? _tilesCompletados / _tilesTotal : 0,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                                minHeight: 3,
                                borderRadius: BorderRadius.circular(2),
                              ),
                          ],
                        ),
                ),
              ),
            ),

          // Botón manual de re-descarga (visible cuando no está descargando)
          if (!_descargandoTiles && !_descargaCompletada && ConnectivityService().isOnline)
            Positioned(
              bottom: _modoPista ? 68 : 128,
              left: 12,
              child: GestureDetector(
                onTap: _preDescargarTiles,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_for_offline_outlined, size: 16, color: AppTheme.primary),
                      SizedBox(width: 5),
                      Text(
                        'Guardar offline',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: (_modoPista && _pinTemporal != null) ? 134 : 90,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'btn_centrar_operativo',
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              onPressed: () => _mapController.move(_lpp!, 15.0),
              child: const Icon(Icons.my_location),
            ),
          ),

          if (!_modoPista)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                ),
                child: _cargandoRecorridos
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Cargando recorridos...'),
                        ],
                      )
                    : Text(
                        _recorridos.isEmpty
                            ? 'Aún no hay recorridos registrados en este operativo.'
                            : '${_recorridos.length} recorrido(s) de voluntarios registrado(s).',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary),
                      ),
              ),
            ),

          // ── Tooltip de detalle de Pista (Rediseñado arriba a la izquierda) ──
          if (_pistaTooltip != null)
            Positioned(
              top: 70, // Debajo de la barra superior
              left: 12,
              width: 280, // Ancho fijo para que sea un panel lateral pequeño
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(2, 4))
                  ],
                  border: Border.all(color: _getColorParaEtiqueta(_pistaTooltip!.etiqueta).withOpacity(0.3), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _getColorParaEtiqueta(_pistaTooltip!.etiqueta).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.info_outline, color: _getColorParaEtiqueta(_pistaTooltip!.etiqueta), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _pistaTooltip!.etiqueta,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _getColorParaEtiqueta(_pistaTooltip!.etiqueta),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                          onPressed: () => setState(() => _pistaTooltip = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      _pistaTooltip!.descripcion ?? 'Sin detalles adicionales.',
                      style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_pistaTooltip!.fecha} a las ${_pistaTooltip!.hora}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        if (widget.esCreador)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 4,
                              children: [
                                // Botón MOVER (Para todos)
                                TextButton.icon(
                                  onPressed: () => _iniciarEdicionPista(_pistaTooltip!),
                                  icon: const Icon(Icons.move_down, size: 16),
                                  label: const Text('Mover', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2196F3),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                // Botón ELIMINAR (Solo si NO es el original LPP)
                                if (_pistaTooltip!.id != 'LPP')
                                  TextButton.icon(
                                    onPressed: () => _confirmarEliminarPista(_pistaTooltip!),
                                    icon: const Icon(Icons.delete_outline, size: 16),
                                    label: const Text('Eliminar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ── Botón de confirmar cuando hay un pin temporal ────────────────
          if (_modoPista && _pinTemporal != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: (_editandoPista && _pistaEnEdicion?.id == 'LPP')
                      ? Colors.orange.withOpacity(0.95)
                      : AppTheme.primary.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black38, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (_editandoPista && _pistaEnEdicion?.id == 'LPP')
                                ? 'Moviendo punto original'
                                : _cuadranteTemporal != null
                                    ? 'En cuadrante: ${_cuadranteTemporal!.codigo}'
                                    : 'Ubicación seleccionada',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            (_editandoPista && _pistaEnEdicion?.id == 'LPP')
                                ? 'Toca en el mapa para elegir la nueva posición'
                                : 'Puedes seguir moviendo el pin',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: (_editandoPista && _pistaEnEdicion?.id == 'LPP')
                            ? _mostrarConfirmacionMoverLPP
                            : _mostrarSelectorEtiqueta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 18),
                            SizedBox(width: 6),
                            Text('Confirmar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VoluntarioRecorrido {
  final String nombre;
  final List<LatLng> puntos;
  final Color color;
  final bool terminado;

  const _VoluntarioRecorrido({
    required this.nombre,
    required this.puntos,
    required this.color,
    required this.terminado,
  });
}
