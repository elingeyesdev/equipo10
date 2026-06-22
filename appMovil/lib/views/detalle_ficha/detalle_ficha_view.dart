import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/reporte_model.dart';
import '../perfil/perfil_publico_view.dart';
import '../widgets/nombre_con_insignia.dart';
import '../../models/campos_categoria.dart';
import '../../models/campo_categoria_model.dart';
import '../../viewmodels/detalle_ficha_viewmodel.dart';
import '../../viewmodels/editar_ficha_viewmodel.dart';
import '../../viewmodels/tracking_viewmodel.dart';
import '../../viewmodels/evidencia_viewmodel.dart';
import '../editar_ficha/editar_ficha_view.dart';
import 'mapa_operativo_view.dart';
import '../panel_control/panel_control_view.dart';
import '../tracking/tracking_view.dart';
import '../widgets/full_screen_image_view.dart';
import '../../theme/app_theme.dart';
import 'comentarios_section.dart';
import 'evidencias_section.dart';
import 'report_dialogs.dart';
import 'unirse_bottom_sheet.dart';
import 'geofencing_bloqueado_sheet.dart';
import '../../widgets/map_tile_layer.dart';

class DetalleFichaView extends StatefulWidget {
  final String fichaId;
  final String currentUserId;

  const DetalleFichaView({
    super.key,
    required this.fichaId,
    required this.currentUserId,
  });

  @override
  State<DetalleFichaView> createState() => _DetalleFichaViewState();
}

class _DetalleFichaViewState extends State<DetalleFichaView> {
  bool _huboCambios = false;
  int _selectedTab = 0;
  late EvidenciaViewModel _evidenciaVm;

  @override
  void initState() {
    super.initState();
    _evidenciaVm = EvidenciaViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<DetalleFichaViewModel>()
          .cargarFicha(widget.fichaId, widget.currentUserId);
    });
  }

  @override
  void dispose() {
    _evidenciaVm.dispose();
    super.dispose();
  }

  Future<void> _onUnirse() async {
    final vm = context.read<DetalleFichaViewModel>();
    final ficha = vm.ficha;
    if (ficha == null) return;

    await UnirseBottomSheet.show(
      context,
      ficha: ficha,
      usuarioId: widget.currentUserId,
      voluntariosActivos: vm.voluntariosCount,
    );

    if (mounted) {
      setState(() => _huboCambios = true);
      context.read<DetalleFichaViewModel>().cargarFicha(
            widget.fichaId,
            widget.currentUserId,
          );
    }
  }

  Future<void> _onAbandonar() async {
    final confirmar = await showAbandonarOperativoDialog(context);
    if (!confirmar || !mounted) return;

    final vm = context.read<DetalleFichaViewModel>();
    final success = await vm.abandonarBusqueda(
      widget.fichaId,
      widget.currentUserId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Has abandonado el operativo.'
            : (vm.errorMessage ?? 'Error al abandonar.')),
        backgroundColor: success ? Colors.orange : Colors.red.shade700,
      ),
    );
    if (success) setState(() => _huboCambios = true);
  }

  Future<void> _onEliminar() async {
    final confirmar = await showEliminarReporteDialog(context);
    if (!confirmar || !mounted) return;

    final editVm = context.read<EditarFichaViewModel>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await editVm.eliminarFicha(widget.fichaId);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ficha eliminada.'),
          backgroundColor: AppTheme.primary,
        ),
      );
      nav.pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(editVm.errorMessage ?? 'Error al eliminar.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _onIrAlPanel() async {
    final detaVm = context.read<DetalleFichaViewModel>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PanelControlView(fichaId: widget.fichaId),
      ),
    );
    if (mounted) {
      setState(() => _huboCambios = true);
      detaVm.cargarFicha(widget.fichaId, widget.currentUserId);
    }
  }

  Future<void> _onEditar(dynamic ficha) async {
    final detaVm = context.read<DetalleFichaViewModel>();
    final nav = Navigator.of(context);
    final result = await nav.push<bool>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => EditarFichaViewModel(),
          child: EditarFichaView(ficha: ficha),
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() => _huboCambios = true);
      detaVm.cargarFicha(widget.fichaId, widget.currentUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetalleFichaViewModel>();

    if (vm.isLoading && vm.ficha == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.ficha == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: const Center(child: Text('Ficha no encontrada.')),
      );
    }

    final ficha = vm.ficha!;
    final esCreador = ficha.creadoPor == widget.currentUserId;
    final esBloqueado = ficha.estado.toLowerCase() != 'activo';
    final estadoText = ficha.estado.toLowerCase();

    return ChangeNotifierProvider.value(
      value: _evidenciaVm,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          Navigator.of(context).pop(_huboCambios);
        },
        child: Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.darkBase),
              onPressed: () => Navigator.of(context).pop(_huboCambios),
            ),
            title: const Text(
              'Detalle del reporte',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.darkBase,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: esCreador
                ? [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: AppTheme.darkBase),
                      color: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) async {
                        if (value == 'editar') {
                          await _onEditar(ficha);
                        } else if (value == 'eliminar') {
                          await _onEliminar();
                        } else if (value == 'panel') {
                          await _onIrAlPanel();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Text(
                            'Editar reporte',
                            style: TextStyle(color: AppTheme.surface),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'panel',
                          child: Text(
                            'Ir al Panel de Control',
                            style: TextStyle(color: AppTheme.surface),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Text(
                            'Eliminar reporte',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]
                : null,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroImage(
                    fotoUrl: ficha.fotoUrl,
                    categoria: ficha.nombreCategoria),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ficha.titulo,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _EstadoSubtitulo(
                        estado: ficha.estado,
                        voluntariosCount: vm.voluntariosCount,
                        esCreador: esCreador,
                        yaVinculado: vm.yaVinculado,
                      ),
                      const SizedBox(height: 16),
                      _buildActionArea(vm, esCreador, esBloqueado, estadoText),
                      if (esBloqueado || vm.yaVinculado || !esCreador)
                        const SizedBox(height: 16),
                    ],
                  ),
                ),
                // Segmented navigation (inline, scrolls with page)
                _SegmentedNavBar(
                  selectedIndex: _selectedTab,
                  onChanged: (i) => setState(() => _selectedTab = i),
                ),
                // Tab content — no inner scroll, page scrolls as one
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildTabContent(
                      context, vm, ficha, esCreador),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, DetalleFichaViewModel vm,
      dynamic ficha, bool esCreador) {
    switch (_selectedTab) {
      case 1:
        return EvidenciasSection(
          reporteId: widget.fichaId,
          usuarioId: widget.currentUserId,
          puedePublicar: ficha.estado.toLowerCase() == 'activo',
          esCreador: esCreador,
        );
      case 2:
        return ComentariosSection(
          comentarios: vm.comentarios
              .map((c) => Map<String, dynamic>.from(c as Map))
              .toList(),
          currentUserId: widget.currentUserId,
          puedeComentar: ficha.estado.toLowerCase() == 'activo',
          esCreadorDelReporte: esCreador,
          hasMore: vm.hasMoreComentarios,
          onEnviar: (texto) =>
              vm.enviarComentario(widget.fichaId, texto),
          onEliminar: (comentarioId) =>
              vm.eliminarComentario(widget.fichaId, comentarioId),
          onCargarMas: () => vm.cargarMasComentarios(),
          onRefresh: () => vm.refrescarComentarios(),
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descripción del caso',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ficha.descripcion,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            _InfoSection(ficha: ficha),
            const SizedBox(height: 20),
            if (ficha.latitud != null && ficha.longitud != null)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapaOperativoView(
                        ficha: ficha,
                        esCreador: esCreador,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.info, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      IgnorePointer(
                        child: Consumer<EvidenciaViewModel>(
                            builder: (context, evidenciaVm, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter:
                                    LatLng(ficha.latitud!, ficha.longitud!),
                                initialZoom: 15.0,
                                interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none),
                              ),
                              children: [
                                MapTileLayer(useSatellite: false),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(
                                          ficha.latitud!, ficha.longitud!),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(Icons.location_on,
                                          color: Colors.red, size: 40),
                                    ),
                                    ...evidenciaVm.evidencias
                                        .where((e) =>
                                            (esCreador ||
                                                e.estado == 'approved') &&
                                            e.lat != null &&
                                            e.lng != null)
                                        .map((evidencia) {
                                      return Marker(
                                        point: LatLng(
                                            evidencia.lat!, evidencia.lng!),
                                        width: 30,
                                        height: 30,
                                        child: const Icon(Icons.camera_alt,
                                            color: Colors.blueAccent, size: 24),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      Container(color: Colors.black.withValues(alpha: 0.1)),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBase,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map, color: AppTheme.surface),
                              SizedBox(width: 8),
                              Text(
                                'Ver mapa de cuadrantes',
                                style: TextStyle(
                                  color: AppTheme.surface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (ficha.direccionReferencia != null &&
                              (ficha.direccionReferencia as String).isNotEmpty)
                          ? (ficha.direccionReferencia as String)
                          : ((ficha.cuadranteNombre != null &&
                                  ficha.cuadranteNombre!.isNotEmpty)
                              ? '${ficha.cuadranteNombre} (${ficha.cuadranteZona ?? "Zona"})'
                              : 'Ubicación seleccionada en el mapa'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActionArea(DetalleFichaViewModel vm, bool esCreador,
      bool esBloqueado, String estadoText) {
    final ficha = vm.ficha;
    if (ficha == null) return const SizedBox.shrink();

    if (esCreador) {
      return esBloqueado ? _BannerBloqueado(ficha: ficha) : const SizedBox.shrink();
    }

    if (esBloqueado) {
      return _BannerBloqueado(ficha: ficha);
    }

    if (vm.yaVinculado) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: ficha == null ? null : () => _onIniciarBusqueda(ficha),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.directions_walk),
              label: const Text(
                'Iniciar mi búsqueda',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: vm.isLoading ? null : _onAbandonar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.darkDark,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Abandonar operativo',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: vm.isLoading ? null : _onUnirse,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.info,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        icon: vm.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.group_add),
        label: const Text(
          'Unirme a la búsqueda',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _onIniciarBusqueda(ReporteModel ficha) async {
    if (ficha.cuadranteLatMin == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Este reporte no tiene un cuadrante asignado aún.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final trackingVm = context.read<TrackingViewModel>();
    final pos = await trackingVm.verificarGeofencing(
      latMin: ficha.cuadranteLatMin!,
      latMax: ficha.cuadranteLatMax!,
      lngMin: ficha.cuadranteLngMin!,
      lngMax: ficha.cuadranteLngMax!,
    );

    if (!mounted) return;

    if (pos == null) {
      Position? posActual;
      try {
        posActual = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      if (!mounted) return;

      await GeofencingBloqueadoSheet.show(
        context,
        ficha: ficha,
        posicionActual: posActual,
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackingView(
          ficha: ficha,
          usuarioId: widget.currentUserId,
        ),
      ),
    );
    if (mounted) {
      setState(() => _huboCambios = true);
      context
          .read<DetalleFichaViewModel>()
          .cargarFicha(widget.fichaId, widget.currentUserId);
    }
  }

}

// ─────────────────────────────────────────────────────────────────────────────
class _BannerBloqueado extends StatelessWidget {
  final ReporteModel ficha;

  const _BannerBloqueado({required this.ficha});

  @override
  Widget build(BuildContext context) {
    final e = ficha.estado.toLowerCase();
    final bool esResuelto =
        e == 'resuelto' || e == 'finalizado' || e == 'cerrado';

    final Color bgColor =
        esResuelto ? AppTheme.backgroundDark : AppTheme.accent;
    final Color contentColor =
        esResuelto ? AppTheme.textSecondary : AppTheme.darkDark;
    final titulo = esResuelto ? 'Reporte resuelto' : 'Reporte pausado';
    
    Widget subtituloWidget;
    if (esResuelto) {
      if (ficha.resueltoPorNombre != null && ficha.resueltoPorNombre!.isNotEmpty) {
        subtituloWidget = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Resuelto por: ', style: TextStyle(color: contentColor, fontSize: 13)),
            NombreConInsignia(
              nombre: ficha.resueltoPorNombre!,
              oro: ficha.resueltoPorOro,
              plataBronce: ficha.resueltoPorPlataBronce,
              baseStyle: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        );
      } else {
        subtituloWidget = Text('Volvió a casa', style: TextStyle(color: contentColor, fontSize: 13, fontWeight: FontWeight.w500));
      }
    } else {
      subtituloWidget = Text('No se admiten nuevos voluntarios.', style: TextStyle(color: contentColor, fontSize: 12));
    }
    final icono =
        esResuelto ? Icons.check_circle_outline : Icons.lock_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icono, color: contentColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: contentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                subtituloWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _HeroImage extends StatelessWidget {
  final String? fotoUrl;
  final String? categoria;

  const _HeroImage({this.fotoUrl, this.categoria});

  static IconData _iconoPorCategoria(String? cat) {
    if (cat == null) return Icons.person_search;
    final c = cat.toLowerCase().trim();
    if (c.contains('mascota') || c == 'mascotas') return Icons.pets;
    if (c.contains('veh') || c == 'vehículos' || c == 'vehiculos')
      return Icons.directions_car;
    if (c.contains('document') || c == 'documentos') return Icons.badge;
    if (c.contains('electr') || c == 'electrónicos' || c == 'electronicos')
      return Icons.devices;
    if (c.contains('persona') || c == 'personas') return Icons.person_search;
    return Icons.search;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (fotoUrl != null && fotoUrl!.isNotEmpty)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageView(
                    imageUrl: fotoUrl!,
                    tag: 'hero-image-${fotoUrl!}',
                  ),
                ),
              );
            },
            child: Hero(
              tag: 'hero-image-${fotoUrl!}',
              child: Container(
                width: double.infinity,
                height: 300,
                color: AppTheme.backgroundLight,
                child: CachedNetworkImage(
                  imageUrl: fotoUrl!,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => _placeholder(),
                  errorWidget: (context, url, error) => _placeholder(),
                ),
              ),
            ),
          )
        else
          _placeholder(),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x4D000000)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      height: 240,
      color: AppTheme.primary.withValues(alpha: 0.06),
      width: double.infinity,
      child: Icon(
        _iconoPorCategoria(categoria),
        size: 80,
        color: AppTheme.primaryLight,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _EstadoSubtitulo extends StatelessWidget {
  final String estado;
  final int voluntariosCount;
  final bool esCreador;
  final bool yaVinculado;

  const _EstadoSubtitulo({
    required this.estado,
    required this.voluntariosCount,
    required this.esCreador,
    this.yaVinculado = false,
  });

  @override
  Widget build(BuildContext context) {
    final e = estado.toLowerCase();
    final Color dotColor;
    if (e == 'activo') {
      dotColor = AppTheme.primaryBase;
    } else if (e == 'pausado') {
      dotColor = AppTheme.accent;
    } else {
      dotColor = AppTheme.backgroundDark;
    }

    final parts = <String>[
      estado[0].toUpperCase() + estado.substring(1),
      '$voluntariosCount ${voluntariosCount == 1 ? 'voluntario' : 'voluntarios'}',
      if (esCreador) 'Creado por ti',
      if (!esCreador && yaVinculado) 'Participando',
    ];

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          parts.join(' • '),
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final dynamic ficha;

  const _InfoSection({required this.ficha});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            if (ficha.nombreCategoria != null &&
                (ficha.nombreCategoria as String).isNotEmpty)
              _MiniCard(
                  icon: Icons.category_outlined,
                  label: 'Categoría',
                  value: ficha.nombreCategoria),
            if (ficha.fechaPerdida != null &&
                (ficha.fechaPerdida as String).isNotEmpty)
              _MiniCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha',
                  value: (ficha.fechaPerdida as String).length > 10
                      ? (ficha.fechaPerdida as String).substring(0, 10)
                      : ficha.fechaPerdida),
            if (ficha.recompensa != null && (ficha.recompensa as num) > 0)
              _MiniCard(
                  icon: Icons.monetization_on_outlined,
                  label: 'Recompensa',
                  value: '${ficha.recompensa} BOB'),
          ],
        ),
        const SizedBox(height: 16),
        if ((ficha.telefonoContacto != null &&
                (ficha.telefonoContacto as String).isNotEmpty) ||
            (ficha.emailContacto != null &&
                (ficha.emailContacto as String).isNotEmpty))
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INFORMACIÓN DE CONTACTO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                if (ficha.telefonoContacto != null &&
                    (ficha.telefonoContacto as String).isNotEmpty)
                  _ContactRow(
                      icon: Icons.phone_outlined,
                      text: ficha.telefonoContacto),
                if (ficha.emailContacto != null &&
                    (ficha.emailContacto as String).isNotEmpty)
                  _ContactRow(
                      icon: Icons.email_outlined, text: ficha.emailContacto),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (ficha.caracteristicas != null &&
            (ficha.caracteristicas as Map).isNotEmpty)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CARACTERÍSTICAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final camposRef = ficha.nombreCategoria != null
                      ? CamposCategoria.paraNombre(ficha.nombreCategoria!)
                      : <CampoCategoria>[];
                  final entries =
                      (ficha.caracteristicas as Map<String, dynamic>)
                          .entries
                          .map((entry) {
                    final clave = entry.key;
                    final valor = entry.value;
                    final campoRef = camposRef
                        .where((c) => c.clave == clave)
                        .firstOrNull;
                    final etiqueta = campoRef?.etiqueta ??
                        clave.replaceAll('_', ' ').toUpperCase();
                    final icono =
                        campoRef?.icono ?? Icons.info_outline;
                    String valorStr;
                    if (valor is bool) {
                      valorStr = valor ? 'Sí' : 'No';
                    } else if (valor == 1 ||
                        valor == '1' ||
                        valor == 'true') {
                      valorStr = 'Sí';
                    } else if (valor == 0 ||
                        valor == '0' ||
                        valor == 'false') {
                      valorStr = 'No';
                    } else {
                      valorStr = valor.toString();
                    }
                    return (icono: icono, texto: '$etiqueta: $valorStr');
                  }).toList();

                  // Build interleaved list: [item, separator, item, ...]
                  final widgets = <Widget>[];
                  for (int i = 0; i < entries.length; i++) {
                    final item = entries[i];
                    widgets.add(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icono,
                            size: 14, color: AppTheme.primaryBase),
                        const SizedBox(width: 5),
                        Text(
                          item.texto,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ));
                    if (i < entries.length - 1) {
                      widgets.add(const Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ));
                    }
                  }
                  return Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 6,
                    children: widgets,
                  );
                }),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (ficha.nombreUsuario != null &&
                (ficha.nombreUsuario as String).isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Text('Reportado por: ',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      Expanded(
                        child: NombreConInsignia(
                          nombre: ficha.nombreUsuario!,
                          oro: ficha.usuarioOro,
                          plataBronce: ficha.usuarioPlataBronce,
                          baseStyle: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (ficha.vistas != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_red_eye_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${ficha.vistas} vistas',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.primaryBase),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBase),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SegmentedNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const List<String> _labels = ['Detalles', 'Evidencias', 'Comentarios'];

  const _SegmentedNavBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: List.generate(_labels.length, (i) {
            final isSelected = i == selectedIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.darkBase.withValues(alpha: 0.10),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}