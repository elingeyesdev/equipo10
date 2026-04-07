import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/ficha_model.dart';
import '../../services/ficha_service.dart';

class MapaOperativoView extends StatefulWidget {
  final FichaModel ficha;
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
  List<List<LatLng>> _cuadrantesFormateados = [];
  LatLng? _lpp;

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    if (widget.ficha.latitud != null && widget.ficha.longitud != null) {
      _lpp = LatLng(widget.ficha.latitud!, widget.ficha.longitud!);
    }
    
    if (widget.ficha.cuadrantes != null) {
      for (var currQuadrant in widget.ficha.cuadrantes!) {
        List<LatLng> polygon = [];
        for (var point in (currQuadrant as List)) {
          polygon.add(LatLng((point['lat'] as num).toDouble(), (point['lng'] as num).toDouble()));
        }
        _cuadrantesFormateados.add(polygon);
      }
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
          if (widget.esCreador)
            IconButton(
              icon: const Icon(Icons.edit_location_alt_outlined),
              tooltip: 'Editar Cuadrantes (Próximamente)',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La edición libre de cuadrantes estará disponible en una próxima actualización.')),
                );
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
              if (_cuadrantesFormateados.isNotEmpty)
                PolygonLayer(
                  polygons: _cuadrantesFormateados.map((q) => Polygon(
                        points: q,
                        color: Colors.redAccent.withOpacity(0.2),
                        borderColor: Colors.red.shade900,
                        borderStrokeWidth: 2,
                      )).toList(),
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _lpp!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
              ),
              child: const Text(
                'Los cuadrantes delimitan las zonas de búsqueda prioritarias de los voluntarios.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
