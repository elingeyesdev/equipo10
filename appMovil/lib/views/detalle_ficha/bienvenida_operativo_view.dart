import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/reporte_model.dart';
import '../../services/vinculacion_service.dart';
import '../../models/perfil_model.dart';
import '../../viewmodels/tracking_viewmodel.dart';
import '../../widgets/map_tile_layer.dart';
import '../../theme/app_theme.dart';
import '../tracking/tracking_view.dart';
import 'geofencing_bloqueado_sheet.dart';

/// Pantalla de bienvenida que se muestra inmediatamente después de que el
/// voluntario se une exitosamente a un operativo. Provee contexto completo:
/// mapa del cuadrante asignado, equipo activo e instrucciones de acción.
class BienvenidaOperativoView extends StatefulWidget {
  final ReporteModel ficha;
  final String usuarioId;

  const BienvenidaOperativoView({
    super.key,
    required this.ficha,
    required this.usuarioId,
  });

  @override
  State<BienvenidaOperativoView> createState() =>
      _BienvenidaOperativoViewState();
}

class _BienvenidaOperativoViewState extends State<BienvenidaOperativoView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  List<PerfilModel> _voluntarios = [];
  bool _cargandoVoluntarios = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    _cargarVoluntarios();
  }

  Future<void> _cargarVoluntarios() async {
    try {
      final lista = await VinculacionService().obtenerVoluntarios(widget.ficha.id);
      if (mounted) setState(() => _voluntarios = lista);
    } catch (_) {
      // No bloqueamos la pantalla si falla la carga de voluntarios
    } finally {
      if (mounted) setState(() => _cargandoVoluntarios = false);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarBusqueda() async {
    final ficha = widget.ficha;

    if (ficha.cuadranteLatMin == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'El coordinador asignará tu cuadrante pronto. Vuelve en unos minutos.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final trackingVm = TrackingViewModel();
    final pos = await trackingVm.verificarGeofencing(
      latMin: ficha.cuadranteLatMin!,
      latMax: ficha.cuadranteLatMax!,
      lngMin: ficha.cuadranteLngMin!,
      lngMax: ficha.cuadranteLngMax!,
    );

    if (!mounted) return;

    if (pos == null) {
      // Usar la posición en caché (instantánea) para mostrarla en el mapa del sheet
      Position? posActual;
      try {
        posActual = await Geolocator.getLastKnownPosition();
      } catch (_) {
        // Sin posición en caché, el sheet se muestra sin el punto azul
      }

      if (!mounted) return;

      await GeofencingBloqueadoSheet.show(
        context,
        ficha: ficha,
        posicionActual: posActual,
      );
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => TrackingViewModel(),
          child: TrackingView(
            ficha: ficha,
            usuarioId: widget.usuarioId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tieneCuadrante = widget.ficha.cuadranteLatMin != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero de confirmación ─────────────────────────────────────
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.success.withOpacity(0.4), width: 3),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.success,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Título de bienvenida ─────────────────────────────────────
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      const Text(
                        '¡Ya eres parte del equipo!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.ficha.titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Sección: Tu zona ─────────────────────────────────────────
              _SectionHeader(
                icon: Icons.map_outlined,
                title: 'Área del operativo',
              ),
              const SizedBox(height: 12),
              if (tieneCuadrante)
                _MapaCuadrante(ficha: widget.ficha)
              else
                _CuadrantePendiente(),
              const SizedBox(height: 28),

              // ── Sección: Equipo activo ───────────────────────────────────
              _SectionHeader(
                icon: Icons.people_outline,
                title: 'Equipo activo',
                badge: _cargandoVoluntarios
                    ? null
                    : '${_voluntarios.length} voluntario${_voluntarios.length != 1 ? 's' : ''}',
              ),
              const SizedBox(height: 12),
              _EquipoActivo(
                voluntarios: _voluntarios,
                cargando: _cargandoVoluntarios,
              ),
              const SizedBox(height: 28),

              // ── Sección: Instrucciones ───────────────────────────────────
              _SectionHeader(
                icon: Icons.checklist_outlined,
                title: 'Pasos a seguir',
              ),
              const SizedBox(height: 12),
              const _Instrucciones(),
              const SizedBox(height: 32),

              // ── Botones de acción ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _iniciarBusqueda,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.directions_walk),
                  label: const Text(
                    'Iniciar búsqueda ahora',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Volver al detalle del operativo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets internos ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MapaCuadrante extends StatelessWidget {
  final ReporteModel ficha;

  const _MapaCuadrante({required this.ficha});

  @override
  Widget build(BuildContext context) {
    final center = LatLng(
      (ficha.cuadranteLatMin! + ficha.cuadranteLatMax!) / 2,
      (ficha.cuadranteLngMin! + ficha.cuadranteLngMax!) / 2,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 14.5,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  MapTileLayer(useSatellite: false),
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: [
                          LatLng(ficha.cuadranteLatMax!, ficha.cuadranteLngMin!),
                          LatLng(ficha.cuadranteLatMax!, ficha.cuadranteLngMax!),
                          LatLng(ficha.cuadranteLatMin!, ficha.cuadranteLngMax!),
                          LatLng(ficha.cuadranteLatMin!, ficha.cuadranteLngMin!),
                        ],
                        color: AppTheme.primary.withOpacity(0.2),
                        borderColor: AppTheme.primary,
                        borderStrokeWidth: 2.5,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      if (ficha.latitud != null)
                        Marker(
                          point: LatLng(ficha.latitud!, ficha.longitud!),
                          width: 32,
                          height: 32,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Etiqueta superpuesta
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location,
                        size: 12, color: AppTheme.primary),
                    SizedBox(width: 4),
                    Text(
                      'Cuadrante completo',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary),
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

class _CuadrantePendiente extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.5)),
      ),
      child: const Column(
        children: [
          Icon(Icons.pending_outlined, color: Color(0xFFE65100), size: 36),
          SizedBox(height: 10),
          Text(
            'Zona pendiente de asignación',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100),
                fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'El coordinador asignará tu cuadrante pronto. Recibirás una notificación cuando esté listo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF5F6368), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EquipoActivo extends StatelessWidget {
  final List<PerfilModel> voluntarios;
  final bool cargando;

  const _EquipoActivo({required this.voluntarios, required this.cargando});

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (voluntarios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Eres el primero en unirte. ¡Lidera el equipo!',
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: voluntarios.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final v = voluntarios[i];
          final inicial = v.nombreCompleto.isNotEmpty
              ? v.nombreCompleto[0].toUpperCase()
              : '?';
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(
                  inicial,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 52,
                child: Text(
                  v.nombreCompleto.split(' ').first,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Instrucciones extends StatelessWidget {
  const _Instrucciones();

  static const _pasos = [
    (
      icon: Icons.directions_walk,
      color: AppTheme.primary,
      titulo: 'Dirígete al área',
      desc: 'Ve a la zona de búsqueda indicada en el mapa de arriba.',
    ),
    (
      icon: Icons.gps_fixed,
      color: AppTheme.success,
      titulo: 'Activa el tracking',
      desc: 'Pulsa "Iniciar búsqueda" para que tu recorrido quede registrado.',
    ),
    (
      icon: Icons.camera_alt_outlined,
      color: AppTheme.warning,
      titulo: 'Reporta hallazgos',
      desc: 'Usa el botón de evidencias en el mapa para fotografiar cualquier pista.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_pasos.length, (i) {
        final paso = _pasos[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Número + línea vertical
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: paso.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: paso.color.withOpacity(0.4)),
                    ),
                    child: Icon(paso.icon, size: 18, color: paso.color),
                  ),
                  if (i < _pasos.length - 1)
                    Container(
                      width: 2,
                      height: 30,
                      color: const Color(0xFFE0E0E0),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paso.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        paso.desc,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
