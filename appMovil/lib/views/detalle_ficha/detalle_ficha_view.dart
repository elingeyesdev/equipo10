import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/reporte_model.dart';
import '../../models/campos_categoria.dart';
import '../../models/campo_categoria_model.dart';
import '../../viewmodels/detalle_ficha_viewmodel.dart';
import '../../viewmodels/editar_ficha_viewmodel.dart';
import '../../viewmodels/tracking_viewmodel.dart';
import '../../viewmodels/evidencia_viewmodel.dart';
import '../editar_ficha/editar_ficha_view.dart';
import '../mapa/mapa_operativo_view.dart';
import '../panel_control/panel_control_view.dart';
import '../tracking/tracking_view.dart';
import '../widgets/full_screen_image_view.dart';
import '../../theme/app_theme.dart';
import 'evidencias_section.dart';
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

    // Abrir el Bottom Sheet de confirmación con el formulario del voluntario.
    // El propio sheet llama al API y navega a la pantalla de bienvenida si tiene éxito.
    await UnirseBottomSheet.show(
      context,
      ficha: ficha,
      usuarioId: widget.currentUserId,
      voluntariosActivos: vm.voluntariosCount,
    );

    // Refrescar el detalle al volver (el estado yaVinculado habrá cambiado)
    if (mounted) {
      setState(() => _huboCambios = true);
      context.read<DetalleFichaViewModel>().cargarFicha(
            widget.fichaId,
            widget.currentUserId,
          );
    }
  }

  Future<void> _onAbandonar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange),
            SizedBox(width: 8),
            Text('Abandonar operativo'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas retirarte de esta búsqueda? '  
          'Tu recorrido hasta ahora quedará guardado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

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
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar ficha'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta ficha? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

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
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(_huboCambios),
            ),
            title: Text(ficha.titulo, overflow: TextOverflow.ellipsis),
            actions: esCreador
                ? [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Editar ficha',
                      onPressed: () async {
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
                          detaVm.cargarFicha(
                            widget.fichaId,
                            widget.currentUserId,
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFEF9A9A),
                      ),
                      tooltip: 'Eliminar ficha',
                      onPressed: _onEliminar,
                    ),
                  ]
                : null,
          ),
          body: DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroImage(fotoUrl: ficha.fotoUrl, categoria: ficha.nombreCategoria),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _EstadoBadge(estado: ficha.estado),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E5F5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF8E24AA)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.group, size: 14, color: Color(0xFF8E24AA)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${vm.voluntariosCount} Voluntarios',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF8E24AA),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (esCreador)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.primary),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (ficha.avatarUsuario != null && ficha.avatarUsuario!.isNotEmpty) ...[
                                            CircleAvatar(
                                              radius: 8,
                                              backgroundImage: CachedNetworkImageProvider(ficha.avatarUsuario!),
                                              backgroundColor: Colors.transparent,
                                            ),
                                          ] else
                                            const Icon(Icons.person, size: 14, color: AppTheme.primary),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Tú creaste esta búsqueda',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                ficha.titulo,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 3,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.info,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildActionArea(vm, esCreador, esBloqueado, estadoText),
                            ]
                          )
                        )
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      const TabBar(
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppTheme.primary,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(text: "Detalles"),
                          Tab(text: "Evidencias"),
                          Tab(text: "Comentarios"),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  // Tab 1: Detalles
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Descripción del caso',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5F6368),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ficha.descripcion,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A1A1A),
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
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.info, width: 1.5),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Stack(
                                children: [
                                  IgnorePointer(
                                    child: Consumer<EvidenciaViewModel>(
                                      builder: (context, evidenciaVm, _) {
                                        return FlutterMap(
                                          options: MapOptions(
                                            initialCenter: LatLng(ficha.latitud!, ficha.longitud!),
                                            initialZoom: 15.0,
                                            interactionOptions: const InteractionOptions(
                                                flags: InteractiveFlag.none),
                                          ),
                                          children: [
                                            MapTileLayer(useSatellite: false),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: LatLng(ficha.latitud!, ficha.longitud!),
                                                  width: 40,
                                                  height: 40,
                                                  child: const Icon(Icons.location_on,
                                                      color: Colors.red, size: 40),
                                                ),
                                                ...evidenciaVm.evidencias.where((e) => (esCreador || e.estado == 'approved') && e.lat != null && e.lng != null).map((evidencia) {
                                                  return Marker(
                                                    point: LatLng(evidencia.lat!, evidencia.lng!),
                                                    width: 30,
                                                    height: 30,
                                                    child: const Icon(Icons.camera_alt, color: Colors.blueAccent, size: 24),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ],
                                        );
                                      }
                                    ),
                                  ),
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.1),
                                  ),
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.map, color: AppTheme.info),
                                          SizedBox(width: 8),
                                          Text(
                                            'Ver Mapa de Cuadrantes',
                                            style: TextStyle(
                                              color: AppTheme.primaryLight,
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
                              const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  (ficha.direccionReferencia != null && (ficha.direccionReferencia as String).isNotEmpty)
                                      ? (ficha.direccionReferencia as String)
                                      : ((ficha.cuadranteNombre != null && ficha.cuadranteNombre!.isNotEmpty)
                                          ? '${ficha.cuadranteNombre} (${ficha.cuadranteZona ?? "Zona"})'
                                          : 'Ubicación seleccionada en el mapa'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab 2: Evidencias
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: EvidenciasSection(
                      reporteId: widget.fichaId,
                      usuarioId: widget.currentUserId,
                      puedePublicar: ficha.estado.toLowerCase() == 'activo',
                      esCreador: esCreador,
                    ),
                  ),
                  // Tab 3: Comentarios
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildComentariosSection(vm),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea(
      DetalleFichaViewModel vm, bool esCreador, bool esBloqueado, String estadoText) {
    if (esCreador) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
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
              },
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Ir al Panel de Control de la búsqueda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (esBloqueado) _BannerBloqueado(estado: estadoText),
        ],
      );
    }

    if (esBloqueado) {
      return _BannerBloqueado(estado: estadoText);
    }

    final ficha = vm.ficha;

    if (vm.yaVinculado) {
      return Column(
        children: [
          // Banner de participación activa
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.success),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ya estás participando en esta búsqueda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Botón principal: Iniciar búsqueda
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: ficha == null ? null : () => _onIniciarBusqueda(ficha),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.directions_walk),
              label: const Text(
                'Iniciar mi Búsqueda',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Botón secundario: Abandonar operativo
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: vm.isLoading ? null : _onAbandonar,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: const Text(
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: vm.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

    final trackingVm = TrackingViewModel();
    final pos = await trackingVm.verificarGeofencing(
      latMin: ficha.cuadranteLatMin!,
      latMax: ficha.cuadranteLatMax!,
      lngMin: ficha.cuadranteLngMin!,
      lngMax: ficha.cuadranteLngMax!,
    );

    if (!mounted) return;

    if (pos == null) {
      // Usar getLastKnownPosition() en lugar de getCurrentPosition():
      // es instantáneo porque no espera señal GPS, solo lee el último
      // dato en caché del sistema. El sheet muestra el mapa igual sin ella.
      Position? posActual;
      try {
        posActual = await Geolocator.getLastKnownPosition();
      } catch (_) {
        // Si tampoco hay posición en caché, el sheet se muestra sin el punto azul
      }

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
        builder: (_) => ChangeNotifierProvider(
          create: (_) => TrackingViewModel(),
          child: TrackingView(
            ficha: ficha,
            usuarioId: widget.currentUserId,
          ),
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

  Widget _buildComentariosSection(DetalleFichaViewModel vm) {
    final TextEditingController ctrl = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comentarios Ciudadanos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        if (vm.comentarios.isEmpty)
          const Text('No hay comentarios aún. ¡Sé el primero en escribir!',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vm.comentarios.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = vm.comentarios[index];
              final autor = c['usuario'] != null ? c['usuario']['nombre'] : 'Anónimo';
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(autor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(c['texto'] ?? '', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        if (vm.ficha?.estado.toLowerCase() == 'activo')
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    hintText: 'Añadir comentario...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: () async {
                    if (ctrl.text.trim().isEmpty) return;
                    await vm.enviarComentario(widget.fichaId, ctrl.text.trim(), widget.currentUserId);
                    ctrl.clear();
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _BannerBloqueado extends StatelessWidget {
  final String estado;

  const _BannerBloqueado({required this.estado});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Color(0xFFE65100), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Búsqueda $estado',
                  style: const TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'No se admiten nuevos voluntarios.',
                  style: TextStyle(color: Color(0xFF5F6368), fontSize: 12),
                ),
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
    if (c.contains('veh') || c == 'vehículos' || c == 'vehiculos') return Icons.directions_car;
    if (c.contains('document') || c == 'documentos') return Icons.badge;
    if (c.contains('electr') || c == 'electrónicos' || c == 'electronicos') return Icons.devices;
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
              child: CachedNetworkImage(
                imageUrl: fotoUrl!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                placeholder: (context, url) => _placeholder(),
                errorWidget: (context, url, error) => _placeholder(),
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
class _EstadoBadge extends StatelessWidget {
  final String estado;

  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final isActive = estado.toLowerCase() == 'activo';
    Color bg;
    Color border;

    if (isActive) {
      bg = AppTheme.primary.withValues(alpha: 0.06);
      border = AppTheme.success;
    } else if (estado.toLowerCase() == 'pausado') {
      bg = const Color(0xFFFFF3E0);
      border = const Color(0xFFFF9800);
    } else {
      bg = const Color(0xFFFFEBEE);
      border = const Color(0xFFF44336);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: border,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            estado.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: border,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
            if (ficha.nombreCategoria != null && (ficha.nombreCategoria as String).isNotEmpty)
              _MiniCard(
                  icon: Icons.category_outlined,
                  label: 'Categoría',
                  value: ficha.nombreCategoria),
            if (ficha.fechaPerdida != null && (ficha.fechaPerdida as String).isNotEmpty)
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
                  value: '${ficha.recompensa} BOB',
                  color: Colors.green),
          ],
        ),
        const SizedBox(height: 16),

        if ((ficha.telefonoContacto != null &&
                (ficha.telefonoContacto as String).isNotEmpty) ||
            (ficha.emailContacto != null &&
                (ficha.emailContacto as String).isNotEmpty))
          Card(
            elevation: 0,
            color: const Color(0xFFF8F9FA),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE0E0E0))),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INFORMACIÓN DE CONTACTO',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5F6368),
                          letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  if (ficha.telefonoContacto != null &&
                      (ficha.telefonoContacto as String).isNotEmpty)
                    _ContactRow(
                        icon: Icons.phone_outlined, text: ficha.telefonoContacto),
                  if (ficha.emailContacto != null &&
                      (ficha.emailContacto as String).isNotEmpty)
                    _ContactRow(
                        icon: Icons.email_outlined, text: ficha.emailContacto),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        if (ficha.caracteristicas != null &&
            (ficha.caracteristicas as Map).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CARACTERÍSTICAS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5F6368),
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (ficha.caracteristicas as Map<String, dynamic>).entries.map((entry) {
                  final clave = entry.key;
                  final valor = entry.value;

                  final camposRef = ficha.nombreCategoria != null
                      ? CamposCategoria.paraNombre(ficha.nombreCategoria!)
                      : <CampoCategoria>[];
                  final campoRef =
                      camposRef.where((c) => c.clave == clave).firstOrNull;

                  final etiqueta =
                      campoRef?.etiqueta ?? clave.replaceAll('_', ' ').toUpperCase();
                  final icono = campoRef?.icono ?? Icons.info_outline;

                  String valorStr;
                  if (valor is bool) {
                    valorStr = valor ? 'Sí' : 'No';
                  } else if (valor == 1 || valor == '1' || valor == 'true') {
                    valorStr = 'Sí';
                  } else if (valor == 0 || valor == '0' || valor == 'false') {
                    valorStr = 'No';
                  } else {
                    valorStr = valor.toString();
                  }

                  return Chip(
                    avatar: Icon(icono, size: 16, color: AppTheme.primary),
                    label: Text('$etiqueta: $valorStr'),
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.06),
                    side: BorderSide.none,
                    labelStyle:
                        const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
                  );
                }).toList(),
              ),
            ],
          ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (ficha.nombreUsuario != null &&
                (ficha.nombreUsuario as String).isNotEmpty)
              Expanded(
                child: Text('Reportado por: ${ficha.nombreUsuario}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            if (ficha.vistas != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${ficha.vistas} vistas',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
  final Color color;

  const _MiniCard(
      {required this.icon,
      required this.label,
      required this.value,
      this.color = AppTheme.primaryLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
              overflow: TextOverflow.ellipsis),
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
          Icon(icon, size: 18, color: const Color(0xFF5F6368)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF1A1A1A)))),
        ],
      ),
    );
  }
}


class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
