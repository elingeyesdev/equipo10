import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/crear_ficha_viewmodel.dart';
import '../../services/nominatim_service.dart';

class LPPPickerView extends StatefulWidget {
  const LPPPickerView({super.key});

  @override
  State<LPPPickerView> createState() => _LPPPickerViewState();
}

class _LPPPickerViewState extends State<LPPPickerView> {
  LatLng? _selectedLPP;
  List<List<LatLng>> _drawnQuadrants = [];
  final MapController _mapController = MapController();
  final LatLng _defaultCenter = const LatLng(-17.7833, -63.1821);

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
      _generarCuadrantes(desde: _selectedLPP!);
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
      _generarCuadrantes(desde: punto);
      _sugerencias = [];
      _mostrarSugerencias = false;
      _searchController.text = lugar.nombre;
    });
    _mapController.move(punto, 16.0);
    FocusScope.of(context).unfocus();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLPP = point;
      _generarCuadrantes(desde: point);
      _mostrarSugerencias = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _generarCuadrantes({required LatLng desde}) {
    double delta = 0.002;
    _drawnQuadrants = [
      // Superior izquierdo
      [
        LatLng(desde.latitude, desde.longitude - delta),
        LatLng(desde.latitude + delta, desde.longitude - delta),
        LatLng(desde.latitude + delta, desde.longitude),
        LatLng(desde.latitude, desde.longitude),
      ],
      // Superior derecho
      [
        LatLng(desde.latitude, desde.longitude),
        LatLng(desde.latitude + delta, desde.longitude),
        LatLng(desde.latitude + delta, desde.longitude + delta),
        LatLng(desde.latitude, desde.longitude + delta),
      ],
      // Inferior izquierdo
      [
        LatLng(desde.latitude - delta, desde.longitude - delta),
        LatLng(desde.latitude, desde.longitude - delta),
        LatLng(desde.latitude, desde.longitude),
        LatLng(desde.latitude - delta, desde.longitude),
      ],
      // Inferior derecho
      [
        LatLng(desde.latitude - delta, desde.longitude),
        LatLng(desde.latitude, desde.longitude),
        LatLng(desde.latitude, desde.longitude + delta),
        LatLng(desde.latitude - delta, desde.longitude + delta),
      ],
    ];
  }

  void _confirmarUbicacion() {
    if (_selectedLPP == null) return;
    final jsonQuadrants = _drawnQuadrants.map((polygon) {
      return polygon.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList();
    }).toList();

    context.read<CrearFichaViewModel>().setUbicacion(
          _selectedLPP!.latitude,
          _selectedLPP!.longitude,
          jsonQuadrants,
        );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Indicar LPP', style: TextStyle(color: Colors.white)),
        actions: [
          if (_selectedLPP != null)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _confirmarUbicacion,
              tooltip: 'Confirmar Zona',
            )
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
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.equipo10.echoes',
              ),
              if (_drawnQuadrants.isNotEmpty)
                PolygonLayer(
                  polygons: List.generate(_drawnQuadrants.length, (i) {
                    final colores = [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                    ];
                    return Polygon(
                      points: _drawnQuadrants[i],
                      color: colores[i].withOpacity(0.18),
                      borderColor: colores[i].shade700,
                      borderStrokeWidth: 2.0,
                    );
                  }),
                ),
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
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF1B5E20)),
                      suffixIcon: _buscando
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1B5E20),
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
                            color: Color(0xFF1B5E20),
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
                      color: const Color(0xFF1B5E20).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'LPP y cuadrantes trazados. Toca ✓ para confirmar.',
                          style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
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
