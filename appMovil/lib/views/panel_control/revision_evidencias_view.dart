import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/evidencia_model.dart';
import '../../viewmodels/evidencia_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../widgets/full_screen_image_view.dart';

class RevisionEvidenciasView extends StatefulWidget {
  final String reporteId;
  final String reporteTitulo;

  const RevisionEvidenciasView({
    super.key,
    required this.reporteId,
    required this.reporteTitulo,
  });

  @override
  State<RevisionEvidenciasView> createState() => _RevisionEvidenciasViewState();
}

class _RevisionEvidenciasViewState extends State<RevisionEvidenciasView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<EvidenciaViewModel>()
          .cargarEvidencias(widget.reporteId, esCreador: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EvidenciaViewModel>();

    final pendientes =
        vm.evidencias.where((e) => e.estado == 'pending').toList();
    final aprobadas =
        vm.evidencias.where((e) => e.estado == 'approved').toList();
    final rechazadas =
        vm.evidencias.where((e) => e.estado == 'rejected').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision de Evidencias'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${pendientes.length}'),
                isLabelVisible: pendientes.isNotEmpty,
                backgroundColor: Colors.orange,
                child: const Icon(Icons.hourglass_top),
              ),
              text: 'Pendientes',
            ),
            Tab(
              icon: Badge(
                label: Text('${aprobadas.length}'),
                isLabelVisible: aprobadas.isNotEmpty,
                backgroundColor: Colors.green,
                child: const Icon(Icons.check_circle),
              ),
              text: 'Aprobadas',
            ),
            Tab(
              icon: Badge(
                label: Text('${rechazadas.length}'),
                isLabelVisible: rechazadas.isNotEmpty,
                backgroundColor: Colors.red,
                child: const Icon(Icons.cancel),
              ),
              text: 'Rechazadas',
            ),
          ],
        ),
      ),
      body: vm.cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _EvidenciasList(
                  evidencias: pendientes,
                  reporteId: widget.reporteId,
                  tipo: 'pending',
                  emptyMessage: 'No hay evidencias pendientes de revision.',
                  emptyIcon: Icons.hourglass_empty,
                ),
                _EvidenciasList(
                  evidencias: aprobadas,
                  reporteId: widget.reporteId,
                  tipo: 'approved',
                  emptyMessage: 'Aun no has aprobado ninguna evidencia.',
                  emptyIcon: Icons.check_circle_outline,
                ),
                _EvidenciasList(
                  evidencias: rechazadas,
                  reporteId: widget.reporteId,
                  tipo: 'rejected',
                  emptyMessage: 'No has rechazado ninguna evidencia.',
                  emptyIcon: Icons.cancel_outlined,
                ),
              ],
            ),
    );
  }
}

// Lista de evidencias segun tipo
class _EvidenciasList extends StatelessWidget {
  final List<EvidenciaModel> evidencias;
  final String reporteId;
  final String tipo;
  final String emptyMessage;
  final IconData emptyIcon;

  const _EvidenciasList({
    required this.evidencias,
    required this.reporteId,
    required this.tipo,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (evidencias.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context
            .read<EvidenciaViewModel>()
            .cargarEvidencias(reporteId, esCreador: true);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: evidencias.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => _EvidenciaCard(
          evidencia: evidencias[i],
          reporteId: reporteId,
          tipo: tipo,
        ),
      ),
    );
  }
}

// Card de evidencia con foto, descripcion, voluntario y acciones
class _EvidenciaCard extends StatefulWidget {
  final EvidenciaModel evidencia;
  final String reporteId;
  final String tipo;

  const _EvidenciaCard({
    required this.evidencia,
    required this.reporteId,
    required this.tipo,
  });

  @override
  State<_EvidenciaCard> createState() => _EvidenciaCardState();
}

class _EvidenciaCardState extends State<_EvidenciaCard> {
  bool _procesando = false;

  Future<void> _accion(bool aprobar) async {
    setState(() => _procesando = true);
    final vm = context.read<EvidenciaViewModel>();
    bool ok;
    if (aprobar) {
      ok = await vm.aprobarEvidencia(widget.evidencia.id, widget.reporteId);
    } else {
      ok = await vm.rechazarEvidencia(widget.evidencia.id, widget.reporteId);
    }
    if (!mounted) return;
    setState(() => _procesando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (aprobar ? 'Evidencia aprobada' : 'Evidencia rechazada')
            : 'Error al procesar la evidencia'),
        backgroundColor: ok
            ? (aprobar ? AppTheme.success : Colors.red.shade700)
            : Colors.red.shade700,
      ),
    );
  }

  String _tiempoRelativo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} dias';
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (widget.tipo) {
      case 'pending':
        borderColor = const Color(0xFFFFD700);
        badgeColor = const Color(0xFFFFC107);
        badgeText = 'PENDIENTE';
        badgeIcon = Icons.hourglass_top;
        break;
      case 'approved':
        borderColor = Colors.green;
        badgeColor = Colors.green;
        badgeText = 'APROBADA';
        badgeIcon = Icons.check_circle;
        break;
      default:
        borderColor = Colors.red;
        badgeColor = Colors.red;
        badgeText = 'RECHAZADA';
        badgeIcon = Icons.cancel;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge de estado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(badgeIcon, color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  _tiempoRelativo(widget.evidencia.creadoEn),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Foto (clickeable para pantalla completa)
          if (widget.evidencia.fotoUrl != null &&
              widget.evidencia.fotoUrl!.isNotEmpty)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageView(
                    imageUrl: widget.evidencia.fotoUrl!,
                    tag: 'rev-ev-${widget.evidencia.id}',
                  ),
                ),
              ),
              child: Hero(
                tag: 'rev-ev-${widget.evidencia.id}',
                child: ClipRRect(
                  child: CachedNetworkImage(
                    imageUrl: widget.evidencia.fotoUrl!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 220,
                      color: Colors.grey.shade100,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 220,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            size: 56, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descripcion
                Text(
                  widget.evidencia.descripcion,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                // GPS
                if (widget.evidencia.lat != null && widget.evidencia.lng != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 13, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.evidencia.lat!.toStringAsFixed(5)}, ${widget.evidencia.lng!.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (widget.evidencia.lat != null) const SizedBox(height: 8),
                // Voluntario
                Row(
                  children: [
                    if (widget.evidencia.avatarUsuario != null &&
                        widget.evidencia.avatarUsuario!.isNotEmpty)
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: CachedNetworkImageProvider(
                            widget.evidencia.avatarUsuario!),
                        backgroundColor: Colors.transparent,
                      )
                    else
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person,
                            size: 16, color: AppTheme.primary),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.evidencia.nombreUsuario ?? 'Voluntario',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Botones aprobar/rechazar solo para pendientes
                if (widget.tipo == 'pending') ...[
                  const SizedBox(height: 14),
                  if (_procesando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _accion(false),
                            icon: const Icon(Icons.close,
                                color: Colors.red, size: 18),
                            label: const Text('Rechazar',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _accion(true),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Aprobar',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppTheme.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
