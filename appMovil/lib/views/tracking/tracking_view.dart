import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/reporte_model.dart';
import '../../models/evidencia_model.dart';
import '../../models/cuadrante_model.dart';
import '../../services/cuadrante_service.dart';
import '../../viewmodels/tracking_viewmodel.dart';
import '../../widgets/map_tile_layer.dart';
import '../../widgets/lpp_marker.dart';
import '../../widgets/evidencia_marker.dart';
import '../../theme/app_theme.dart';
import '../widgets/full_screen_image_view.dart';
import '../widgets/encuesta_dialog.dart';

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
  final CuadranteService _cuadranteService = CuadranteService();
  bool _useSatellite = true;

  List<Polygon> _cuadrantesPolygons = [];

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
    _cargarCuadrantes();
  }

  /// Carga todos los cuadrantes del sistema para mostrar la cuadrícula base
  /// y el área de expansión dinámica del LPP.
  Future<void> _cargarCuadrantes() async {
    try {
      final cuadrantes = await _cuadranteService.getCuadrantes();
      if (!mounted) return;

      const double radioBase = 0.0007;
      final polygons = <Polygon>[];

      // 1. Cuadrícula base — líneas azules
      for (final c in cuadrantes) {
        List<LatLng>? pts;
        if (c.geometria != null) {
          try {
            final geo = c.geometria!['type'] == 'Feature'
                ? c.geometria!['geometry']
                : c.geometria;
            if (geo['type'] == 'Polygon') {
              final coords = geo['coordinates'][0] as List;
              pts = coords
                  .map((coord) => LatLng(double.parse(coord[1].toString()),
                      double.parse(coord[0].toString())))
                  .toList();
            }
          } catch (_) {}
        }
        if (pts == null &&
            c.latMin != null &&
            c.latMax != null &&
            c.lngMin != null &&
            c.lngMax != null) {
          pts = [
            LatLng(c.latMax!, c.lngMin!),
            LatLng(c.latMax!, c.lngMax!),
            LatLng(c.latMin!, c.lngMax!),
            LatLng(c.latMin!, c.lngMin!),
          ];
        }
        if (pts != null) {
          polygons.add(Polygon(
            points: pts,
            color: Colors.transparent,
            borderColor: Colors.blue.withOpacity(0.45),
            borderStrokeWidth: 1.5,
          ));
        }
      }

      // 2. Zona de expansión verde del LPP — nivel calculado dinámicamente
      if (widget.ficha.latitud != null && widget.ficha.longitud != null) {
        final nivel = _calcularNivel(widget.ficha.createdAt?.toIso8601String());
        final r = radioBase * nivel;
        final lat = widget.ficha.latitud!;
        final lng = widget.ficha.longitud!;
        polygons.add(Polygon(
          points: [
            LatLng(lat - r, lng - r),
            LatLng(lat - r, lng + r),
            LatLng(lat + r, lng + r),
            LatLng(lat + r, lng - r),
          ],
          color: const Color(0xFF10B981).withOpacity(0.20),
          borderColor: const Color(0xFF059669),
          borderStrokeWidth: 2.5,
        ));
      }

      setState(() => _cuadrantesPolygons = polygons);
    } catch (_) {}
  }

  int _calcularNivel(String? fechaStr) {
    if (fechaStr == null || fechaStr.isEmpty) return 1;
    final fecha = DateTime.tryParse(fechaStr.replaceAll(' ', 'T'));
    if (fecha == null) return 1;
    final diffMin = DateTime.now().difference(fecha).inMinutes;
    if (diffMin >= 5760) return 10;
    if (diffMin >= 4320) return 9;
    if (diffMin >= 2880) return 8;
    if (diffMin >= 1440) return 7;
    if (diffMin >= 720) return 6;
    if (diffMin >= 360) return 5;
    if (diffMin >= 180) return 4;
    if (diffMin >= 60) return 3;
    if (diffMin >= 30) return 2;
    return 1;
  }

  /// Al presionar la flecha de regreso:
  /// - Si hay búsqueda activa/pausada → sale sin detener el GPS.
  ///   El Foreground Service sigue corriendo con la notificación (Pausar / Terminar).
  /// - Si no hay búsqueda activa → sale normalmente.
  Future<bool> _onWillPop() async {
    final vm = context.read<TrackingViewModel>();
    if (vm.estado == TrackingEstado.activo ||
        vm.estado == TrackingEstado.pausado) {
      // Salir sin interrumpir el tracking; el usuario puede volver desde notificación
      Navigator.of(context).pop();
      return false;
    }
    return true;
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
            child:
                const Text('Terminar', style: TextStyle(color: Colors.white)),
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
    // Mostrar encuesta de satisfacción antes de salir
    if (mounted)
      await EncuestaDialog.show(context, widget.ficha, widget.usuarioId);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrackingViewModel>();
    final pts = vm.puntosActuales;
    final polylinePoints = pts.map((p) => LatLng(p.lat, p.lng)).toList();
    final center = widget.ficha.latitud != null
        ? LatLng(widget.ficha.latitud!, widget.ficha.longitud!)
        : (pts.isNotEmpty
            ? LatLng(pts.last.lat, pts.last.lng)
            : const LatLng(0, 0));

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
            onPressed: () => _onWillPop(),
          ),
          actions: [
            // Botón Pausar / Reanudar — ancho fijo para evitar infinite width en AppBar
            if (vm.estado == TrackingEstado.activo)
              SizedBox(
                width: 108,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.pause_circle_outline, size: 18),
                    label: const Text('Pausar', style: TextStyle(fontSize: 13)),
                    onPressed: () => vm.pausarBusqueda(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              )
            else if (vm.estado == TrackingEstado.pausado)
              SizedBox(
                width: 120,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label:
                        const Text('Reanudar', style: TextStyle(fontSize: 13)),
                    onPressed: () async => vm.reanudarBusqueda(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
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

                // Cuadrícula de cuadrantes + zona de expansión verde del LPP
                if (_cuadrantesPolygons.isNotEmpty)
                  PolygonLayer(polygons: _cuadrantesPolygons),

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
                          boxShadow: const [
                            BoxShadow(blurRadius: 6, color: Colors.black38)
                          ],
                        ),
                        child: const Icon(Icons.navigation,
                            color: Colors.white, size: 18),
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
                    ...vm.evidencias
                        .where((e) =>
                            e.estado == 'approved' &&
                            e.lat != null &&
                            e.lng != null)
                        .map((evidencia) {
                      return Marker(
                        point: LatLng(evidencia.lat!, evidencia.lng!),
                        width: 80,
                        height: 70,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Future.delayed(const Duration(milliseconds: 150),
                                () {
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
                                          if (evidencia.fotoUrl != null &&
                                              evidencia.fotoUrl!.isNotEmpty)
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        FullScreenImageView(
                                                      imageUrl:
                                                          evidencia.fotoUrl!,
                                                      tag:
                                                          'track-ev-${evidencia.id}',
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Hero(
                                                tag: 'track-ev-${evidencia.id}',
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        evidencia.fotoUrl!,
                                                    height: 150,
                                                    width: 300,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (_, __, ___) =>
                                                        const Icon(
                                                            Icons.broken_image,
                                                            size: 50),
                                                    placeholder: (_, __) =>
                                                        Container(
                                                      height: 150,
                                                      width: 300,
                                                      color: const Color(
                                                          0xFFF5F5F5),
                                                      child: const Center(
                                                          child:
                                                              CircularProgressIndicator()),
                                                    ),
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
                            nombreVoluntario:
                                evidencia.nombreUsuario ?? 'Evidencia',
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
                      style: const TextStyle(
                          color: Color(0xFF5F6368), fontSize: 13),
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
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
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
