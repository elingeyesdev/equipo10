import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../models/reporte_model.dart';
import '../../services/api_service.dart';
import '../../widgets/map_tile_layer.dart';
import '../../widgets/lpp_marker.dart';
import '../../models/cuadrante_model.dart';
import '../../services/cuadrante_service.dart';

// Paleta de colores para los recorridos de distintos voluntarios
const List<Color> _coloresVoluntarios = [
  Color(0xFF2196F3), // azul
  Color(0xFFFF9800), // naranja
  Color(0xFF9C27B0), // morado
  Color(0xFFE91E63), // rosa
  Color(0xFF00BCD4), // cyan
  Color(0xFF795548), // marrón
];

// Etiquetas disponibles para las pistas (NO incluye 'Visto por última vez',
// esa etiqueta es exclusiva del punto original LPP y no se puede reasignar)
const List<Map<String, String>> _etiquetasPista = [
  {'emoji': '🔍', 'label': 'Nueva pista'},
  {'emoji': '✅', 'label': 'Avistamiento confirmado'},
  {'emoji': '📡', 'label': 'Última señal'},
  {'emoji': '⚠️', 'label': 'Zona de interés'},
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
  _PistaInfo({
    this.id,
    required this.punto, 
    required this.etiqueta, 
    required this.fecha, 
    required this.hora,
    this.descripcion,
    this.cuadranteId,
  });
}

class _MapaOperativoViewState extends State<MapaOperativoView> {
  final MapController _mapController = MapController();
  final ApiService _api = ApiService();
  final CuadranteService _cuadranteService = CuadranteService();

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
  _PistaInfo? _pistaTooltip; // pista que está mostrando tooltip
  _PistaInfo? _pistaEnEdicion; // Pista que se está moviendo/editando
  bool _editandoPista = false; // Indica si estamos en modo edición

  @override
  void initState() {
    super.initState();
    _parseData();
    _cargarCuadrantes();
    _cargarRecorridos();
    _cargarPistas();
  }

  @override
  void dispose() {
    _descripcionPistaCtrl.dispose();
    super.dispose();
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
      _cachedPolygons = _cuadrantes.map((c) {
        final points = _cuadrantePoints[c.id];
        if (points == null || points.isEmpty) return null;

        // Determinar si debe ser rojo
        bool esOficial = widget.ficha.cuadranteId != null && widget.ficha.cuadranteId == c.id;
        bool contieneLPP = _lpp != null && _puntoEnPoligono(_lpp!, points);
        bool tienePista = _pistas.any((p) => p.cuadranteId == c.id);
        bool esTemporal = _cuadranteTemporal?.id == c.id;

        // Prioridad: Si tiene pistas, es el oficial, o es donde cae el LPP (si no hay oficial)
        bool resaltar = esOficial || tienePista || esTemporal || (widget.ficha.cuadranteId == null && contieneLPP);

        if (resaltar) {
          return Polygon(
            points: points,
            color: Colors.red.withOpacity(0.25),
            borderColor: Colors.red.shade900,
            borderStrokeWidth: (esOficial || esTemporal) ? 4.0 : 2.5,
          );
        } else {
          return Polygon(
            points: points,
            color: Colors.blue.withOpacity(0.08),
            borderColor: Colors.blue.withOpacity(0.5),
            borderStrokeWidth: 1.2,
          );
        }
      }).whereType<Polygon>().toList();
    });
  }

  Future<void> _detectarCuadranteTemporal(double lat, double lng) async {
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
    try {
      final response = await _api.client.get('/reportes/${widget.ficha.id}/pistas');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> raw = response.data['data'] ?? [];
        setState(() {
          _pistas = raw.map((p) {
            // Conversión segura de coordenadas (maneja String o num)
            double lat = double.tryParse(p['ubicacion_lat']?.toString() ?? '0') ?? 0;
            double lng = double.tryParse(p['ubicacion_lng']?.toString() ?? '0') ?? 0;
            
            // Extraer fecha y hora de created_at (ej: 2026-04-27 14:30:00)
            String fullDate = p['created_at']?.toString() ?? '';
            String dateOnly = fullDate.length >= 10 ? fullDate.substring(0, 10) : '';
            String timeOnly = fullDate.length >= 19 ? fullDate.substring(11, 16) : '';

            return _PistaInfo(
              id: p['id']?.toString(),
              punto: LatLng(lat, lng),
              etiqueta: p['mensaje']?.toString() ?? 'Pista',
              fecha: dateOnly,
              hora: timeOnly,
              descripcion: p['direccion_referencia']?.toString(),
              cuadranteId: p['cuadrante_id']?.toString(),
            );
          }).where((p) => p.punto.latitude != 0).toList(); // Filtrar puntos inválidos
          
          _actualizarCachePoligonos();
        });
      }
    } catch (e) {
      debugPrint('Error cargando pistas: $e');
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
            backgroundColor: const Color(0xFF1B5E20),
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
      case 'Nueva pista': return Colors.blueGrey;
      case 'Avistamiento confirmado': return Colors.green;
      case 'Última señal': return Colors.blue;
      case 'Zona de interés': return Colors.orange;
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
                          color: Color(0xFF1B5E20))),
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
                        selectedColor: const Color(0xFFB8F5C2),
                        checkmarkColor: const Color(0xFF1B5E20),
                        backgroundColor: Colors.grey[100],
                        side: BorderSide(
                            color: selected
                                ? const Color(0xFF1B5E20)
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
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1B5E20))),
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
                            backgroundColor: const Color(0xFF1B5E20),
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
    );

    todosLosMarkers.add(
      Marker(
        point: _lpp!,
        width: 100,
        height: 100,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => setState(() => _pistaTooltip = _pistaTooltip == lppInfo ? null : lppInfo),
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
            onTap: () => setState(() => _pistaTooltip = _pistaTooltip == pista ? null : pista),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Operativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _cargarCuadrantes();
              _cargarPistas();
              _cargarRecorridos();
            },
          ),
          if (widget.esCreador)
            IconButton(
              icon: Icon(_modoPista ? Icons.close : Icons.add_location_alt, 
                        color: _modoPista ? Colors.red : null),
              onPressed: () => setState(() {
                _modoPista = !_modoPista;
                if (!_modoPista) { 
                  _pinTemporal = null; 
                  _cuadranteTemporal = null; 
                  _actualizarCachePoligonos(); 
                }
              }),
            ),
        ],
      ),
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
              child: _LeyendaRecorridos(recorridos: _recorridos),
            ),

          Positioned(
            bottom: (_modoPista && _pinTemporal != null) ? 140 : 96,
            right: 80,
            child: MapLayerToggleButton(
              heroTag: 'btn_toggle_operativo',
              useSatellite: _useSatellite,
              onToggle: () => setState(() => _useSatellite = !_useSatellite),
            ),
          ),

          Positioned(
            bottom: (_modoPista && _pinTemporal != null) ? 134 : 90,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'btn_centrar_operativo',
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B5E20),
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
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
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
                          '📅 ${_pistaTooltip!.fecha}  🕒 ${_pistaTooltip!.hora}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        if (widget.esCreador)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_location_alt, size: 18, color: Color(0xFF2196F3)),
                                onPressed: () => _iniciarEdicionPista(_pistaTooltip!),
                                tooltip: 'Mover/Editar',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              if (_pistaTooltip!.id != 'LPP')
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  onPressed: () => _confirmarEliminarPista(_pistaTooltip!),
                                  tooltip: 'Eliminar',
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          )
                        else
                          const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
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
                      : const Color(0xFF1B5E20).withOpacity(0.95),
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
                                ? '⚠️ Moviendo punto original'
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
                          foregroundColor: const Color(0xFF1B5E20),
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

class _LeyendaRecorridos extends StatelessWidget {
  final List<_VoluntarioRecorrido> recorridos;

  const _LeyendaRecorridos({required this.recorridos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Voluntarios',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          ...recorridos.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 14, height: 4,
                        decoration: BoxDecoration(color: r.color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text(r.nombre, style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A1A))),
                    const SizedBox(width: 4),
                    if (r.terminado)
                      const Icon(Icons.check_circle, size: 11, color: Color(0xFF4CAF50))
                    else
                      const Icon(Icons.radio_button_checked, size: 11, color: Colors.orange),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
