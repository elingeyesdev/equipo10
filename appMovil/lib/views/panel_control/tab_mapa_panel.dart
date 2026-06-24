import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../viewmodels/panel_control_viewmodel.dart';
import '../../viewmodels/evidencia_viewmodel.dart';
import '../../widgets/map_tile_layer.dart';
import '../../widgets/lpp_marker.dart';
import '../../services/cuadrante_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/full_screen_image_view.dart';

class TabMapaPanel extends StatefulWidget {
  final void Function(String usuarioId, String nombre, String? estado)
      onMensajeDirecto;

  const TabMapaPanel({super.key, required this.onMensajeDirecto});

  @override
  State<TabMapaPanel> createState() => _TabMapaPanelState();
}

class _TabMapaPanelState extends State<TabMapaPanel> {
  final MapController _mapController = MapController();
  final CuadranteService _cuadranteService = CuadranteService();
  bool _useSatellite = true;
  bool _dialogAbierto = false;
  bool _mostrarRecorridos = true;
  bool _mostrarEvidencias = true;
  List<Polygon> _cuadrantesPolygons = [];

  @override
  void initState() {
    super.initState();
    _cargarCuadrantes();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _cargarCuadrantes() async {
    try {
      final cuadrantes = await _cuadranteService.getCuadrantes();
      if (!mounted) return;
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
        if (pts == null && c.latMin != null) {
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
            borderColor: Colors.blue.withOpacity(0.4),
            borderStrokeWidth: 1.5,
          ));
        }
      }
      if (mounted) setState(() => _cuadrantesPolygons = polygons);
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

  void _mostrarFiltroRecorridos(
      BuildContext context, PanelControlViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text(
                'Filtrar recorridos',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.primary),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.people_alt,
                          color: AppTheme.primary, size: 20),
                      title: const Text('Todos',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      selected: vm.filtroNombreVoluntario == null,
                      selectedColor: AppTheme.primary,
                      onTap: () {
                        vm.setFiltroVoluntario(null);
                        Navigator.pop(ctx);
                      },
                    ),
                    const Divider(height: 1),
                    ...vm.todasLasRutas.asMap().entries.map((e) {
                      final ruta = e.value;
                      final isSelected =
                          vm.filtroNombreVoluntario == ruta.nombre;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: [
                              Colors.blue,
                              Colors.red,
                              Colors.green,
                              Colors.orange,
                              Colors.purple,
                              Colors.teal,
                            ][e.key % 6],
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(ruta.nombre,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppTheme.primary : null)),
                        trailing: isSelected
                            ? const Icon(Icons.check,
                                color: AppTheme.primary, size: 20)
                            : null,
                        onTap: () {
                          vm.setFiltroVoluntario(ruta.nombre);
                          if (ruta.puntos.isNotEmpty) {
                            _mapController.move(ruta.puntos.last, 16.0);
                          }
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PanelControlViewModel>();
    final evVm = context.watch<EvidenciaViewModel>();
    final ficha = vm.ficha;

    if (ficha == null) return const SizedBox.shrink();

    // Calcular el centro (Prioridad: LPP > Cuadrante > Recorridos)
    LatLng? center;
    if (ficha.latitud != null && ficha.longitud != null) {
      center = LatLng(ficha.latitud!, ficha.longitud!);
    } else if (ficha.cuadranteLatMin != null &&
        ficha.cuadranteLatMax != null &&
        ficha.cuadranteLngMin != null &&
        ficha.cuadranteLngMax != null) {
      center = LatLng(
        (ficha.cuadranteLatMin! + ficha.cuadranteLatMax!) / 2,
        (ficha.cuadranteLngMin! + ficha.cuadranteLngMax!) / 2,
      );
    } else if (vm.recorridosMap.isNotEmpty) {
      center = vm.recorridosMap.first.first;
    }

    if (center == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No hay datos de ubicación.',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Asegúrese de que el reporte tenga una ubicación inicial o cuadrante asignado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final List<Color> pathColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    final List<Marker> markersPistas = [];
    final List<Marker> markersEvidencias = [];

    // Punto original (LPP)
    if (ficha.latitud != null && ficha.longitud != null) {
      markersPistas.add(Marker(
        point: LatLng(ficha.latitud!, ficha.longitud!),
        width: 80,
        height: 70,
        alignment: Alignment.center,
        child: LppMarker(
          fotoUrl: ficha.fotoUrl,
          nombre: 'Visto por última vez',
          color: const Color(0xFFD32F2F),
        ),
      ));
    }

    // Evidencias aprobadas con coordenadas (capa separada — siempre encima)
    final evidenciasAprobadas =
        evVm.evidencias.where((e) => e.estado == 'approved').toList();
    markersEvidencias.addAll(evidenciasAprobadas
        .where((e) => e.lat != null && e.lng != null)
        .map((evidencia) {
      return Marker(
        point: LatLng(evidencia.lat!, evidencia.lng!),
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_dialogAbierto) return;
            _dialogAbierto = true;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text(
                    'Evidencia',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (evidencia.fotoUrl != null &&
                            evidencia.fotoUrl!.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageView(
                                    imageUrl: evidencia.fotoUrl!,
                                    tag: 'panel-ev-${evidencia.id}',
                                  ),
                                ),
                              );
                            },
                            child: Hero(
                              tag: 'panel-ev-${evidencia.id}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: evidencia.fotoUrl!,
                                  height: 200,
                                  width: MediaQuery.of(ctx).size.width,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      size: 50),
                                  placeholder: (_, __) => Container(
                                    height: 200,
                                    color: const Color(0xFFF5F5F5),
                                    child: const Center(
                                        child: CircularProgressIndicator()),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (evidencia.nombreUsuario != null) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.person,
                                size: 16, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(evidencia.nombreUsuario!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ]),
                        ],
                        if (evidencia.descripcion.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Text(
                            evidencia.descripcion,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                                fontSize: 13, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actionsPadding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ).then((_) {
                _dialogAbierto = false;
              });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                      color: const Color(0xFF8B5CF6), width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2))
                  ],
                ),
                child: ClipOval(
                  child: evidencia.fotoUrl != null &&
                          evidencia.fotoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: evidencia.fotoUrl!,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (_, __) => const ColoredBox(
                              color: Color(0xFFF5F3FF)),
                          errorWidget: (_, __, ___) => const ColoredBox(
                              color: Color(0xFFF5F3FF)),
                        )
                      : const ColoredBox(color: Color(0xFFF5F3FF)),
                ),
              ),
              Positioned(
                top: 1,
                right: 1,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 3,
                          offset: Offset(0, 1)),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
        ),
      );
    }));

    // Pistas adicionales — se agregan a markersEvidencias para que el toggle las oculte junto con las evidencias
    markersEvidencias.addAll(vm.pistas.map((pista) {
      return Marker(
        point: pista.punto,
        width: 28,
        height: 28,
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 14),
        ),
      );
    }));

    final capturedCenter = center;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15.0,
          ),
          children: [
            MapTileLayer(useSatellite: _useSatellite),
            if (_cuadrantesPolygons.isNotEmpty)
              PolygonLayer(polygons: _cuadrantesPolygons),
            // Halo verde del LPP — siempre visible
            if (ficha.latitud != null && ficha.longitud != null)
              PolygonLayer(polygons: () {
                const double radioBase = 0.0007;
                final nivel =
                    _calcularNivel(ficha.createdAt?.toIso8601String());
                final r = radioBase * nivel;
                final lat = ficha.latitud!;
                final lng = ficha.longitud!;
                return [
                  Polygon(
                    points: [
                      LatLng(lat - r, lng - r),
                      LatLng(lat - r, lng + r),
                      LatLng(lat + r, lng + r),
                      LatLng(lat + r, lng - r),
                    ],
                    color: const Color(0xFF10B981).withOpacity(0.22),
                    borderColor: const Color(0xFF059669),
                    borderStrokeWidth: 2.5,
                  ),
                ];
              }()),
            // Halos verdes de pistas — se ocultan con el toggle de evidencias
            if (_mostrarEvidencias && vm.pistas.isNotEmpty)
              PolygonLayer(polygons: vm.pistas.map((p) {
                const double radioBase = 0.0007;
                final rp = radioBase *
                    _calcularNivel(p.createdAt?.toIso8601String());
                return Polygon(
                  points: [
                    LatLng(p.punto.latitude - rp, p.punto.longitude - rp),
                    LatLng(p.punto.latitude - rp, p.punto.longitude + rp),
                    LatLng(p.punto.latitude + rp, p.punto.longitude + rp),
                    LatLng(p.punto.latitude + rp, p.punto.longitude - rp),
                  ],
                  color: const Color(0xFF10B981).withOpacity(0.18),
                  borderColor: const Color(0xFF059669),
                  borderStrokeWidth: 1.5,
                );
              }).toList()),
            if (_mostrarRecorridos)
              PolylineLayer(
                polylines: List.generate(vm.rutasVoluntarios.length, (index) {
                  final ruta = vm.rutasVoluntarios[index];
                  final originalIndex = vm.todasLasRutas.indexOf(ruta);
                  return Polyline(
                    points: ruta.puntos,
                    color: pathColors[originalIndex % pathColors.length]
                        .withOpacity(0.7),
                    strokeWidth: 4.0,
                  );
                }),
              ),
            if (_mostrarRecorridos)
              MarkerLayer(
              markers: List.generate(vm.rutasVoluntarios.length, (index) {
                final ruta = vm.rutasVoluntarios[index];
                if (ruta.puntos.isEmpty) return null;
                final lastPoint = ruta.puntos.last;
                final originalIndex = vm.todasLasRutas.indexOf(ruta);
                final markerColor =
                    pathColors[originalIndex % pathColors.length];

                return Marker(
                  point: lastPoint,
                  width: 100,
                  height: 60,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (ruta.usuarioId != null) {
                        widget.onMensajeDirecto(
                            ruta.usuarioId!, ruta.nombre, ruta.estadoBusqueda);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'No se puede enviar mensaje a este voluntario.')),
                        );
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: ruta.estadoBusqueda == 'buscando'
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                  offset: Offset(0, 1))
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (ruta.estadoBusqueda == 'buscando')
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  ruta.nombre,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: markerColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.person_pin_circle,
                          color: markerColor,
                          size: 32,
                          shadows: const [
                            Shadow(color: Colors.white, blurRadius: 2)
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).whereType<Marker>().toList(),
            ),
            MarkerLayer(markers: markersPistas),
            if (_mostrarEvidencias) MarkerLayer(markers: markersEvidencias),
          ],
        ),
        // Filtrar recorridos — esquina superior izquierda
        if (vm.todasLasRutas.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            child: ElevatedButton(
              onPressed: () => _mostrarFiltroRecorridos(context, vm),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.pressed)
                        ? AppTheme.primary
                        : Colors.white),
                foregroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.pressed)
                        ? Colors.white
                        : AppTheme.primary),
                elevation: WidgetStateProperty.all(4),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50))),
                padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0)),
                minimumSize: WidgetStateProperty.all(const Size(0, 40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_list, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    vm.filtroNombreVoluntario ?? 'Filtrar recorridos',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        // Filtros de capa — esquina superior derecha
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _LayerToggleChip(
                label: 'Recorridos',
                icon: Icons.route,
                active: _mostrarRecorridos,
                onTap: () => setState(() => _mostrarRecorridos = !_mostrarRecorridos),
              ),
              const SizedBox(height: 8),
              _LayerToggleChip(
                label: 'Evidencias',
                icon: Icons.camera_alt,
                active: _mostrarEvidencias,
                onTap: () => setState(() => _mostrarEvidencias = !_mostrarEvidencias),
              ),
            ],
          ),
        ),

        // Toggle satélite/callejero — esquina inferior izquierda
        Positioned(
          bottom: 16,
          left: 16,
          child: ElevatedButton(
            onPressed: () => setState(() => _useSatellite = !_useSatellite),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.pressed)
                      ? AppTheme.primary
                      : Colors.white),
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.pressed)
                      ? Colors.white
                      : AppTheme.primary),
              elevation: WidgetStateProperty.all(4),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50))),
              padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
              minimumSize: WidgetStateProperty.all(const Size(0, 52)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _useSatellite ? Icons.map_outlined : Icons.satellite_outlined,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  _useSatellite ? 'Callejero' : 'Satélite',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),

        // Botón ir a ubicación — esquina inferior derecha
        Positioned(
          bottom: 16,
          right: 16,
          child: ElevatedButton(
            onPressed: () => _mapController.move(capturedCenter, 15.0),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.pressed)
                      ? AppTheme.primary
                      : Colors.white),
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.pressed)
                      ? Colors.white
                      : AppTheme.primary),
              elevation: WidgetStateProperty.all(4),
              shape: WidgetStateProperty.all(const CircleBorder()),
              padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16)),
              minimumSize: WidgetStateProperty.all(const Size(0, 52)),
            ),
            child: const Icon(Icons.my_location, size: 22),
          ),
        ),
      ],
    );
  }
}

class _LayerToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _LayerToggleChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
