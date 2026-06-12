import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/evidencia_model.dart';
import '../../viewmodels/evidencia_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../utils/descarga/descargador.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined,
                color: Colors.white),
            tooltip: 'Descargar Evidencias',
            onPressed: () {
              if (vm.evidencias.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'No hay evidencias disponibles en este operativo para descargar.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              _mostrarDialogoDescarga(context, vm.evidencias);
            },
          ),
        ],
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

  void _mostrarDialogoDescarga(
      BuildContext context, List<EvidenciaModel> evidencias) {
    String filtro = 'approved';
    String formato = 'dossier';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.download_for_offline,
                      color: AppTheme.primary, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Descarga de Evidencias',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtro de Evidencias:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('Solo Aprobadas (Recomendado)',
                          style: TextStyle(fontSize: 13)),
                      value: 'approved',
                      groupValue: filtro,
                      activeColor: AppTheme.primary,
                      onChanged: (val) {
                        setState(() => filtro = val!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text(
                          'Todas (Aprobadas, Pendientes y Rechazadas)',
                          style: TextStyle(fontSize: 13)),
                      value: 'all',
                      groupValue: filtro,
                      activeColor: AppTheme.primary,
                      onChanged: (val) {
                        setState(() => filtro = val!);
                      },
                    ),
                    const Divider(),
                    const Text(
                      'Formato de Descarga:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('Ficha de Evidencias (HTML imprimible)',
                          style: TextStyle(fontSize: 13)),
                      value: 'dossier',
                      groupValue: formato,
                      activeColor: AppTheme.primary,
                      onChanged: (val) {
                        setState(() => formato = val!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Fotos individuales (.jpg)',
                          style: TextStyle(fontSize: 13)),
                      value: 'photos',
                      groupValue: formato,
                      activeColor: AppTheme.primary,
                      onChanged: (val) {
                        setState(() => formato = val!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Ficha + Fotos individuales',
                          style: TextStyle(fontSize: 13)),
                      value: 'both',
                      groupValue: formato,
                      activeColor: AppTheme.primary,
                      onChanged: (val) {
                        setState(() => formato = val!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _procesarDescarga(context, evidencias, filtro, formato);
                  },
                  child: const Text('Descargar',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _procesarDescarga(
    BuildContext context,
    List<EvidenciaModel> evidencias,
    String filtro,
    String formato,
  ) async {
    final filtradas = filtro == 'approved'
        ? evidencias.where((e) => e.estado == 'approved').toList()
        : evidencias;

    if (filtradas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No hay evidencias disponibles para descargar con el filtro seleccionado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Generando y descargando evidencias. Por favor, espere...',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );

    int exitosas = 0;
    int fallidas = 0;

    try {
      if (formato == 'dossier' || formato == 'both') {
        final String htmlContent = _generarHtmlDossier(filtradas);
        await Descargador.descargarTexto(
          htmlContent,
          'ficha_evidencias_${widget.reporteId}.html',
          'text/html',
        );
        exitosas++;
      }

      if (formato == 'photos' || formato == 'both') {
        for (int i = 0; i < filtradas.length; i++) {
          final e = filtradas[i];
          if (e.fotoUrl != null && e.fotoUrl!.isNotEmpty) {
            try {
              final String cleanName = (e.nombreUsuario ?? 'voluntario')
                  .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
              final String fileName =
                  'evidencia_${widget.reporteId}_${e.id}_$cleanName.jpg';
              await Descargador.descargarArchivo(e.fotoUrl!, fileName);
              exitosas++;
            } catch (err) {
              fallidas++;
            }
          }
        }
      }

      if (!context.mounted) return;
      Navigator.pop(context);
      _mostrarDialogoExito(context, exitosas, fallidas, formato);
    } catch (err) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al realizar la descarga masiva: $err'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoExito(
      BuildContext context, int exitosas, int fallidas, String formato) {
    String mensaje = '';
    if (formato == 'dossier') {
      mensaje =
          'La ficha de evidencias HTML del operativo ha sido generada y descargada correctamente.';
    } else if (formato == 'photos') {
      mensaje =
          'Se completó la descarga de imágenes individuales.\n\n• Descargas exitosas: $exitosas\n• Errores: $fallidas';
    } else {
      mensaje =
          'Se descargaron exitosamente tanto la ficha de evidencias HTML como las fotos individuales.\n\n• Descargas exitosas: $exitosas\n• Errores: $fallidas';
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text(
                'Descarga Completada',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            mensaje,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _generarHtmlDossier(List<EvidenciaModel> evidencias) {
    final String fechaGen = DateTime.now().toLocal().toString().split('.')[0];
    final StringBuffer tableRows = StringBuffer();
    final StringBuffer cards = StringBuffer();

    for (final e in evidencias) {
      final String fecha = e.creadoEn != null
          ? '${e.creadoEn!.day}/${e.creadoEn!.month}/${e.creadoEn!.year} ${e.creadoEn!.hour.toString().padLeft(2, '0')}:${e.creadoEn!.minute.toString().padLeft(2, '0')}'
          : 'N/A';
      final String coords = e.lat != null && e.lng != null
          ? '${e.lat!.toStringAsFixed(6)}, ${e.lng!.toStringAsFixed(6)}'
          : 'Sin coordenadas';

      String badgeClass = 'badge-pending';
      String estadoText = 'Pendiente';
      if (e.estado == 'approved') {
        badgeClass = 'badge-approved';
        estadoText = 'Aprobada';
      } else if (e.estado == 'rejected') {
        badgeClass = 'badge-rejected';
        estadoText = 'Rechazada';
      }

      tableRows.write('''
        <tr>
          <td><strong>${e.nombreUsuario ?? 'Voluntario'}</strong></td>
          <td>${e.descripcion.isNotEmpty ? e.descripcion : 'Sin descripción'}</td>
          <td><code>$coords</code></td>
          <td>$fecha</td>
          <td><span class="badge $badgeClass">$estadoText</span></td>
        </tr>
      ''');

      cards.write('''
        <div class="evidence-card">
          ${e.fotoUrl != null ? '<img class="evidence-image" src="${e.fotoUrl}" alt="Evidencia">' : '<div class="evidence-image" style="display:flex;align-items:center;justify-content:center;color:#888;">Sin imagen</div>'}
          <div class="evidence-content">
            <h3 class="evidence-title">Evidencia de ${e.nombreUsuario ?? 'Voluntario'}</h3>
            <p class="evidence-desc">${e.descripcion.isNotEmpty ? e.descripcion : 'Sin descripción registrada por el voluntario.'}</p>
            <div class="evidence-meta">
              <div class="meta-row">
                <span><strong>Fecha:</strong> $fecha</span>
                <span><strong>Estado:</strong> <span class="badge $badgeClass">$estadoText</span></span>
              </div>
              <div class="meta-row" style="margin-top: 6px;">
                <span><strong>Ubicación:</strong> $coords</span>
              </div>
            </div>
          </div>
        </div>
      ''');
    }

    return '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Ficha de Evidencias - ${widget.reporteTitulo}</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #333; margin: 40px; background-color: #f4f6f9; line-height: 1.6; }
        .header { text-align: center; margin-bottom: 40px; border-bottom: 3px solid #0056b3; padding-bottom: 20px; }
        .header h1 { margin: 0; color: #0056b3; font-size: 32px; font-weight: 700; }
        .header p { margin: 5px 0 0 0; color: #555; font-size: 14px; }
        .summary-table { width: 100%; border-collapse: collapse; margin-bottom: 40px; background: white; box-shadow: 0 4px 6px rgba(0,0,0,0.05); border-radius: 10px; overflow: hidden; }
        .summary-table th, .summary-table td { padding: 15px; text-align: left; border-bottom: 1px solid #eee; }
        .summary-table th { background-color: #0056b3; color: white; font-weight: 600; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px; }
        .summary-table tr:last-child td { border-bottom: none; }
        .badge { display: inline-block; padding: 6px 12px; border-radius: 20px; font-size: 11px; font-weight: bold; text-transform: uppercase; text-align: center; }
        .badge-approved { background-color: #e2f0d9; color: #385723; }
        .badge-pending { background-color: #fff2cc; color: #7f6000; }
        .badge-rejected { background-color: #fce4d6; color: #c65911; }
        .evidence-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 25px; margin-top: 20px; }
        .evidence-card { background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 6px 12px rgba(0,0,0,0.05); border: 1px solid #eef; display: flex; flex-direction: column; transition: transform 0.2s; }
        .evidence-image { width: 100%; height: 240px; object-fit: cover; background-color: #e9ecef; }
        .evidence-content { padding: 20px; flex-grow: 1; display: flex; flex-direction: column; }
        .evidence-title { font-weight: bold; font-size: 18px; margin: 0 0 10px 0; color: #222; }
        .evidence-desc { font-size: 14px; color: #555; margin-bottom: 20px; flex-grow: 1; }
        .evidence-meta { font-size: 12px; color: #777; border-top: 1px solid #f0f0f0; padding-top: 15px; margin-top: auto; }
        .meta-row { display: flex; justify-content: space-between; margin-bottom: 6px; }
        code { font-family: 'Courier New', Courier, monospace; background-color: #f8f9fa; padding: 2px 6px; border-radius: 4px; font-size: 12px; }
        @media print {
            body { background: white; margin: 0; }
            .evidence-card { break-inside: avoid; box-shadow: none; border: 1px solid #ccc; }
            .summary-table { box-shadow: none; border: 1px solid #ccc; }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Ficha de Evidencias del Operativo</h1>
        <p>Generado por Echoes el $fechaGen</p>
        <p><strong>Búsqueda:</strong> ${widget.reporteTitulo} | <strong>ID de Operativo:</strong> ${widget.reporteId}</p>
    </div>
    
    <h2 style="color: #333; border-bottom: 2px solid #ddd; padding-bottom: 10px; margin-bottom: 20px;">Resumen del Operativo</h2>
    <table class="summary-table">
        <thead>
            <tr>
                <th>Voluntario</th>
                <th>Descripción</th>
                <th>Coordenadas</th>
                <th>Fecha y Hora</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
            ${tableRows.toString()}
        </tbody>
    </table>
    
    <h2 style="color: #333; border-bottom: 2px solid #ddd; padding-bottom: 10px; margin-top: 40px; margin-bottom: 20px;">Detalle de Evidencias Fotográficas</h2>
    <div class="evidence-grid">
        ${cards.toString()}
    </div>
</body>
</html>
''';
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

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Evidencia?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _procesando = true);
    final vm = context.read<EvidenciaViewModel>();
    final ok = await vm.eliminarEvidencia(widget.evidencia.id, widget.reporteId);
    if (!mounted) return;
    setState(() => _procesando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Evidencia eliminada' : 'Error al eliminar evidencia'),
        backgroundColor: ok ? Colors.black87 : Colors.red.shade700,
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
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
                if (widget.evidencia.lat != null &&
                    widget.evidencia.lng != null)
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
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.1),
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
                // Acciones de Gestión de Evidencia (Aprobar/Rechazar/Eliminar siempre visibles)
                const SizedBox(height: 14),
                if (_procesando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          if (widget.evidencia.estado != 'rejected')
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _accion(false),
                                icon: Icon(Icons.close_rounded, color: Colors.red.shade700, size: 20),
                                label: Text('Rechazar',
                                    style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red.shade700,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          if (widget.evidencia.estado != 'rejected' && widget.evidencia.estado != 'approved')
                            const SizedBox(width: 12),
                          if (widget.evidencia.estado != 'approved')
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _accion(true),
                                icon: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                                label: const Text('Aprobar',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: AppTheme.success,
                                  elevation: 2,
                                  shadowColor: AppTheme.success.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _eliminar,
                          icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade600, size: 20),
                          label: Text('Eliminar Evidencia Definitivamente', 
                              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
