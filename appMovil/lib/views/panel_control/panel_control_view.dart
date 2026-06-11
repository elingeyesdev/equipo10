import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../viewmodels/panel_control_viewmodel.dart';
import '../../viewmodels/evidencia_viewmodel.dart';
import '../../widgets/map_tile_layer.dart';
import '../../widgets/lpp_marker.dart';
import '../../widgets/evidencia_marker.dart';
import '../../models/cuadrante_model.dart';
import '../../services/cuadrante_service.dart';
import '../../services/auth_service.dart';
import 'revision_evidencias_view.dart';
import '../widgets/full_screen_image_view.dart';
import '../widgets/encuesta_dialog.dart';
import '../../services/pdf_reporte_service.dart';
import '../../services/reporte_service.dart';
import '../reporte_pdf/reporte_pdf_preview.dart';

class PanelControlView extends StatefulWidget {
  final String fichaId;

  const PanelControlView({super.key, required this.fichaId});

  @override
  State<PanelControlView> createState() => _PanelControlViewState();
}

class _PanelControlViewState extends State<PanelControlView> {
  final MapController _mapController = MapController();
  final CuadranteService _cuadranteService = CuadranteService();
  bool _useSatellite = true;

  List<Polygon> _cuadrantesPolygons = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<PanelControlViewModel>();
      vm.cargarDatos(widget.fichaId);
      vm.iniciarPolling(widget.fichaId);
      context
          .read<EvidenciaViewModel>()
          .cargarEvidencias(widget.fichaId, esCreador: true);
    });
    _cargarCuadrantes();
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

  @override
  void dispose() {
    _mapController.dispose();
    // Detener polling si la vista se destruye
    context.read<PanelControlViewModel>().detenerPolling();
    super.dispose();
  }

  Future<void> _cambiarEstado(BuildContext context, String nuevoEstado) async {
    final vm = context.read<PanelControlViewModel>();
    String? justificacion;

    if (nuevoEstado == 'pausado' || nuevoEstado == 'cerrado') {
      justificacion = await _mostrarDialogoJustificacion(context, nuevoEstado);
      if (justificacion == null) return; // Canceló el diálogo
    } else {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar Reanudación'),
          content: const Text(
              '¿Deseas volver a poner la búsqueda en estado Activa? Los voluntarios podrán unirse nuevamente.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20)),
              child: const Text('Reanudar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    final success = await vm.cambiarEstado(widget.fichaId, nuevoEstado,
        justificacion: justificacion);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Búsqueda cambiada a $nuevoEstado exitosamente.'),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
      // Mostrar encuesta de satisfacción al finalizar la búsqueda
      if ((nuevoEstado == 'cerrado' || nuevoEstado == 'resuelto') &&
          mounted &&
          vm.ficha != null) {
        final userId = AuthService().currentUserId ?? '';
        await EncuestaDialog.show(context, vm.ficha!, userId,
            isCoordinador: true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Error al actualizar el estado.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<String?> _mostrarDialogoJustificacion(
      BuildContext context, String nuevoEstado) {
    final TextEditingController ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String actionTitle = nuevoEstado == 'cerrado' ? 'Finalizar' : 'Pausar';
        return AlertDialog(
          title: Text('$actionTitle Búsqueda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Por favor, indica la justificación o razón para $actionTitle esta búsqueda.'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Escribe la justificación aquí...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('La justificación es obligatoria.')),
                  );
                } else {
                  Navigator.pop(ctx, ctrl.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: nuevoEstado == 'cerrado'
                    ? Colors.red
                    : const Color(0xFFFF9800),
              ),
              child: Text(actionTitle),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoAlertaMasiva(BuildContext context) async {
    final vm = context.read<PanelControlViewModel>();
    final TextEditingController ctrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Text('Alerta Masiva'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Este mensaje será enviado a todos los voluntarios que estén buscando o esperando en este momento.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Ej: Atención equipo, concentremos la búsqueda en la zona norte del cuadrante...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx); // Cerrar diálogo

              final success =
                  await vm.enviarAlertaMasiva(widget.fichaId, ctrl.text.trim());
              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Alerta masiva enviada con éxito!'),
                    backgroundColor: Color(0xFF1B5E20),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(vm.errorMessage ?? 'Error al enviar alerta.'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20)),
            child: const Text('Enviar Alerta'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoMensajeDirecto(
    BuildContext context,
    String usuarioId,
    String nombreVoluntario,
    String? estadoBusqueda,
  ) async {
    final vm = context.read<PanelControlViewModel>();
    final TextEditingController ctrl = TextEditingController();

    String estadoTxt = 'Desconocido';
    Color estadoColor = Colors.grey;
    if (estadoBusqueda == 'buscando') {
      estadoTxt = 'En Búsqueda';
      estadoColor = Colors.green;
    } else if (estadoBusqueda == 'esperando') {
      estadoTxt = 'En Espera';
      estadoColor = Colors.orange;
    } else if (estadoBusqueda == 'inactivo') {
      estadoTxt = 'Inactivo / Finalizado';
      estadoColor = Colors.grey;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.message, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Expanded(
                child:
                    Text('Mensaje Directo', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para: $nombreVoluntario',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Estado: ',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: estadoColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      estadoTxt,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Este mensaje será enviado únicamente a este voluntario.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Escribe el mensaje aquí...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);

              final success = await vm.enviarMensajeDirecto(
                  widget.fichaId, usuarioId, ctrl.text.trim());
              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mensaje enviado con éxito'),
                    backgroundColor: Color(0xFF1B5E20),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(vm.errorMessage ?? 'Error al enviar mensaje.'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20)),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PanelControlViewModel>();

    if (vm.isLoading && vm.ficha == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (vm.ficha == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel de Control')),
        body: const Center(child: Text('Búsqueda no encontrada.')),
      );
    }

    final ficha = vm.ficha!;
    final bool isActive = ficha.estado == 'activo';
    final bool isClosed =
        ficha.estado == 'cerrado' || ficha.estado == 'resuelto';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Comando'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'General'),
              Tab(icon: Icon(Icons.map), text: 'Mapa de Cobertura'),
              Tab(icon: Icon(Icons.photo_library), text: 'Galería'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          physics:
              const NeverScrollableScrollPhysics(), // Evita conflicto con gestos del mapa
          children: [
            _buildTabGeneral(context, vm, ficha, isActive),
            _buildTabMapa(vm, ficha),
            _buildTabGaleria(vm, widget.fichaId),
          ],
        ),
        floatingActionButton: isClosed
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _mostrarDialogoAlertaMasiva(context),
                backgroundColor: const Color(0xFF0277BD),
                icon: const Icon(Icons.campaign, color: Colors.white),
                label: const Text('Alerta Masiva',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
      ),
    );
  }

  Widget _buildTabGeneral(BuildContext context, PanelControlViewModel vm,
      dynamic ficha, bool isActive) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de la Ficha
          Text(
            ficha.titulo,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _EstadoBadge(estado: ficha.estado),
          if (ficha.justificacion != null &&
              ficha.justificacion!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                border: Border.all(color: const Color(0xFFBDBDBD)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Justificación / Resolución:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5F6368))),
                  const SizedBox(height: 4),
                  Text(ficha.justificacion!),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Acciones Rápidas',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isActive)
                Expanded(
                    child: _buildActionButton(
                  label: 'Reanudar',
                  icon: Icons.play_arrow_rounded,
                  color: const Color(0xFF166534),
                  shadowColor: const Color(0x3316653A),
                  onPressed: vm.isChangingState
                      ? null
                      : () => _cambiarEstado(context, 'activo'),
                  isLoading: vm.isChangingState,
                ))
              else
                Expanded(
                    child: _buildActionButton(
                  label: 'Pausar',
                  icon: Icons.pause_rounded,
                  color: const Color(0xFF92400E),
                  shadowColor: const Color(0x3392400E),
                  onPressed: vm.isChangingState
                      ? null
                      : () => _cambiarEstado(context, 'pausado'),
                  isLoading: vm.isChangingState,
                )),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildActionButton(
                label: 'Finalizar',
                icon: Icons.flag_rounded,
                color: const Color(0xFF7F1D1D),
                shadowColor: const Color(0x337F1D1D),
                onPressed: vm.isChangingState ||
                        ficha.estado == 'cerrado' ||
                        ficha.estado == 'resuelto'
                    ? null
                    : () => _cambiarEstado(context, 'cerrado'),
                isLoading: vm.isChangingState,
              )),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Boton de revision de evidencias
          _buildBotonRevisionEvidencias(context, vm),

          const SizedBox(height: 16),

          // Botón de generar reporte PDF
          _buildBotonGenerarPDF(context, vm),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Lista de voluntarios
          Row(
            children: [
              const Icon(Icons.people, color: Color(0xFF1B5E20)),
              const SizedBox(width: 8),
              Text(
                'Voluntarios (${vm.voluntarios.length})',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (vm.voluntarios.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Aún no hay voluntarios en esta búsqueda.',
                    style: TextStyle(color: Color(0xFF757575))),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.voluntarios.length,
              itemBuilder: (context, index) {
                final v = vm.voluntarios[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Text(
                      v.nombreCompleto.isNotEmpty
                          ? v.nombreCompleto[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Color(0xFF1B5E20)),
                    ),
                  ),
                  title: Text(v.nombreCompleto.isNotEmpty
                      ? v.nombreCompleto
                      : 'Sin Nombre'),
                  subtitle:
                      Text(v.telefono.isNotEmpty ? v.telefono : 'Sin teléfono'),
                  trailing: IconButton(
                    icon: const Icon(Icons.message, color: Color(0xFF1B5E20)),
                    onPressed: () {
                      // Buscar el estado de este voluntario en las rutas
                      final ruta = vm.rutasVoluntarios
                          .where((r) => r.usuarioId == v.id)
                          .firstOrNull;
                      _mostrarDialogoMensajeDirecto(context, v.id,
                          v.nombreCompleto, ruta?.estadoBusqueda);
                    },
                    tooltip: 'Enviar mensaje directo',
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Botón de acción primaria con color sólido oscuro y sombra suave.
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color shadowColor,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    final isDisabled = onPressed == null;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: isDisabled ? const Color(0xFFD1D5DB) : color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                else
                  Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isDisabled ? const Color(0xFF6B7280) : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotonRevisionEvidencias(
      BuildContext context, PanelControlViewModel vm) {
    final evVm = context.watch<EvidenciaViewModel>();
    final pendingCount =
        evVm.evidencias.where((e) => e.estado == 'pending').length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RevisionEvidenciasView(
                  reporteId: widget.fichaId,
                  reporteTitulo: vm.ficha?.titulo ?? 'Búsqueda',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rate_review_outlined,
                    color: Color(0xFFB8860B),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revisión de Evidencias',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202124),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pendingCount > 0
                            ? '$pendingCount evidencia(s) esperando revisión'
                            : 'Ver todas las evidencias enviadas',
                        style: TextStyle(
                          fontSize: 13,
                          color: pendingCount > 0
                              ? const Color(0xFFD32F2F)
                              : const Color(0xFF5F6368),
                          fontWeight: pendingCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pendingCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF5F6368),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Botón Generar Reporte PDF ────────────────────────────────────────────
  Widget _buildBotonGenerarPDF(BuildContext context, PanelControlViewModel vm) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3F7AC5), Color(0xFF2D5A9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F7AC5).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _generarReportePDF(context, vm),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generar Reporte PDF',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Requiere conexión a internet para renderizar los mapas satelitales',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Genera el reporte PDF mostrando un diálogo de progreso con porcentaje real.
  Future<void> _generarReportePDF(
      BuildContext context, PanelControlViewModel vm) async {
    if (vm.ficha == null) return;
    final ficha = vm.ficha!;

    // Notificador de progreso con estado enriquecido
    final progressNotifier = ValueNotifier<_PdfProgreso>(const _PdfProgreso(
      icono: Icons.map_rounded,
      titulo: 'Capturando mapa',
      mensaje: 'Generando snapshot del mapa de ruta...',
      porcentaje: 0.03,
      color: Color(0xFF16A34A),
      esError: false,
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoProgresoPDF(progresoNotifier: progressNotifier),
    );

    // Helper para actualizar el notificador con estado predefinido
    void actualizarPaso(String paso, String mensaje, double porcentaje) {
      final (icono, titulo, color) = switch (paso) {
        'mapa' => (
            Icons.map_rounded,
            'Capturando mapa',
            const Color(0xFF16A34A)
          ),
        'recopilando' => (
            Icons.cloud_download_rounded,
            'Recopilando datos',
            const Color(0xFF3F7AC5)
          ),
        'imagenes' => (
            Icons.photo_library_rounded,
            'Optimizando imágenes',
            const Color(0xFF8B5CF6)
          ),
        'ensamblando' => (
            Icons.picture_as_pdf_rounded,
            'Generando PDF',
            const Color(0xFF3F7AC5)
          ),
        'error' => (
            Icons.error_outline_rounded,
            'Error',
            const Color(0xFFEF4444)
          ),
        _ => (
            Icons.hourglass_top_rounded,
            'Procesando',
            const Color(0xFF3F7AC5)
          ),
      };
      progressNotifier.value = _PdfProgreso(
        icono: icono,
        titulo: titulo,
        mensaje: mensaje,
        porcentaje: porcentaje,
        color: color,
        esError: paso == 'error',
      );
    }

    try {
      // Paso 1: Capturar snapshot del mapa (3%)
      final evVm = context.read<EvidenciaViewModel>();

      // Construir listas de coordenadas para los mapas estáticos
      final List<LatLng> cuadranteCoords = ficha.cuadranteLatMin != null
          ? [
              LatLng(ficha.cuadranteLatMax!, ficha.cuadranteLngMin!),
              LatLng(ficha.cuadranteLatMax!, ficha.cuadranteLngMax!),
              LatLng(ficha.cuadranteLatMin!, ficha.cuadranteLngMax!),
              LatLng(ficha.cuadranteLatMin!, ficha.cuadranteLngMin!),
            ]
          : [];

      final List<List<LatLng>> rutasCoords = vm.rutasVoluntarios
          .where((r) => r.puntos.isNotEmpty)
          .map((r) => r.puntos)
          .toList();

      Map<String, dynamic> datos;
      try {
        datos = await ReporteService().obtenerDatosReporteFinal(ficha.id);
        actualizarPaso('recopilando', 'Datos del operativo obtenidos', 0.15);
      } catch (_) {
        actualizarPaso(
            'recopilando', 'Usando datos locales del operativo...', 0.12);
        datos = {
          'id': ficha.id,
          'titulo': ficha.titulo,
          'descripcion': ficha.descripcion,
          'estado': ficha.estado,
          'categoria': ficha.nombreCategoria,
          'fecha_reporte': ficha.createdAt?.toIso8601String(),
          'fecha_perdida': ficha.fechaPerdida,
          'cuadrante_nombre': ficha.cuadranteNombre,
          'cuadrante_zona': ficha.cuadranteZona,
          'latitud': ficha.latitud,
          'longitud': ficha.longitud,
          'telefono_contacto': ficha.telefonoContacto,
          'email_contacto': ficha.emailContacto,
          'direccion_referencia': ficha.direccionReferencia,
          'recompensa': ficha.recompensa,
          'nivel_expansion': ficha.nivelExpansion,
          'max_expansion': 10,
          'primera_imagen': ficha.primeraImagen,
          'evidencias': evVm.evidencias
              .map((e) => {
                    'foto_url': e.fotoUrl,
                    'descripcion': e.descripcion,
                    'estado': e.estado,
                    'lat': e.lat,
                    'lng': e.lng,
                    'created_at': null,
                  })
              .toList(),
          'caracteristicas': {
            'Está esterilizado?': 'Sí',
            'Tenía collar?': 'No',
            'Color': 'Blanco con manchas negras',
          },
          'estadisticas': {
            'total_voluntarios': vm.voluntarios.length,
            'total_evidencias': evVm.evidencias.length,
            'evidencias_aprobadas':
                evVm.evidencias.where((e) => e.estado == 'approved').length,
            'evidencias_rechazadas':
                evVm.evidencias.where((e) => e.estado == 'rejected').length,
            'cuadrantes_expandidos': ficha.nivelExpansion,
            'tiempo_total_minutos': ficha.createdAt != null
                ? DateTime.now().difference(ficha.createdAt!).inMinutes
                : 0,
            'tiempo_activo_minutos': 0,
            'distancia_total_km': 0.0,
          },
        };
      }

      // Inyectar las coordenadas en los datos para que el servicio PDF genere los mapas estáticos

      // Inyectar datos simulados de recorridos (zigzag y espiral) si no hay rutas reales
      if (rutasCoords.isEmpty &&
          ficha.latitud != null &&
          ficha.longitud != null) {
        final lLat = ficha.latitud!;
        final lLng = ficha.longitud!;
        // Ruta 1: Zigzag
        rutasCoords.add([
          LatLng(lLat, lLng),
          LatLng(lLat + 0.001, lLng + 0.001),
          LatLng(lLat + 0.002, lLng - 0.001),
          LatLng(lLat + 0.003, lLng + 0.002),
          LatLng(lLat + 0.004, lLng - 0.002),
        ]);
        // Ruta 2: Espiral
        rutasCoords.add([
          LatLng(lLat, lLng),
          LatLng(lLat - 0.001, lLng),
          LatLng(lLat - 0.001, lLng + 0.001),
          LatLng(lLat - 0.002, lLng + 0.001),
          LatLng(lLat - 0.002, lLng - 0.001),
          LatLng(lLat - 0.003, lLng - 0.001),
          LatLng(lLat - 0.003, lLng + 0.002),
        ]);
      }

      datos['mapa_rutas'] = rutasCoords;
      datos['mapa_cuadrante'] = cuadranteCoords;

      // Paso 3: Generar el PDF con callback de progreso en tiempo real (15% - 95%)
      actualizarPaso(
          'imagenes', 'Descargando evidencias fotográficas...', 0.15);
      final pdfBytes = await PdfReporteService().generarReportePDF(
        datos: datos,
        onProgress: (paso, mensaje, porcentaje) {
          final escalado = 0.15 + (porcentaje * 0.80);
          actualizarPaso(paso, mensaje, escalado.clamp(0.0, 0.95));
        },
      );

      // Completado (100%)
      actualizarPaso('ensamblando', '¡Reporte generado exitosamente!', 1.0);
      await Future.delayed(const Duration(milliseconds: 400));

      // Cerrar diálogo de progreso
      if (context.mounted) Navigator.of(context).pop();

      // Navegar al preview del PDF
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportePdfPreview(
              tituloOperativo: ficha.titulo,
              pdfBytes: pdfBytes,
            ),
          ),
        );
      }
    } catch (e) {
      actualizarPaso('error',
          'Ocurrió un error al generar el reporte.\nIntenta de nuevo.', 0.0);
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar el reporte: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      progressNotifier.dispose();
    }
  }

  Widget _buildTabMapa(PanelControlViewModel vm, dynamic ficha) {
    LatLng? center;

    // Calcular el centro del mapa (Prioridad: LPP > Cuadrante > Recorridos)
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

    // Colores para diferenciar voluntarios (heat map simple)
    final List<Color> pathColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal
    ];

    // Combinar el LPP original con las pistas adicionales
    final List<Marker> markersPistas = [];

    // 1. Agregar el punto original (LPP)
    if (ficha.latitud != null && ficha.longitud != null) {
      markersPistas.add(Marker(
        point: LatLng(ficha.latitud!, ficha.longitud!),
        width: 80,
        height: 70,
        alignment: Alignment.center,
        child: LppMarker(
          fotoUrl: ficha.fotoUrl,
          nombre: 'Visto por última vez',
          color: const Color(0xFFD32F2F), // Rojo para el LPP
        ),
      ));
    }

    // 2. Agregar las evidencias fotograficas capturadas (solo approved)
    final evVm = context.read<EvidenciaViewModel>();
    final evidenciasAprobadas =
        evVm.evidencias.where((e) => e.estado == 'approved').toList();
    markersPistas.addAll(evidenciasAprobadas
        .where((e) => e.lat != null && e.lng != null)
        .map((evidencia) {
      return Marker(
        point: LatLng(evidencia.lat!, evidencia.lng!),
        width: 80,
        height: 70,
        alignment: Alignment.center,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Future.delayed(const Duration(milliseconds: 150), () {
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
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: evidencia.fotoUrl!,
                                    height: 150,
                                    width: 300,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        size: 50),
                                    placeholder: (_, __) => Container(
                                      height: 150,
                                      width: 300,
                                      color: const Color(0xFFF5F5F5),
                                      child: const Center(
                                          child: CircularProgressIndicator()),
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
            nombreVoluntario: evidencia.nombreUsuario ?? 'Evidencia',
          ),
        ),
      );
    }));

    // 2. Agregar el resto de pistas — puntos ámbar simples
    markersPistas.addAll(vm.pistas.map((pista) {
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
            // Cuadrícula completa de cuadrantes + zona verde del LPP
            if (_cuadrantesPolygons.isNotEmpty)
              PolygonLayer(polygons: _cuadrantesPolygons),
            // Zona de expansión verde del LPP (nivel dinámico)
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
                  // Zonas de expansión de pistas del vm
                  ...vm.pistas.map((p) {
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
                  }),
                ];
              }()),
            // Recorridos de voluntarios
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
            // Marcadores de posición actual de voluntarios
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
                        _mostrarDialogoMensajeDirecto(context, ruta.usuarioId!,
                            ruta.nombre, ruta.estadoBusqueda);
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
            // Marcadores de pistas y LPP
            MarkerLayer(
              markers: markersPistas,
            ),
          ],
        ),
        // Filtro de Voluntarios en la parte superior
        if (vm.todasLasRutas.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: vm.filtroNombreVoluntario == null,
                      onSelected: (selected) {
                        if (selected) vm.setFiltroVoluntario(null);
                      },
                      selectedColor: const Color(0xFF1B5E20).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF1B5E20),
                    ),
                  ),
                  ...vm.todasLasRutas.map((ruta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(ruta.nombre),
                        selected: vm.filtroNombreVoluntario == ruta.nombre,
                        onSelected: (selected) {
                          if (selected) {
                            vm.setFiltroVoluntario(ruta.nombre);
                            // Opcional: Centrar la cámara en el último punto del voluntario seleccionado
                            if (ruta.puntos.isNotEmpty) {
                              _mapController.move(ruta.puntos.last, 16.0);
                            }
                          } else {
                            vm.setFiltroVoluntario(null);
                          }
                        },
                        selectedColor: const Color(0xFF1B5E20).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF1B5E20),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        // Toggle de capas (satelital / callejero)
        Positioned(
          bottom: 56,
          right: 60,
          child: MapLayerToggleButton(
            heroTag: null,
            useSatellite: _useSatellite,
            onToggle: () => setState(() => _useSatellite = !_useSatellite),
          ),
        ),
        // Botón de centrado dinámico en LPP
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'btn_centrar_panel',
            mini: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1B5E20),
            onPressed: () {
              _mapController.move(center!, 15.0);
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  Widget _buildLeyendaItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTabGaleria(PanelControlViewModel vm, String fichaId) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.galeria.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay imágenes en la galería aún.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: vm.galeria.length,
      itemBuilder: (context, index) {
        final img = vm.galeria[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageView(
                  imageUrl: img['url'],
                  title: img['tipo'] == 'original'
                      ? 'Imagen del Reporte'
                      : 'Evidencia Aprobada',
                  subtitle: '${img['autor'] ?? ''}',
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: img['url'],
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.broken_image, color: Colors.grey)),
                  placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator())),
                ),
              ),
              if (img['tipo'] == 'original')
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;

    if (estado == 'activo') {
      bg = const Color(0xFFE8F5E9);
      border = const Color(0xFF4CAF50);
    } else if (estado == 'pausado') {
      bg = const Color(0xFFFFF3E0);
      border = const Color(0xFFFF9800);
    } else {
      bg = const Color(0xFFFFEBEE);
      border = const Color(0xFFF44336);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.toUpperCase(),
        style:
            TextStyle(color: border, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Enum de pasos de generación del PDF
// ────────────────────────────────────────────────────────────────────────────

// ────────────────────────────────────────────────────────────────────────────
// Estado de progreso del PDF (E13.3 – reemplaza enum _PdfStep)
// ────────────────────────────────────────────────────────────────────────────

/// Estado inmutable que describe el progreso actual de la generación del PDF.
class _PdfProgreso {
  final IconData icono;
  final String titulo;
  final String mensaje;

  /// Porcentaje de avance (0.0 – 1.0)
  final double porcentaje;
  final Color color;
  final bool esError;

  const _PdfProgreso({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    required this.porcentaje,
    required this.color,
    required this.esError,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// Diálogo de progreso animado con barra de porcentaje real (E13.3)
// ────────────────────────────────────────────────────────────────────────────

class _DialogoProgresoPDF extends StatelessWidget {
  final ValueNotifier<_PdfProgreso> progresoNotifier;

  const _DialogoProgresoPDF({required this.progresoNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_PdfProgreso>(
      valueListenable: progresoNotifier,
      builder: (context, progreso, _) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono animado con indicador circular
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: progreso.esError
                      ? Icon(
                          Icons.error_outline_rounded,
                          size: 56,
                          color: const Color(0xFFEF4444),
                          key: const ValueKey('error_icon'),
                        )
                      : progreso.porcentaje >= 1.0
                          ? Icon(
                              Icons.check_circle_rounded,
                              size: 56,
                              color: const Color(0xFF16A34A),
                              key: const ValueKey('done_icon'),
                            )
                          : SizedBox(
                              width: 56,
                              height: 56,
                              key: ValueKey(progreso.titulo),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: progreso.porcentaje < 0.05
                                        ? null // indeterminado al inicio
                                        : progreso.porcentaje,
                                    color: progreso.color,
                                    strokeWidth: 3.5,
                                    backgroundColor:
                                        progreso.color.withValues(alpha: 0.15),
                                  ),
                                  Icon(progreso.icono,
                                      size: 26, color: progreso.color),
                                ],
                              ),
                            ),
                ),
                const SizedBox(height: 20),

                // Título del paso
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    progreso.esError ? 'Error al generar' : progreso.titulo,
                    key: ValueKey(progreso.titulo),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF353F4C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),

                // Mensaje descriptivo
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    progreso.mensaje,
                    key: ValueKey(progreso.mensaje),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF3F4B5B),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Barra de progreso con porcentaje
                if (!progreso.esError) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progreso.porcentaje),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (ctx, value, _) => LinearProgressIndicator(
                        value: value < 0.03 ? null : value,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE8EFF8),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progreso.porcentaje >= 1.0
                              ? const Color(0xFF16A34A)
                              : progreso.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        progreso.porcentaje >= 1.0
                            ? '¡Listo!'
                            : 'Procesando...',
                        style: TextStyle(
                          fontSize: 11,
                          color: progreso.porcentaje >= 1.0
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween:
                            Tween<double>(begin: 0, end: progreso.porcentaje),
                        duration: const Duration(milliseconds: 400),
                        builder: (ctx, value, _) => Text(
                          '${(value * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: progreso.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
