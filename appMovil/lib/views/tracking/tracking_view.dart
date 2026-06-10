import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/reporte_model.dart';
import '../../models/evidencia_model.dart';
import '../../viewmodels/tracking_viewmodel.dart';
import '../../widgets/map_tile_layer.dart';
import '../../widgets/lpp_marker.dart';
import '../../widgets/evidencia_marker.dart';
import '../../theme/app_theme.dart';
import '../widgets/full_screen_image_view.dart';

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
  bool _useSatellite = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackingViewModel>().cargarEvidencias(widget.ficha.id);
      context.read<TrackingViewModel>().iniciarBusqueda(
            reporteId: widget.ficha.id,
            usuarioId: widget.usuarioId,
          );
    });
  }

  /// Intercepta el botón de regresar: ofrece pausar, terminar o volver.
  Future<bool> _onWillPop() async {
    final vm = context.read<TrackingViewModel>();

    // Si no hay búsqueda activa, dejar salir libremente
    if (vm.estado == TrackingEstado.inactivo ||
        vm.estado == TrackingEstado.terminado) {
      return true;
    }

    final accion = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Búsqueda en curso'),
        ]),
        content: const Text(
          '¿Qué deseas hacer con la búsqueda activa?\n\n'
          '• Pausar y salir: el GPS se detiene pero el recorrido se conserva.\n'
          '• Terminar: el recorrido se guarda y finaliza la sesión.\n'
          '• Volver al mapa: continuar la búsqueda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancelar'),
            child: const Text('Volver al mapa'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop('pausar'),
            child: const Text('Pausar y salir'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('terminar'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Terminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (accion == null || accion == 'cancelar') return false;

    if (accion == 'pausar') {
      await vm.pausarBusqueda();
      if (mounted) Navigator.of(context).pop();
      return false;
    }

    if (accion == 'terminar') {
      final ok = await vm.terminarBusqueda();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? '¡Recorrido guardado! Otros voluntarios ya pueden verlo.'
              : 'Recorrido terminado localmente (sin conexión).'),
          backgroundColor: ok ? AppTheme.success : Colors.orange,
        ));
        Navigator.of(context).pop(true);
      }
      return false;
    }

    return false;
  }

  Future<void> _onTerminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.flag, color: AppTheme.primary),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
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
      backgroundColor: ok ? AppTheme.success : Colors.orange,
    ));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrackingViewModel>();
    final pts = vm.puntosActuales;
    final polylinePoints = pts.map((p) => LatLng(p.lat, p.lng)).toList();
    final center = widget.ficha.latitud != null
        ? LatLng(widget.ficha.latitud!, widget.ficha.longitud!)
        : (pts.isNotEmpty ? LatLng(pts.last.lat, pts.last.lng) : const LatLng(0, 0));

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          foregroundColor: Colors.white,
          title: const Text('Búsqueda en Curso'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop && mounted) Navigator.of(context).pop();
            },
          ),
          actions: [
            // Botón Pausar / Reanudar — ancho fijo para evitar infinite width en AppBar
            if (vm.estado == TrackingEstado.activo)
              SizedBox(
                width: 108,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.pause_circle_outline, size: 18),
                    label: const Text('Pausar', style: TextStyle(fontSize: 13)),
                    onPressed: () => vm.pausarBusqueda(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              )
            else if (vm.estado == TrackingEstado.pausado)
              SizedBox(
                width: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: const Text('Reanudar', style: TextStyle(fontSize: 13)),
                    onPressed: () => vm.reanudarBusqueda(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            // ── Mapa con el recorrido dibujado ─────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16.0,
              ),
              children: [
                MapTileLayer(useSatellite: _useSatellite),

                // Cuadrantes de búsqueda (Base verde y expansiones azules)
                if (widget.ficha.expansionesData != null && widget.ficha.expansionesData!.isNotEmpty)
                  PolygonLayer(
                    polygons: widget.ficha.expansionesData!.where((e) => e['lat_min'] != null).map((e) {
                      final isBase = e['nivel'] == 1;
                      return Polygon(
                        points: [
                          LatLng(double.parse(e['lat_min'].toString()), double.parse(e['lng_min'].toString())),
                          LatLng(double.parse(e['lat_max'].toString()), double.parse(e['lng_min'].toString())),
                          LatLng(double.parse(e['lat_max'].toString()), double.parse(e['lng_max'].toString())),
                          LatLng(double.parse(e['lat_min'].toString()), double.parse(e['lng_max'].toString())),
                        ],
                        color: (isBase ? AppTheme.success : Colors.blue).withValues(alpha: 0.12),
                        borderColor: isBase ? AppTheme.success : Colors.blue.shade400,
                        borderStrokeWidth: 2,
                      );
                    }).toList(),
                  )
                else if (widget.ficha.cuadranteLatMin != null)
                  PolygonLayer(polygons: [
                    Polygon(
                      points: [
                        LatLng(widget.ficha.cuadranteLatMin!, widget.ficha.cuadranteLngMin!),
                        LatLng(widget.ficha.cuadranteLatMax!, widget.ficha.cuadranteLngMin!),
                        LatLng(widget.ficha.cuadranteLatMax!, widget.ficha.cuadranteLngMax!),
                        LatLng(widget.ficha.cuadranteLatMin!, widget.ficha.cuadranteLngMax!),
                      ],
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderColor: AppTheme.success,
                      borderStrokeWidth: 2,
                    )
                  ]),

                // Recorrido del usuario actual
                if (polylinePoints.length >= 2)
                  PolylineLayer(polylines: [
                    Polyline(
                      points: polylinePoints,
                      color: AppTheme.success,
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
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
                        ),
                        child: const Icon(Icons.navigation, color: Colors.white, size: 18),
                      ),
                    ),
                  ]),

                // Marcador LPP personalizado con foto y nombre
                MarkerLayer(markers: [
                  Marker(
                    point: center,
                    width: 110,
                    height: 90,
                    child: LppMarker(
                      fotoUrl: widget.ficha.fotoUrl,
                      nombre: widget.ficha.titulo,
                    ),
                  ),
                  if (vm.evidencias.isNotEmpty)
                    ...vm.evidencias.where((e) => e.estado == 'approved' && e.lat != null && e.lng != null).map((evidencia) {
                      return Marker(
                        point: LatLng(evidencia.lat!, evidencia.lng!),
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
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Evidencia'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (evidencia.fotoUrl != null && evidencia.fotoUrl!.isNotEmpty)
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => FullScreenImageView(
                                                      imageUrl: evidencia.fotoUrl!,
                                                      tag: 'track-ev-${evidencia.id}',
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Hero(
                                                tag: 'track-ev-${evidencia.id}',
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    evidencia.fotoUrl!,
                                                    height: 150,
                                                    width: 300,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 12),
                                          Text(evidencia.descripcion),
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
                              });
                            });
                          },
                          child: EvidenciaMarker(
                            fotoUrl: evidencia.fotoUrl,
                            nombreVoluntario: evidencia.nombreUsuario ?? 'Evidencia',
                          ),
                        ),
                      );
                    }),
                ]),
              ],
            ),

            // ── Toggle de capas (satelital / callejero) ─────────────────
            Positioned(
              bottom: 210,
              right: 80,
              child: MapLayerToggleButton(
                heroTag: null,
                useSatellite: _useSatellite,
                onToggle: () => setState(() => _useSatellite = !_useSatellite),
              ),
            ),

            // ── Botón de centrado en LPP ────────────────────────────────
            Positioned(
              bottom: 170,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'btn_centrar_tracking',
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                onPressed: () {
                  _mapController.move(center, 16.0);
                },
                child: const Icon(Icons.my_location),
              ),
            ),

            // ── Panel de estado en la parte inferior ────────────────────
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
                                ? AppTheme.success
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
                          backgroundColor: AppTheme.primary,
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
      ),
    );
  }
}
