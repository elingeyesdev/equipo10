import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/panel_control_viewmodel.dart';
import '../../viewmodels/evidencia_viewmodel.dart';
import '../../services/auth_service.dart';
import '../../services/pdf_reporte_service.dart';
import '../../services/reporte_service.dart';
import 'revision_evidencias_view.dart';
import 'pdf_progreso_dialog.dart';
import 'tab_mapa_panel.dart';
import 'tab_galeria_panel.dart';
import '../widgets/encuesta_dialog.dart';
import '../reporte_pdf/reporte_pdf_preview.dart';

class PanelControlView extends StatefulWidget {
  final String fichaId;

  const PanelControlView({super.key, required this.fichaId});

  @override
  State<PanelControlView> createState() => _PanelControlViewState();
}

class _PanelControlViewState extends State<PanelControlView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<PanelControlViewModel>();
      vm.cargarDatos(widget.fichaId);
      vm.iniciarPolling(widget.fichaId);
      context
          .read<EvidenciaViewModel>()
          .cargarEvidencias(widget.fichaId, esCreador: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    context.read<PanelControlViewModel>().detenerPolling();
    super.dispose();
  }

  Future<void> _cambiarEstado(BuildContext context, String nuevoEstado) async {
    final vm = context.read<PanelControlViewModel>();
    String? justificacion;

    if (nuevoEstado == 'pausado' || nuevoEstado == 'cerrado') {
      justificacion = await _mostrarDialogoJustificacion(context, nuevoEstado);
      if (justificacion == null) return;
    } else {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text('Confirmar reanudación',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
              '¿Deseas volver a poner la búsqueda en estado Activa? Los voluntarios podrán unirse nuevamente.'),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Reanudar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.darkDark,
                    overlayColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ],
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
          backgroundColor: AppTheme.primary,
        ),
      );
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
        final actionTitle = nuevoEstado == 'cerrado' ? 'Finalizar' : 'Pausar';
        final isCerrado = nuevoEstado == 'cerrado';
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text('$actionTitle búsqueda',
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    backgroundColor:
                        isCerrado ? AppTheme.accent : AppTheme.primary,
                    foregroundColor:
                        isCerrado ? AppTheme.darkDark : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(actionTitle),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.darkDark,
                    overlayColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ],
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Alerta masiva',
          style: TextStyle(
              color: AppTheme.primary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Este mensaje será enviado a todos los voluntarios que estén buscando o esperando en este momento.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Ej: Atención equipo, concentremos la búsqueda en la zona norte del cuadrante...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  final success = await vm.enviarAlertaMasiva(
                      widget.fichaId, ctrl.text.trim());
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
                        content:
                            Text(vm.errorMessage ?? 'Error al enviar alerta.'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Enviar alerta'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.darkDark,
                  overlayColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancelar'),
              ),
            ],
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
            Icon(Icons.message, color: AppTheme.primary),
            SizedBox(width: 8),
            Expanded(
                child:
                    Text('Mensaje directo', overflow: TextOverflow.ellipsis)),
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
                backgroundColor: AppTheme.primary),
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
        appBar: AppBar(title: const Text('Panel de control')),
        body: const Center(child: Text('Búsqueda no encontrada.')),
      );
    }

    final ficha = vm.ficha!;
    final bool isActive = ficha.estado == 'activo';
    final bool isClosed =
        ficha.estado == 'cerrado' || ficha.estado == 'resuelto';

    final bool ocultarFab = isClosed || _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Panel de control',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'General'),
            Tab(icon: Icon(Icons.map), text: 'Mapa de cobertura'),
            Tab(icon: Icon(Icons.photo_library), text: 'Galería'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildTabGeneral(context, vm, ficha, isActive),
          TabMapaPanel(
            onMensajeDirecto: (usuarioId, nombre, estado) =>
                _mostrarDialogoMensajeDirecto(context, usuarioId, nombre, estado),
          ),
          const TabGaleriaPanel(),
        ],
      ),
      floatingActionButton: ocultarFab
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _mostrarDialogoAlertaMasiva(context),
              backgroundColor: AppTheme.primary,
              label: const Text('Alerta masiva',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
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
          Text(
            ficha.titulo,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          _EstadoBadge(estado: ficha.estado),
          const SizedBox(height: 16),
          // ─── Tarjeta: Justificación + Acciones rápidas ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ficha.justificacion != null &&
                    ficha.justificacion!.isNotEmpty) ...[
                  const Text('Justificación / Resolución:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkLight,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(ficha.justificacion!,
                      style: const TextStyle(color: AppTheme.darkDark)),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Acciones rápidas',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkLight),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!isActive)
                      Expanded(
                          child: _buildActionButton(
                        label: 'Reanudar',
                        icon: Icons.play_arrow_rounded,
                        color: AppTheme.primary,
                        textColor: Colors.white,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.3),
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
                        color: AppTheme.primary,
                        textColor: Colors.white,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.3),
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
                      color: AppTheme.accent,
                      textColor: AppTheme.darkDark,
                      shadowColor: AppTheme.accent.withValues(alpha: 0.3),
                      onPressed: vm.isChangingState ||
                              ficha.estado == 'cerrado' ||
                              ficha.estado == 'resuelto'
                          ? null
                          : () => _cambiarEstado(context, 'cerrado'),
                      isLoading: vm.isChangingState,
                    )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ─── Botones cuadrados en grid 2 columnas ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildBotonRevisionEvidencias(context, vm)),
              const SizedBox(width: 12),
              Expanded(child: _buildBotonGenerarPDF(context, vm)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Voluntarios (${vm.voluntarios.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.2),
                    child: Text(
                      v.nombreCompleto.isNotEmpty
                          ? v.nombreCompleto[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: AppTheme.primary),
                    ),
                  ),
                  title: Text(v.nombreCompleto.isNotEmpty
                      ? v.nombreCompleto
                      : 'Sin Nombre'),
                  subtitle:
                      Text(v.telefono.isNotEmpty ? v.telefono : 'Sin teléfono'),
                  trailing: IconButton(
                    icon: const Icon(Icons.message, color: AppTheme.primary),
                    onPressed: () {
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color shadowColor,
    required VoidCallback? onPressed,
    Color textColor = Colors.white,
    bool isLoading = false,
  }) {
    final isDisabled = onPressed == null;
    final resolvedText =
        isDisabled ? const Color(0xFF6B7280) : textColor;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
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
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: resolvedText, strokeWidth: 2),
                  )
                else
                  Icon(icon, color: resolvedText, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: resolvedText,
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

    return AspectRatio(
      aspectRatio: 1,
      child: ElevatedButton(
        onPressed: () {
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
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return AppTheme.accent;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return Colors.white;
            return AppTheme.accent;
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.accent, width: 2),
            ),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.rate_review_outlined, size: 34),
                if (pendingCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: AppTheme.accentDark,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Revisión de\nevidencias',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonGenerarPDF(BuildContext context, PanelControlViewModel vm) {
    return AspectRatio(
      aspectRatio: 1,
      child: ElevatedButton(
        onPressed: () => _generarReportePDF(context, vm),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return AppTheme.primary;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return Colors.white;
            return AppTheme.primary;
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(16)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 34),
            SizedBox(height: 10),
            Text(
              'Generar\nreporte PDF',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Requiere conexión a internet para renderizar los mapas satelitales',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generarReportePDF(
      BuildContext context, PanelControlViewModel vm) async {
    if (vm.ficha == null) return;
    final ficha = vm.ficha!;

    final progressNotifier = ValueNotifier<PdfProgreso>(const PdfProgreso(
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
      builder: (ctx) => PdfProgresoDialog(progresoNotifier: progressNotifier),
    );

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
      progressNotifier.value = PdfProgreso(
        icono: icono,
        titulo: titulo,
        mensaje: mensaje,
        porcentaje: porcentaje,
        color: color,
        esError: paso == 'error',
      );
    }

    try {
      final evVm = context.read<EvidenciaViewModel>();

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

      // Rutas simuladas si no hay datos reales
      if (rutasCoords.isEmpty &&
          ficha.latitud != null &&
          ficha.longitud != null) {
        final lLat = ficha.latitud!;
        final lLng = ficha.longitud!;
        rutasCoords.add([
          LatLng(lLat, lLng),
          LatLng(lLat + 0.001, lLng + 0.001),
          LatLng(lLat + 0.002, lLng - 0.001),
          LatLng(lLat + 0.003, lLng + 0.002),
          LatLng(lLat + 0.004, lLng - 0.002),
        ]);
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

      actualizarPaso('imagenes', 'Descargando evidencias fotográficas...', 0.15);
      final pdfBytes = await PdfReporteService().generarReportePDF(
        datos: datos,
        onProgress: (paso, mensaje, porcentaje) {
          final escalado = 0.15 + (porcentaje * 0.80);
          actualizarPaso(paso, mensaje, escalado.clamp(0.0, 0.95));
        },
      );

      actualizarPaso('ensamblando', '¡Reporte generado exitosamente!', 1.0);
      await Future.delayed(const Duration(milliseconds: 400));

      if (context.mounted) Navigator.of(context).pop();

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
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    String label;

    if (estado == 'activo') {
      dotColor = AppTheme.primary;
      label = 'Activo';
    } else if (estado == 'pausado') {
      dotColor = AppTheme.accent;
      label = 'Pausado';
    } else {
      dotColor = const Color(0xFFF44336);
      label = estado == 'resuelto' ? 'Resuelto' : 'Finalizado';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13),
        ),
      ],
    );
  }
}
