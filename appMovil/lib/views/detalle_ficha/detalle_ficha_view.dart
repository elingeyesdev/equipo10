import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reporte_model.dart';
import '../../models/campos_categoria.dart';
import '../../models/campo_categoria_model.dart';
import '../../viewmodels/detalle_ficha_viewmodel.dart';
import '../../viewmodels/editar_ficha_viewmodel.dart';
import '../../viewmodels/tracking_viewmodel.dart';
import '../editar_ficha/editar_ficha_view.dart';
import '../mapa/mapa_operativo_view.dart';
import '../panel_control/panel_control_view.dart';
import '../tracking/tracking_view.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<DetalleFichaViewModel>()
          .cargarFicha(widget.fichaId, widget.currentUserId);
    });
  }

  Future<void> _onUnirse() async {
    final vm = context.read<DetalleFichaViewModel>();
    final success = await vm.unirseABusqueda(
      widget.fichaId,
      widget.currentUserId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? (vm.successMessage ?? '¡Te uniste a la búsqueda!')
            : (vm.errorMessage ?? 'Error al unirse.')),
        backgroundColor:
            success ? const Color(0xFF1B5E20) : Colors.red.shade700,
      ),
    );
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
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
      // pop(true) → el feed escucha esto y recarga inmediatamente
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

    return Scaffold(
      appBar: AppBar(
        title: Text(ficha.titulo, overflow: TextOverflow.ellipsis),
        actions: esCreador
            ? [
                // El creador puede editar siempre (activa o cerrada)
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen hero
            _HeroImage(fotoUrl: ficha.fotoUrl),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila: estado + badge creador
                  Row(
                    children: [
                      _EstadoBadge(estado: ficha.estado),
                      const SizedBox(width: 8),
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
                      const Spacer(),
                      if (esCreador)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x1A1B5E20),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: const Color(0xFF1B5E20)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person,
                                  size: 14, color: Color(0xFF1B5E20)),
                              SizedBox(width: 4),
                              Text(
                                'Tú creaste este operativo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Título
                  Text(
                    ficha.titulo,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Divider celeste
                  Container(
                    height: 3,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Descripción
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

                  // ── Información adicional del reporte ──
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
                          border: Border.all(
                              color: const Color(0xFF00BCD4), width: 1.5),
                          image: const DecorationImage(
                            image: NetworkImage('https://maps.wikimedia.org/osm-intl/14/5443/9262.png'), // Mapa genérico visual
                            fit: BoxFit.cover,
                            opacity: 0.4,
                          )
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map, color: Color(0xFF00BCD4)),
                                SizedBox(width: 8),
                                Text(
                                  'Ver Mapa de Cuadrantes',
                                  style: TextStyle(
                                    color: Color(0xFF0277BD),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Botones de acción según rol y estado
                  _buildActionArea(vm, esCreador, esBloqueado, estadoText),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea(
      DetalleFichaViewModel vm, bool esCreador, bool esBloqueado, String estadoText) {
    if (esCreador) {
      return Column(
        children: [
          // Botón Panel de Control
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
                // Recargar al volver
                if (mounted) {
                  detaVm.cargarFicha(widget.fichaId, widget.currentUserId);
                }
              },
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Ir al Panel de Control del Operativo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!esBloqueado)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final TextEditingController ctrl = TextEditingController();
                      final justificacion = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Pausar Búsqueda'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Indica la razón para pausar esta búsqueda.'),
                              const SizedBox(height: 12),
                              TextField(
                                controller: ctrl,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Ej: Clima adverso, falta de luz, etc.',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(null),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (ctrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('La justificación es obligatoria.')),
                                  );
                                } else {
                                  Navigator.of(ctx).pop(ctrl.text.trim());
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800)),
                              child: const Text('Pausar'),
                            ),
                          ],
                        ),
                      );

                      if (justificacion != null && mounted) {
                        final detaVm = context.read<DetalleFichaViewModel>();
                        final success = await detaVm.pausarBusqueda(widget.fichaId, justificacion);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('La búsqueda ha sido pausada.'),
                              backgroundColor: Color(0xFF1B5E20),
                            ),
                          );
                          detaVm.cargarFicha(widget.fichaId, widget.currentUserId);
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(detaVm.errorMessage ?? 'Error al pausar.'),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.pause),
                    label: const Text('Pausar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Finalizar Búsqueda'),
                          content: const Text('¿Estás seguro de que deseas dar por finalizada esta búsqueda?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                              child: const Text('Finalizar'),
                            ),
                          ],
                        ),
                      );

                      if (confirmar == true && mounted) {
                        final detaVm = context.read<DetalleFichaViewModel>();
                        final success = await detaVm.cerrarBusqueda(widget.fichaId);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('La búsqueda ha sido finalizada.'),
                              backgroundColor: Color(0xFF1B5E20),
                            ),
                          );
                          detaVm.cargarFicha(widget.fichaId, widget.currentUserId);
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(detaVm.errorMessage ?? 'Error al finalizar.'),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Finalizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF388E3C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          if (esBloqueado) ...[
            if (estadoText.toLowerCase() == 'pausado')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Reanudar Búsqueda'),
                          content: const Text('¿Deseas volver a poner el operativo en estado Activo? Los voluntarios podrán unirse nuevamente.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                              child: const Text('Reanudar'),
                            ),
                          ],
                        ),
                      );

                      if (confirmar == true && mounted) {
                        final detaVm = context.read<DetalleFichaViewModel>();
                        final success = await detaVm.reabrirBusqueda(widget.fichaId);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('La búsqueda ha sido reanudada exitosamente.'),
                              backgroundColor: Color(0xFF1B5E20),
                            ),
                          );
                          detaVm.cargarFicha(widget.fichaId, widget.currentUserId);
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(detaVm.errorMessage ?? 'Error al reanudar.'),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reanudar Búsqueda'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            _BannerBloqueado(estado: estadoText),
          ],
        ],
      );
    }

    // — Voluntario —
    if (esBloqueado) {
      return _BannerBloqueado(estado: estadoText);
    }

    final ficha = vm.ficha;

    if (vm.yaVinculado) {
      return Column(
        children: [
          // Banner: ya participando
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50)),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF1B5E20)),
                  SizedBox(width: 8),
                  Text(
                    'Ya estás participando en esta búsqueda',
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Botón de iniciar búsqueda (tracking)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: ficha == null ? null : () => _onIniciarBusqueda(ficha),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
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
        ],
      );
    }

    // Botón unirse (búsqueda activa, usuario no vinculado)
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: vm.isLoading ? null : _onUnirse,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
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

  Future<void> _onIniciarBusqueda(dynamic ficha) async {
    // Verificar que el reporte tenga cuadrante con bounds
    if (ficha.cuadranteLatMin == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Este reporte no tiene un cuadrante asignado aún.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    // Verificar geofencing con el ViewModel de tracking
    final trackingVm = TrackingViewModel();
    final pos = await trackingVm.verificarGeofencing(
      latMin: ficha.cuadranteLatMin!,
      latMax: ficha.cuadranteLatMax!,
      lngMin: ficha.cuadranteLngMin!,
      lngMax: ficha.cuadranteLngMax!,
    );

    if (!mounted) return;

    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(trackingVm.errorMessage ?? 'No estás en el cuadrante.'),
        backgroundColor: Colors.red.shade700,
      ));
      return;
    }

    // Navegar a la pantalla de tracking
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => TrackingViewModel(),
          child: TrackingView(
            ficha: ficha as ReporteModel,
            usuarioId: widget.currentUserId,
          ),
        ),
      ),
    );
    // Recargar detalle al volver
    if (mounted) {
      context
          .read<DetalleFichaViewModel>()
          .cargarFicha(widget.fichaId, widget.currentUserId);
    }
  }
}


/// Banner que indica que la búsqueda está cerrada o pausada.
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
                  style:
                      TextStyle(color: Color(0xFF5F6368), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Imagen hero en la parte superior del detalle.
class _HeroImage extends StatelessWidget {
  final String? fotoUrl;

  const _HeroImage({this.fotoUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (fotoUrl != null && fotoUrl!.isNotEmpty)
          Image.network(
            fotoUrl!,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
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
      color: const Color(0xFFE8F5E9),
      width: double.infinity,
      child: const Icon(
        Icons.person_search,
        size: 80,
        color: Color(0xFF4CAF50),
      ),
    );
  }
}

/// Badge del estado de la ficha (activo / cerrado).
class _EstadoBadge extends StatelessWidget {
  final String estado;

  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final isActive = estado.toLowerCase() == 'activo';
    Color bg;
    Color border;

    if (isActive) {
      bg = const Color(0xFFE8F5E9);
      border = const Color(0xFF4CAF50);
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

/// Sección de información detallada del reporte.
class _InfoSection extends StatelessWidget {
  final dynamic ficha; // ReporteModel

  const _InfoSection({required this.ficha});

  @override
  Widget build(BuildContext context) {
    final items = <_InfoRow>[];

    if (ficha.nombreCategoria != null && (ficha.nombreCategoria as String).isNotEmpty) {
      items.add(_InfoRow(icon: Icons.category_outlined, label: 'Categoría', value: ficha.nombreCategoria));
    }
    if (ficha.tipoReporte != null && (ficha.tipoReporte as String).isNotEmpty) {
      items.add(_InfoRow(
        icon: ficha.tipoReporte == 'perdido' ? Icons.search : Icons.check_circle_outline,
        label: 'Tipo',
        value: ficha.tipoReporte == 'perdido' ? 'Persona Perdida' : 'Persona Encontrada',
      ));
    }
    if (ficha.prioridad != null && (ficha.prioridad as String).isNotEmpty) {
      items.add(_InfoRow(icon: Icons.priority_high, label: 'Prioridad', value: (ficha.prioridad as String).toUpperCase()));
    }
    if (ficha.fechaPerdida != null && (ficha.fechaPerdida as String).isNotEmpty) {
      final rawFecha = ficha.fechaPerdida as String;
      final shortFecha = rawFecha.length > 10 ? rawFecha.substring(0, 10) : rawFecha;
      items.add(_InfoRow(icon: Icons.calendar_today_outlined, label: 'Fecha del evento', value: shortFecha));
    }
    if (ficha.direccionReferencia != null && (ficha.direccionReferencia as String).isNotEmpty) {
      items.add(_InfoRow(icon: Icons.location_on_outlined, label: 'Dirección de referencia', value: ficha.direccionReferencia));
    }
    if (ficha.telefonoContacto != null && (ficha.telefonoContacto as String).isNotEmpty) {
      items.add(_InfoRow(icon: Icons.phone_outlined, label: 'Teléfono de contacto', value: ficha.telefonoContacto));
    }
    if (ficha.emailContacto != null && (ficha.emailContacto as String).isNotEmpty) {
      items.add(_InfoRow(icon: Icons.email_outlined, label: 'Email de contacto', value: ficha.emailContacto));
    }
    if (ficha.nombreUsuario != null && (ficha.nombreUsuario as String).isNotEmpty) {
      items.add(_InfoRow(icon: Icons.person_outline, label: 'Reportado por', value: ficha.nombreUsuario));
    }
    if (ficha.vistas != null) {
      items.add(_InfoRow(icon: Icons.visibility_outlined, label: 'Vistas', value: '${ficha.vistas}'));
    }

    // Campos dinámicos de la categoría
    if (ficha.caracteristicas != null && (ficha.caracteristicas as Map).isNotEmpty) {
      final chars = ficha.caracteristicas as Map<String, dynamic>;
      final camposRef = ficha.nombreCategoria != null 
          ? CamposCategoria.paraNombre(ficha.nombreCategoria!)
          : <CampoCategoria>[];

      chars.forEach((clave, valor) {
        // Buscar el campo en la referencia para obtener etiqueta e icono
        final campoRef = camposRef.where((c) => c.clave == clave).firstOrNull;
        
        final etiqueta = campoRef?.etiqueta ?? clave.replaceAll('_', ' ').toUpperCase();
        final icono = campoRef?.icono ?? Icons.info_outline;
        
        String valorStr;
        if (valor is bool) {
          valorStr = valor ? 'Sí' : 'No';
        } else {
          valorStr = valor.toString();
        }

        items.add(_InfoRow(icon: icono, label: etiqueta, value: valorStr));
      });
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'INFORMACIÓN DEL CASO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5F6368),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          ...items.map((row) => row).toList(),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? '—',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
