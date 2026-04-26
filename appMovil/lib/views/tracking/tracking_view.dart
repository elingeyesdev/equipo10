import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/reporte_model.dart';
import '../../viewmodels/tracking_viewmodel.dart';
import '../../widgets/map_tile_layer.dart';

class TrackingView extends StatefulWidget {
  final ReporteModel ficha;
  final String usuarioId;

  const TrackingView({
    super.key,
    required this.ficha,
    required this.usuarioId,
  });

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackingViewModel>().iniciarBusqueda(
            reporteId: widget.ficha.id,
            usuarioId: widget.usuarioId,
          );
    });
  }

  Future<void> _onTerminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.flag, color: Color(0xFF1B5E20)),
          SizedBox(width: 8),
          Text('Terminar búsqueda'),
        ]),
        content: const Text(
          'Tu recorrido será guardado y visible para los demás voluntarios. ¿Deseas terminar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            child: const Text('Terminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;
    final vm = context.read<TrackingViewModel>();
    final ok = await vm.terminarBusqueda();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '¡Recorrido guardado! Otros voluntarios ya pueden verlo.'
          : 'Recorrido terminado localmente (sin conexión).'),
      backgroundColor: ok ? const Color(0xFF1B5E20) : Colors.orange,
    ));
    Navigator.of(context).pop(true); // regresa al detalle
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrackingViewModel>();
    final pts = vm.puntosActuales;
    final polylinePoints = pts.map((p) => LatLng(p.lat, p.lng)).toList();
    final center = widget.ficha.latitud != null
        ? LatLng(widget.ficha.latitud!, widget.ficha.longitud!)
        : (pts.isNotEmpty ? LatLng(pts.last.lat, pts.last.lng) : const LatLng(0, 0));

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Búsqueda en Curso'),
        actions: [
          // Pausa / Reanudar
          if (vm.estado == TrackingEstado.activo)
            IconButton(
              icon: const Icon(Icons.pause_circle_outline),
              tooltip: 'Pausar',
              onPressed: () => vm.pausarBusqueda(),
            )
          else if (vm.estado == TrackingEstado.pausado)
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: 'Reanudar',
              onPressed: () => vm.reanudarBusqueda(),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa con el recorrido dibujado
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16.0,
            ),
            children: [
              const MapTileLayer(),
              // Cuadrante del reporte (si tiene bounds)
              if (widget.ficha.cuadranteLatMin != null)
                PolygonLayer(polygons: [
                  Polygon(
                    points: [
                      LatLng(widget.ficha.cuadranteLatMin!, widget.ficha.cuadranteLngMin!),
                      LatLng(widget.ficha.cuadranteLatMax!, widget.ficha.cuadranteLngMin!),
                      LatLng(widget.ficha.cuadranteLatMax!, widget.ficha.cuadranteLngMax!),
                      LatLng(widget.ficha.cuadranteLatMin!, widget.ficha.cuadranteLngMax!),
                    ],
                    color: Colors.blue.withOpacity(0.12),
                    borderColor: Colors.blue.shade400,
                    borderStrokeWidth: 2,
                  )
                ]),
              // Recorrido del usuario actual
              if (polylinePoints.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(
                    points: polylinePoints,
                    color: const Color(0xFF4CAF50),
                    strokeWidth: 4,
                  )
                ]),
              // Marcador de posición actual
              if (pts.isNotEmpty)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(pts.last.lat, pts.last.lng),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
                      ),
                      child: const Icon(Icons.navigation, color: Colors.white, size: 18),
                    ),
                  ),
                ]),
              // Marcador LPP del reporte
              MarkerLayer(markers: [
                Marker(
                  point: center,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
                ),
              ]),
            ],
          ),

          // Botón de centrado dinámico en LPP
          Positioned(
            bottom: 170,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'btn_centrar_tracking',
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B5E20),
              onPressed: () {
                _mapController.move(center, 16.0);
              },
              child: const Icon(Icons.my_location),
            ),
          ),

          // Panel de estado en la parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black26)],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador de estado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: vm.estado == TrackingEstado.activo
                              ? const Color(0xFF4CAF50)
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vm.estado == TrackingEstado.activo
                            ? 'Grabando recorrido...'
                            : vm.estado == TrackingEstado.pausado
                                ? 'Búsqueda pausada'
                                : 'Iniciando...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${vm.totalPuntos} puntos GPS registrados',
                    style: const TextStyle(color: Color(0xFF5F6368), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // Botón terminar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: vm.isLoading ? null : _onTerminar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: vm.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.flag),
                      label: const Text('Terminar Búsqueda',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
