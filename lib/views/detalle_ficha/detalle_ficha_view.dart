import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/detalle_ficha_viewmodel.dart';
import '../../viewmodels/editar_ficha_viewmodel.dart';
import '../editar_ficha/editar_ficha_view.dart';

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

  Future<void> _onCerrarBusqueda() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outlined, color: Color(0xFFFF9800)),
            SizedBox(width: 8),
            Text('Cerrar búsqueda'),
          ],
        ),
        content: const Text(
          'Al cerrar la búsqueda, ningún voluntario nuevo podrá unirse. '
          'Los participantes actuales no se verán afectados.\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
            ),
            child: const Text('Cerrar búsqueda'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final vm = context.read<DetalleFichaViewModel>();
    final success = await vm.cerrarBusqueda(widget.fichaId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Búsqueda cerrada. No se admiten nuevos voluntarios.'
            : (vm.errorMessage ?? 'Error al cerrar la búsqueda.')),
        backgroundColor:
            success ? const Color(0xFFFF9800) : Colors.red.shade700,
      ),
    );
    // No hacemos pop — la ficha sigue visible con estado 'cerrado'
  }

  Future<void> _onReabrirBusqueda() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Text('Reabrir búsqueda'),
          ],
        ),
        content: const Text(
          '¿Deseas reabrir la búsqueda? Los voluntarios podrán volver a unirse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
            ),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final vm = context.read<DetalleFichaViewModel>();
    final success = await vm.reabrirBusqueda(widget.fichaId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '¡Búsqueda reabierta! Los voluntarios pueden unirse nuevamente.'
            : (vm.errorMessage ?? 'Error al reabrir.')),
        backgroundColor:
            success ? const Color(0xFF1B5E20) : Colors.red.shade700,
      ),
    );
    // No hacemos pop — la ficha sigue visible con estado 'activo'
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
    final esCerrado = ficha.estado.toLowerCase() == 'cerrado';

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

                  // Placeholder mapa
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF00BCD4), width: 1.5),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined,
                              size: 40, color: Color(0xFF00BCD4)),
                          SizedBox(height: 8),
                          Text(
                            // TODO: El equipo implementará el Mapa Interactivo aquí.
                            'Mapa Interactivo — Por implementar',
                            style: TextStyle(
                              color: Color(0xFF0277BD),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Botones de acción según rol y estado
                  _buildActionArea(vm, esCreador, esCerrado),
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
      DetalleFichaViewModel vm, bool esCreador, bool esCerrado) {
    if (esCreador) {
      return Column(
        children: [
          // Botón Panel de Control (siempre inactivo por ahora)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: null,
              // TODO: Navegar a la vista de gestión administrativa del Panel de Control.
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Ir al Panel de Control del Operativo'),
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: const Color(0xFF9E9E9E),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cerrar o Reabrir según el estado actual
          if (!esCerrado)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: vm.isLoading ? null : _onCerrarBusqueda,
                icon: vm.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_outline,
                        color: Color(0xFFE65100)),
                label: const Text(
                  'Cerrar búsqueda',
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: Color(0xFFFF9800), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else
            Column(
              children: [
                // Banner cerrado
                _BannerCerrado(),
                const SizedBox(height: 12),
                // Botón reabrir
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: vm.isLoading ? null : _onReabrirBusqueda,
                    icon: vm.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open,
                            color: Color(0xFF1B5E20)),
                    label: const Text(
                      'Reabrir búsqueda',
                      style: TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF4CAF50), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
    }

    // — Voluntario —
    if (esCerrado) {
      return _BannerCerrado();
    }

    if (vm.yaVinculado) {
      return Container(
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
      );
    }

    // Botón unirse (búsqueda activa)
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
}

/// Banner que indica que la búsqueda está cerrada.
class _BannerCerrado extends StatelessWidget {
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
      child: const Row(
        children: [
          Icon(Icons.lock, color: Color(0xFFE65100), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Búsqueda cerrada',
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color:
            isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? const Color(0xFF4CAF50)
              : const Color(0xFFFF9800),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF9800),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            estado.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFFE65100),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
