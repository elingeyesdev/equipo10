import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/reporte_model.dart';
import '../../services/api_service.dart';

// Paleta de colores para los recorridos de distintos voluntarios
const List<Color> _coloresVoluntarios = [
  Color(0xFF2196F3), // azul
  Color(0xFFFF9800), // naranja
  Color(0xFF9C27B0), // morado
  Color(0xFFE91E63), // rosa
  Color(0xFF00BCD4), // cyan
  Color(0xFF795548), // marrón
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

class _MapaOperativoViewState extends State<MapaOperativoView> {
  final MapController _mapController = MapController();
  final ApiService _api = ApiService();

  List<List<LatLng>> _cuadrantesFormateados = [];
  LatLng? _lpp;
  List<_VoluntarioRecorrido> _recorridos = [];
  bool _cargandoRecorridos = true;

  @override
  void initState() {
    super.initState();
    _parseData();
    _cargarRecorridos();
  }

  void _parseData() {
    if (widget.ficha.latitud != null && widget.ficha.longitud != null) {
      _lpp = LatLng(widget.ficha.latitud!, widget.ficha.longitud!);
    }

    if (widget.ficha.cuadrantes != null) {
      for (var currQuadrant in widget.ficha.cuadrantes!) {
        List<LatLng> polygon = [];
        for (var point in (currQuadrant as List)) {
          polygon.add(LatLng(
              (point['lat'] as num).toDouble(), (point['lng'] as num).toDouble()));
        }
        _cuadrantesFormateados.add(polygon);
      }
    }

    // Si no hay cuadrantes desde la ficha pero sí tenemos bounds del API, los usamos
    if (_cuadrantesFormateados.isEmpty && widget.ficha.cuadranteLatMin != null) {
      _cuadrantesFormateados.add([
        LatLng(widget.ficha.cuadranteLatMin!, widget.ficha.cuadranteLngMin!),
        LatLng(widget.ficha.cuadranteLatMax!, widget.ficha.cuadranteLngMin!),
        LatLng(widget.ficha.cuadranteLatMax!, widget.ficha.cuadranteLngMax!),
        LatLng(widget.ficha.cuadranteLatMin!, widget.ficha.cuadranteLngMax!),
      ]);
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
      // Sin conexión: no hay recorridos que mostrar
    } finally {
      setState(() => _cargandoRecorridos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lpp == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mapa Operativo')),
        body: const Center(child: Text('La ficha no tiene un punto LPP establecido.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Sectorizado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar recorridos',
            onPressed: () {
              setState(() => _cargandoRecorridos = true);
              _cargarRecorridos();
            },
          ),
          if (widget.esCreador)
            IconButton(
              icon: const Icon(Icons.edit_location_alt_outlined),
              tooltip: 'Editar Cuadrantes (Próximamente)',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'La edición libre de cuadrantes estará disponible en una próxima actualización.'),
                ));
              },
            )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _lpp!,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.equipo10.echoes',
              ),
              // Cuadrante(s) del operativo
              if (_cuadrantesFormateados.isNotEmpty)
                PolygonLayer(
                  polygons: _cuadrantesFormateados
                      .map((q) => Polygon(
                            points: q,
                            color: Colors.redAccent.withOpacity(0.15),
                            borderColor: Colors.red.shade900,
                            borderStrokeWidth: 2,
                          ))
                      .toList(),
                ),
              // Recorridos de cada voluntario
              if (_recorridos.isNotEmpty)
                PolylineLayer(
                  polylines: _recorridos
                      .where((r) => r.puntos.length >= 2)
                      .map((r) => Polyline(
                            points: r.puntos,
                            color: r.color.withOpacity(r.terminado ? 0.85 : 0.5),
                            strokeWidth: r.terminado ? 4 : 3,
                            pattern: r.terminado
                                ? const StrokePattern.solid()
                                : const StrokePattern.dotted(),
                          ))
                      .toList(),
                ),
              // Marcador LPP
              MarkerLayer(
                markers: [
                  Marker(
                    point: _lpp!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.person_pin_circle,
                        color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // Leyenda de voluntarios
          if (_recorridos.isNotEmpty)
            Positioned(
              top: 12,
              right: 12,
              child: _LeyendaRecorridos(recorridos: _recorridos),
            ),

          // Panel inferior
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
                        SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Cargando recorridos...'),
                      ],
                    )
                  : Text(
                      _recorridos.isEmpty
                          ? 'Aún no hay recorridos registrados en este operativo.'
                          : '${_recorridos.length} recorrido(s) de voluntarios registrado(s).',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                      ),
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
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          ...recorridos.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 14,
                        height: 4,
                        decoration: BoxDecoration(
                            color: r.color,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text(r.nombre,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A1A))),
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
