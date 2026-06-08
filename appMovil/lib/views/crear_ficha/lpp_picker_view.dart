import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/crear_ficha_viewmodel.dart';
import '../../services/nominatim_service.dart';
import '../../widgets/map_tile_layer.dart';
import '../../models/cuadrante_model.dart';
import '../../services/cuadrante_service.dart';

class LPPPickerView extends StatefulWidget {
  const LPPPickerView({super.key});

  @override
  State<LPPPickerView> createState() => _LPPPickerViewState();
}

class _LPPPickerViewState extends State<LPPPickerView> {
  LatLng? _selectedLPP;
  final MapController _mapController = MapController();
  final LatLng _defaultCenter = const LatLng(-17.7833, -63.1821);
  bool _useSatellite = true;

  // Cuadrantes
  List<CuadranteModel> _cuadrantes = [];
  List<Polygon>? _cachedPolygons; // Memoria para evitar lag
  final CuadranteService _cuadranteService = CuadranteService();
  CuadranteModel? _cuadranteSeleccionado;

  // Buscador
  final TextEditingController _searchController = TextEditingController();
  final NominatimService _nominatim = NominatimService();
  List<LugarSugerido> _sugerencias = [];
  bool _buscando = false;
  Timer? _debounce;
  bool _mostrarSugerencias = false;

  @override
  void initState() {
    super.initState();
    final vm = context.read<CrearFichaViewModel>();
    if (vm.latitudLPP != null && vm.longitudLPP != null) {
      _selectedLPP = LatLng(vm.latitudLPP!, vm.longitudLPP!);
      _detectarCuadrante(_selectedLPP!.latitude, _selectedLPP!.longitude);
    }
    _cargarCuadrantes();
  }

  Future<void> _cargarCuadrantes() async {
    final resultados = await _cuadranteService.getCuadrantes();
    if (mounted) {
      setState(() {
        _cuadrantes = resultados;
        _actualizarCachePoligonos();
      });
    }
  }

  void _actualizarCachePoligonos() {
    _cachedPolygons = _cuadrantes.map((c) {
      List<LatLng>? points;
      
      if (c.geometria != null) {
        try {
          var geometryData = c.geometria;
          final geometry = geometryData!['type'] == 'Feature' 
              ? geometryData['geometry'] 
              : geometryData;
          
          if (geometry['type'] == 'Polygon') {
            final coords = geometry['coordinates'][0] as List;
            points = coords.map((coord) {
              return LatLng(double.parse(coord[1].toString()), double.parse(coord[0].toString()));
            }).toList();
          }
        } catch (_) {}
      } 
      
      // Fallback: usar bounding box si no hay geometría compleja
      if (points == null && c.latMin != null) {
        points = [
          LatLng(c.latMin!, c.lngMin!),
          LatLng(c.latMin!, c.lngMax!),
          LatLng(c.latMax!, c.lngMax!),
          LatLng(c.latMax!, c.lngMin!),
          LatLng(c.latMin!, c.lngMin!),
        ];
      }

      if (points == null) return null;

      bool esSeleccionado = _cuadranteSeleccionado?.id == c.id;

      return Polygon(
        points: points,
        color: Colors.transparent, // NUNCA rellenar de azul
        borderColor: Colors.blue.withOpacity(0.5), // Azul más fuerte
        borderStrokeWidth: esSeleccionado ? 2.5 : 1.2, 
      );
    }).whereType<Polygon>().toList();

    // 2. Dibujar mini-cuadrante verde alrededor del LPP seleccionado
    if (_selectedLPP != null) {
      const double radioMini = 0.0008; // Tamaño DOBLE como pidió el usuario
      _cachedPolygons!.add(Polygon(
        points: [
          LatLng(_selectedLPP!.latitude - radioMini, _selectedLPP!.longitude - radioMini),
          LatLng(_selectedLPP!.latitude - radioMini, _selectedLPP!.longitude + radioMini),
          LatLng(_selectedLPP!.latitude + radioMini, _selectedLPP!.longitude + radioMini),
          LatLng(_selectedLPP!.latitude + radioMini, _selectedLPP!.longitude - radioMini),
        ],
        color: const Color(0xFF10B981).withOpacity(0.4),
        borderColor: const Color(0xFF059669),
        borderStrokeWidth: 3.0,
      ));
    }
  }

  CuadranteModel? _encontrarCuadranteLocal(double lat, double lng) {
    for (var c in _cuadrantes) {
      if (c.latMin != null && c.latMax != null && c.lngMin != null && c.lngMax != null) {
        if (lat >= c.latMin! && lat <= c.latMax! && lng >= c.lngMin! && lng <= c.lngMax!) {
          return c;
        }
      }
    }
    return null;
  }

  Future<void> _detectarCuadrante(double lat, double lng) async {
    // Primero intentamos detección local (Instantánea)
    final localMatch = _encontrarCuadranteLocal(lat, lng);
    if (localMatch != null) {
      setState(() {
        _cuadranteSeleccionado = localMatch;
        _actualizarCachePoligonos();
      });
      return;
    }

    final res = await _cuadranteService.detectarCuadrante(lat, lng);
    if (mounted) {
      setState(() {
        _cuadranteSeleccionado = res;
        _actualizarCachePoligonos(); // Refrescar colores al seleccionar
      });
    }
  }

  Future<void> _irAUbicacionActual() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Los servicios de ubicación están desactivados.')));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permiso de ubicación denegado.')));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Los permisos de ubicación están denegados permanentemente.')));
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final punto = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _selectedLPP = punto;
          _mostrarSugerencias = false;
        });
        _mapController.move(punto, 16.0);
        _detectarCuadrante(punto.latitude, punto.longitude);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo obtener la ubicación actual.')));
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onBusquedaCambiada(String texto) {
    _debounce?.cancel();
    if (texto.trim().length < 3) {
      setState(() {
        _sugerencias = [];
        _mostrarSugerencias = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _buscando = true);
      final resultados = await _nominatim.buscar(texto);
      setState(() {
        _sugerencias = resultados;
        _buscando = false;
        _mostrarSugerencias = resultados.isNotEmpty;
      });
    });
  }

  void _seleccionarLugar(LugarSugerido lugar) {
    final punto = LatLng(lugar.lat, lugar.lng);
    setState(() {
      _selectedLPP = punto;
      _sugerencias = [];
      _mostrarSugerencias = false;
      _searchController.text = lugar.nombre;
    });
    _mapController.move(punto, 16.0);
    _detectarCuadrante(punto.latitude, punto.longitude); // Detectar cuadrante al buscar
    FocusScope.of(context).unfocus();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLPP = point;
      _mostrarSugerencias = false;
    });
    _detectarCuadrante(point.latitude, point.longitude);
    FocusScope.of(context).unfocus();
  }

  void _confirmarUbicacion() {
    if (_selectedLPP == null) return;

    // VALIDACIÓN: No permitir puntos fuera de la zona de cuadrantes
    if (_cuadranteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Ubicación inválida. Debes seleccionar un punto dentro de la zona de búsqueda permitida.')),
            ],
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    context.read<CrearFichaViewModel>().setUbicacion(
          _selectedLPP!.latitude,
          _selectedLPP!.longitude,
          [_cuadranteSeleccionado!.id],
        );
    Navigator.pop(context, true);
  }

  void _limpiarUbicacion() {
    setState(() {
      _selectedLPP = null;
      _cuadranteSeleccionado = null;
      _actualizarCachePoligonos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Indicar LPP', style: TextStyle(color: Colors.white)),
        actions: [
          if (_selectedLPP != null) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              onPressed: _limpiarUbicacion,
              tooltip: 'Quitar marcador',
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _confirmarUbicacion,
              tooltip: 'Confirmar Zona',
            ),
          ]
        ],
      ),
      body: Stack(
        children: [
          // ── MAPA ──────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLPP ?? _defaultCenter,
              initialZoom: 14.0,
              onTap: _onMapTap,
            ),
            children: [
              MapTileLayer(useSatellite: _useSatellite),
              if (_cachedPolygons != null)
                PolygonLayer(polygons: _cachedPolygons!),
              if (_selectedLPP != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLPP!,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 44,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Toggle de capas (satelital / callejero) y Mi ubicación
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'my_location',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _irAUbicacionActual,
                  child: const Icon(Icons.my_location, color: AppTheme.primary),
                ),
                const SizedBox(height: 8),
                MapLayerToggleButton(
                  heroTag: null,
                  useSatellite: _useSatellite,
                  onToggle: () => setState(() => _useSatellite = !_useSatellite),
                ),
              ],
            ),
          ),

          // ── BUSCADOR + SUGERENCIAS ─────────────────────
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                // Campo de búsqueda
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onBusquedaCambiada,
                    decoration: InputDecoration(
                      hintText: 'Buscar lugar en Santa Cruz...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                      suffixIcon: _buscando
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _sugerencias = [];
                                      _mostrarSugerencias = false;
                                    });
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                // Lista de sugerencias
                if (_mostrarSugerencias && _sugerencias.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _sugerencias.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 48),
                      itemBuilder: (context, i) {
                        final s = _sugerencias[i];
                        return ListTile(
                          leading: const Icon(
                            Icons.place_outlined,
                            color: AppTheme.primary,
                          ),
                          title: Text(
                            s.nombre,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _seleccionarLugar(s),
                        );
                      },
                    ),
                  ),

                // Instrucción cuando no hay LPP aún
                if (!_mostrarSugerencias && _selectedLPP == null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(
                          'Busca un lugar o toca el mapa para fijar el LPP',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                // Confirmación cuando hay LPP activo
                if (!_mostrarSugerencias && _selectedLPP != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          _cuadranteSeleccionado != null 
                              ? 'Ubicado en: ${_cuadranteSeleccionado!.nombre}. Toca el check para confirmar.'
                              : 'LPP y cuadrantes trazados. Toca el check para confirmar.',
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
