import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/reporte_model.dart';
import '../../models/evidencia_model.dart';
import '../../services/cuadrante_service.dart';
import '../../viewmodels/tracking_viewmodel.dart';
import '../../viewmodels/evidencia_viewmodel.dart';
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
  final CuadranteService _cuadranteService = CuadranteService();
  bool _useSatellite = true;
  bool _terminandoPorNotificacion = false;

  List<Polygon> _cuadrantesPolygons = [];

  @override
  void initState() {
    super.initState();

    // Registrar listener de botones de notificacion directamente en la View
    // para mayor confiabilidad (ademas del que registra el ViewModel)
    FlutterForegroundTask.addTaskDataCallback(_onNotificacionAction);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackingViewModel>().cargarEvidencias(widget.ficha.id);
      context.read<TrackingViewModel>().iniciarBusqueda(
            reporteId: widget.ficha.id,
            usuarioId: widget.usuarioId,
          );
    });
    _cargarCuadrantes();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onNotificacionAction);
    super.dispose();
  }

  /// Maneja los botones de la notificacion del Foreground Service.
  /// Se llama desde el main isolate cuando el usuario toca Pausar o Terminar.
  void _onNotificacionAction(Object data) {
    if (data is! String || !mounted) return;
    final vm = context.read<TrackingViewModel>();

    if (data == 'btn_pausar') {
      if (vm.estado == TrackingEstado.activo) {
        vm.pausarBusqueda();
      } else if (vm.estado == TrackingEstado.pausado) {
        vm.reanudarBusqueda();
      }
    } else if (data == 'btn_terminar') {
      // Desde la notificacion: terminar sin dialogo (no se puede mostrar UI desde background)
      if (_terminandoPorNotificacion ||
          vm.estado == TrackingEstado.terminado ||
          vm.isLoading) return;
      _terminandoPorNotificacion = true;
      vm.terminarBusqueda().then((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Recorrido finalizado.'),
          backgroundColor: AppTheme.success,
        ));
        Navigator.of(context).pop(true);
      });
    }
  }

  Future<void> _cargarCuadrantes() async {
    try {
      final cuadrantes = await _cuadranteService.getCuadrantes();
      if (!mounted) return;

      const double radioBase = 0.0007;
      final polygons = <Polygon>[];

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

  Future<bool> _onWillPop() async {
    final vm = context.read<TrackingViewModel>();
    if (vm.estado == TrackingEstado.activo ||
        vm.estado == TrackingEstado.pausado) {
      Navigator.of(context).pop();
      return false;
    }
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FLUJO PRINCIPAL: Terminar Recorrido
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _onTerminar() async {
    final nombreBuscado = widget.ficha.titulo ?? 'la persona';

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Por que finalizas tu recorrido?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Opcion B — principal (encontre)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop('encontre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.celebration_outlined, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      '¡Encontre a $nombreBuscado!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Opcion A — secundaria (me retiro)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop('retiro'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.home_outlined, size: 22),
                    SizedBox(height: 2),
                    Text(
                      'Termine mi recorrido / Me retiro a casa',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancelar',
                  style: TextStyle(color: Color(0xFF9CA3AF))),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;
    final vm = context.read<TrackingViewModel>();

    if (result == 'retiro') {
      // Opcion A: terminar + mensaje de agradecimiento
      final ok = await vm.terminarBusqueda();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Gracias por tu tiempo, cada paso ayuda.'
            : 'Recorrido terminado localmente (sin conexion).'),
        backgroundColor: ok ? AppTheme.success : Colors.orange,
        duration: const Duration(seconds: 4),
      ));
      Navigator.of(context).pop(true);
    } else if (result == 'encontre') {
      // Opcion B: terminar + subir evidencia + WhatsApp
      await vm.terminarBusqueda();
      if (!mounted) return;
      await _subirEvidenciaHallazgo();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FLUJO: Subir evidencia de hallazgo
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _subirEvidenciaHallazgo() async {
    final evVm = context.read<EvidenciaViewModel>();

    // Elegir fuente de la foto
    final fuente = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                '¡Posible hallazgo!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sube una foto para notificar al creador de la busqueda',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFECFDF5),
                  child: Icon(Icons.camera_alt, color: Color(0xFF059669)),
                ),
                title: const Text('Tomar foto ahora'),
                subtitle:
                    const Text('Abre la camara del dispositivo'),
                onTap: () => Navigator.of(ctx).pop('camara'),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFECFDF5),
                  child: Icon(Icons.photo_library, color: Color(0xFF059669)),
                ),
                title: const Text('Elegir de galeria'),
                subtitle:
                    const Text('Selecciona una foto existente'),
                onTap: () => Navigator.of(ctx).pop('galeria'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Omitir por ahora',
                    style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (fuente == null) {
      // Usuario omitio la foto — salir y mostrar contacto directamente
      await _mostrarContactoCreador(false);
      return;
    }

    // Spinner mientras captura
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    bool capturo = false;
    if (fuente == 'camara') {
      capturo = await evVm.capturarFoto();
    } else {
      capturo = await evVm.seleccionarDeGaleria();
    }

    if (mounted) Navigator.of(context).pop(); // Cerrar spinner

    if (!capturo || !mounted) {
      await _mostrarContactoCreador(false);
      return;
    }

    // Navegar a la pagina de descripcion / confirmacion
    final bytes =
        evVm.bytesPreview != null ? Uint8List.fromList(evVm.bytesPreview!) : null;
    final descripcion = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PublicarHallazgoPage(
          bytesPreview: bytes,
          tienePosicion: evVm.tienePosicion,
          latitud: evVm.latTemporal,
          longitud: evVm.lngTemporal,
          nombreBuscado: widget.ficha.titulo ?? 'la persona',
        ),
      ),
    );

    if (!mounted) return;

    if (descripcion == null || descripcion.isEmpty) {
      await _mostrarContactoCreador(false);
      return;
    }

    // Subir la evidencia
    final ok = await evVm.publicarEvidencia(
      reporteId: widget.ficha.id,
      usuarioId: widget.usuarioId,
      descripcion: descripcion,
    );

    if (!mounted) return;
    await _mostrarContactoCreador(ok);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FLUJO: Mostrar contacto del creador + boton de WhatsApp
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _mostrarContactoCreador(bool evidenciaEnviada) async {
    final telefono = widget.ficha.telefonoContacto;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF059669), size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                evidenciaEnviada ? '¡Evidencia enviada!' : '¡Hallazgo registrado!',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              evidenciaEnviada
                  ? 'Tu foto fue enviada al creador de la busqueda. Por la urgencia del caso, comunicarte de inmediato.'
                  : 'El hallazgo fue registrado. Si es urgente, comunicate con el creador ahora.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
            if (telefono != null && telefono.isNotEmpty) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _abrirWhatsApp(telefono),
                  icon: const Icon(Icons.chat_bubble_outline, size: 22),
                  label: const Text(
                    'Abrir chat con el dueno',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar',
                    style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
            ),
          ],
        ),
      ),
    );

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _abrirWhatsApp(String telefono) async {
    final tel = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$tel');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────

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
          title: const Text('Busqueda en Curso'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onWillPop(),
          ),
          actions: [
            if (vm.estado == TrackingEstado.activo)
              SizedBox(
                width: 108,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.pause_circle_outline, size: 18),
                    label:
                        const Text('Pausar', style: TextStyle(fontSize: 13)),
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
                    label: const Text('Reanudar',
                        style: TextStyle(fontSize: 13)),
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
            // ── Mapa ─────────────────────────────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16.0,
              ),
              children: [
                MapTileLayer(useSatellite: _useSatellite),

                if (_cuadrantesPolygons.isNotEmpty)
                  PolygonLayer(polygons: _cuadrantesPolygons),

                if (polylinePoints.length >= 2)
                  PolylineLayer(polylines: [
                    Polyline(
                      points: polylinePoints,
                      color: AppTheme.success,
                      strokeWidth: 4,
                    )
                  ]),

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

                MarkerLayer(markers: [
                  // Marcador LPP
                  Marker(
                    point: center,
                    width: 110,
                    height: 90,
                    child: LppMarker(
                      fotoUrl: widget.ficha.fotoUrl,
                      nombre: widget.ficha.titulo,
                    ),
                  ),
                  // Marcadores de evidencias aprobadas
                  if (vm.evidencias.isNotEmpty)
                    ...vm.evidencias
                        .where((e) =>
                            e.estado == 'approved' &&
                            e.lat != null &&
                            e.lng != null)
                        .map((evidencia) {
                      return Marker(
                        point: LatLng(evidencia.lat!, evidencia.lng!),
                        // height aumentado a 92 para evitar bottom overflow
                        // (circulo 58 + triangulo 8 + etiqueta ~18 + margen 8 = 92)
                        width: 80,
                        height: 92,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
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
                                                  imageUrl: evidencia.fotoUrl!,
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
                                                imageUrl: evidencia.fotoUrl!,
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

            // ── Toggle satelital / callejero ─────────────────────────────
            Positioned(
              bottom: 210,
              right: 80,
              child: MapLayerToggleButton(
                heroTag: null,
                useSatellite: _useSatellite,
                onToggle: () =>
                    setState(() => _useSatellite = !_useSatellite),
              ),
            ),

            // ── Centrar en LPP ───────────────────────────────────────────
            Positioned(
              bottom: 170,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'btn_centrar_tracking',
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                onPressed: () => _mapController.move(center, 16.0),
                child: const Icon(Icons.my_location),
              ),
            ),

            // ── Panel de estado ──────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(blurRadius: 12, color: Colors.black26)
                  ],
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
                                  ? 'Busqueda pausada'
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
                    // Boton principal — "Terminar Recorrido"
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
                        label: const Text(
                          'Terminar Recorrido',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Pagina de publicacion de evidencia para hallazgo
// ─────────────────────────────────────────────────────────────────────────────

class _PublicarHallazgoPage extends StatefulWidget {
  final Uint8List? bytesPreview;
  final bool tienePosicion;
  final double? latitud;
  final double? longitud;
  final String nombreBuscado;

  const _PublicarHallazgoPage({
    required this.bytesPreview,
    required this.tienePosicion,
    required this.latitud,
    required this.longitud,
    required this.nombreBuscado,
  });

  @override
  State<_PublicarHallazgoPage> createState() => _PublicarHallazgoPageState();
}

class _PublicarHallazgoPageState extends State<_PublicarHallazgoPage> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '¡Posible hallazgo! ');
    // Mover el cursor al final del texto prefijo
    _ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _ctrl.text.length),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    final text = _ctrl.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La descripcion debe tener al menos 5 caracteres')),
      );
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: const Text('¡Posible hallazgo!'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de urgencia
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Subir foto de ${widget.nombreBuscado} — el creador recibira una notificacion inmediata.',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preview de la foto
            if (widget.bytesPreview != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  widget.bytesPreview!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // GPS info
            Row(
              children: [
                Icon(
                  widget.tienePosicion
                      ? Icons.location_on
                      : Icons.location_off,
                  size: 14,
                  color: widget.tienePosicion
                      ? AppTheme.success
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.tienePosicion
                        ? 'GPS: ${widget.latitud!.toStringAsFixed(5)}, ${widget.longitud!.toStringAsFixed(5)}'
                        : 'Sin ubicacion GPS',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.tienePosicion
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo de descripcion
            TextField(
              controller: _ctrl,
              maxLines: 4,
              maxLength: 400,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripcion del hallazgo *',
                hintText: 'Describe donde y como encontraste a la persona...',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),

            // Boton confirmar
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _confirmar,
                icon: const Icon(Icons.send_outlined),
                label: const Text(
                  'Enviar evidencia al creador',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
