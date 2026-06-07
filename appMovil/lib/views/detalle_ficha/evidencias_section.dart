import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/evidencia_model.dart';
import '../../models/evidencia_offline_model.dart';
import '../../viewmodels/evidencia_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../widgets/full_screen_image_view.dart';

/// Sección completa de evidencias fotográficas para usar dentro del
/// detalle de un reporte. Muestra la galería de evidencias y el botón
/// para capturar una nueva.
class EvidenciasSection extends StatefulWidget {
  final String reporteId;
  final String usuarioId;
  final bool puedePublicar;
  final bool esCreador;

  const EvidenciasSection({
    super.key,
    required this.reporteId,
    required this.usuarioId,
    required this.puedePublicar,
    this.esCreador = false,
  });

  @override
  State<EvidenciasSection> createState() => _EvidenciasSectionState();
}

class _EvidenciasSectionState extends State<EvidenciasSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<EvidenciaViewModel>()
          .cargarEvidencias(widget.reporteId, esCreador: widget.esCreador);
    });
  }

  Future<void> _onAgregarEvidencia() async {
    final vm = context.read<EvidenciaViewModel>();

    final fuente = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'Agregar evidencia fotográfica',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppTheme.primary),
                ),
                title: const Text('Tomar foto ahora',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Abre la cámara del dispositivo'),
                onTap: () => Navigator.of(ctx).pop('camara'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: AppTheme.info),
                ),
                title: const Text('Elegir de galería',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Selecciona una foto existente'),
                onTap: () => Navigator.of(ctx).pop('galeria'),
              ),
            ],
          ),
        ),
      ),
    );

    if (fuente == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    bool capturo = false;
    if (fuente == 'camara') {
      capturo = await vm.capturarFoto();
    } else {
      capturo = await vm.seleccionarDeGaleria();
    }

    if (mounted) {
      Navigator.of(context).pop(); // Cerrar el diálogo de carga
    }

    if (!capturo || !mounted) return;

    // Navigate to the form as a full page route (NOT a bottom sheet).
    // This completely avoids Overlay entry conflicts because the new route
    // owns its own isolated Overlay scope.
    final bytes = vm.bytesPreview != null ? Uint8List.fromList(vm.bytesPreview!) : null;
    final descripcion = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PublicarEvidenciaPage(
          bytesPreview: bytes,
          tienePosicion: vm.tienePosicion,
          latitud: vm.latTemporal,
          longitud: vm.lngTemporal,
        ),
      ),
    );

    if (descripcion == null || descripcion.isEmpty || !mounted) return;

    // The route is now fully gone from the Overlay — safe to call async work.
    final ok = await vm.publicarEvidencia(
      reporteId: widget.reporteId,
      usuarioId: widget.usuarioId,
      descripcion: descripcion,
    );

    if (!mounted) return;
    if (ok) {
      if (vm.estado == EvidenciaEstado.listoOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sin conexión. Evidencia guardada, se subirá automáticamente.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.esCreador
                ? 'Evidencia publicada exitosamente'
                : 'Evidencia subida. El creador de la búsqueda la verificará antes de que aparezca en el mapa.'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      final errorMsg = vm.errorMessage ?? 'Error al procesar la evidencia.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EvidenciaViewModel>();

    // Las evidencias pendientes no se muestran afuera en la ficha
    final evidenciasPendientes = <EvidenciaModel>[];
    final evidenciasAprobadas =
        vm.evidencias.where((e) => e.estado == 'approved').toList();

    final totalVisible = evidenciasAprobadas.length +
        vm.pendientes.length +
        evidenciasPendientes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: [
            const Icon(Icons.camera_enhance, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Evidencias Fotográficas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
            if (totalVisible > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalVisible',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Fotos capturadas por voluntarios durante la búsqueda.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),

        // Botón agregar evidencia
        if (widget.puedePublicar)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: vm.cargando ? null : _onAgregarEvidencia,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Agregar evidencia'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Bandeja de aprobacion: visible solo para el creador
        if (widget.esCreador && evidenciasPendientes.isNotEmpty) ...([
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD700)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions,
                    color: Color(0xFFB8860B), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${evidenciasPendientes.length} evidencia(s) esperan tu aprobación',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF856404),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: evidenciasPendientes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _EvidenciaPendienteAdminCard(
              evidencia: evidenciasPendientes[i],
              reporteId: widget.reporteId,
            ),
          ),
          const SizedBox(height: 16),
        ]),

        // Lista principal
        if (vm.cargando)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (totalVisible == 0)
          _EmptyEvidencias(puedePublicar: widget.puedePublicar)
        else
          Column(
            children: [
              // Offline pendientes
              if (vm.pendientes.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vm.pendientes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _EvidenciaOfflineCard(offline: vm.pendientes[i]),
                ),
              if (vm.pendientes.isNotEmpty && evidenciasAprobadas.isNotEmpty)
                const SizedBox(height: 10),
              // Evidencias aprobadas
              if (evidenciasAprobadas.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: evidenciasAprobadas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _EvidenciaCard(evidencia: evidenciasAprobadas[i]),
                ),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla de publicación (full-page route para evitar conflictos de Overlay)
// ─────────────────────────────────────────────────────────────────────────────
class _PublicarEvidenciaPage extends StatefulWidget {
  final Uint8List? bytesPreview;
  final bool tienePosicion;
  final double? latitud;
  final double? longitud;

  const _PublicarEvidenciaPage({
    required this.bytesPreview,
    required this.tienePosicion,
    required this.latitud,
    required this.longitud,
  });

  @override
  State<_PublicarEvidenciaPage> createState() => _PublicarEvidenciaPageState();
}

class _PublicarEvidenciaPageState extends State<_PublicarEvidenciaPage> {
  // Owned here — created in initState, disposed in dispose.
  // NEVER passed from parent.
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La descripción debe tener al menos 5 caracteres'),
        ),
      );
      return;
    }
    // Pop returns the text. The parent (which is a stable, non-animated route)
    // will handle calling publicarEvidencia once this route is fully gone.
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Evidencia'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.bytesPreview != null) ...
              [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    widget.bytesPreview!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            Row(
              children: [
                Icon(
                  widget.tienePosicion ? Icons.location_on : Icons.location_off,
                  size: 14,
                  color: widget.tienePosicion ? AppTheme.success : AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.tienePosicion
                        ? 'GPS: ${widget.latitud!.toStringAsFixed(5)}, ${widget.longitud!.toStringAsFixed(5)}'
                        : 'Sin ubicación GPS',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.tienePosicion ? AppTheme.success : AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              maxLength: 400,
              autofocus: false,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción de la evidencia *',
                hintText: 'Ej: Encontré el collar en la zona noreste...',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _confirmar,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Confirmar y publicar'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card individual de evidencia (Online)
// ─────────────────────────────────────────────────────────────────────────────
class _EvidenciaCard extends StatelessWidget {
  final EvidenciaModel evidencia;

  const _EvidenciaCard({required this.evidencia});

  String _tiempoRelativo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (evidencia.fotoUrl != null && evidencia.fotoUrl!.isNotEmpty)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageView(
                    imageUrl: evidencia.fotoUrl!,
                    tag: 'evidencia-${evidencia.id}',
                  ),
                ),
              ),
              child: Hero(
                tag: 'evidencia-${evidencia.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: CachedNetworkImage(
                    imageUrl: evidencia.fotoUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 200,
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 200,
                      color: const Color(0xFFF5F5F5),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidencia.descripcion,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5),
                ),
                const SizedBox(height: 10),
                if (evidencia.lat != null && evidencia.lng != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 13, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text(
                        '${evidencia.lat!.toStringAsFixed(5)}, ${evidencia.lng!.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                if (evidencia.lat != null) const SizedBox(height: 8),
                Row(
                  children: [
                    if (evidencia.avatarUsuario != null && evidencia.avatarUsuario!.isNotEmpty)
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: CachedNetworkImageProvider(evidencia.avatarUsuario!),
                        backgroundColor: Colors.transparent,
                      )
                    else
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person, size: 14, color: AppTheme.primary),
                      ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        evidencia.nombreUsuario ?? 'Voluntario',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _tiempoRelativo(evidencia.creadoEn),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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

// ─────────────────────────────────────────────────────────────────────────────
// Card individual de evidencia (Offline Pendiente)
// ─────────────────────────────────────────────────────────────────────────────
class _EvidenciaOfflineCard extends StatelessWidget {
  final EvidenciaOfflineModel offline;

  const _EvidenciaOfflineCard({required this.offline});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta de "Pendiente"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: const BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'PENDIENTE DE SUBIDA (Offline)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Imagen Local
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Image.file(
              File(offline.imagePath),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: const Color(0xFFF5F5F5),
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offline.descripcion,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5),
                ),
                const SizedBox(height: 10),
                if (offline.lat != null && offline.lng != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 13, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text(
                        '${offline.lat!.toStringAsFixed(5)}, ${offline.lng!.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w600),
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

// ─────────────────────────────────────────────────────────────────────────────
// Card de evidencia PENDIENTE para el dueno del reporte (con botones aprobar/rechazar)
// ─────────────────────────────────────────────────────────────────────────────
class _EvidenciaPendienteAdminCard extends StatefulWidget {
  final EvidenciaModel evidencia;
  final String reporteId;

  const _EvidenciaPendienteAdminCard({
    required this.evidencia,
    required this.reporteId,
  });

  @override
  State<_EvidenciaPendienteAdminCard> createState() =>
      _EvidenciaPendienteAdminCardState();
}

class _EvidenciaPendienteAdminCardState
    extends State<_EvidenciaPendienteAdminCard> {
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta pendiente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFC107),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: const Row(
              children: [
                Icon(Icons.hourglass_top, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'PENDIENTE DE APROBACION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Imagen
          if (widget.evidencia.fotoUrl != null &&
              widget.evidencia.fotoUrl!.isNotEmpty)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageView(
                    imageUrl: widget.evidencia.fotoUrl!,
                    tag: 'admin-evidencia-${widget.evidencia.id}',
                  ),
                ),
              ),
              child: Hero(
                tag: 'admin-evidencia-${widget.evidencia.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: CachedNetworkImage(
                    imageUrl: widget.evidencia.fotoUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 200,
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 200,
                      color: const Color(0xFFF5F5F5),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.evidencia.descripcion,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textPrimary, height: 1.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (widget.evidencia.avatarUsuario != null &&
                        widget.evidencia.avatarUsuario!.isNotEmpty)
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: CachedNetworkImageProvider(
                            widget.evidencia.avatarUsuario!),
                        backgroundColor: Colors.transparent,
                      )
                    else
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person,
                            size: 14, color: AppTheme.primary),
                      ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.evidencia.nombreUsuario ?? 'Voluntario',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _tiempoRelativo(widget.evidencia.creadoEn),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Botones aprobar / rechazar
                if (_procesando)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _accion(false),
                          icon: const Icon(Icons.close,
                              color: Colors.red, size: 18),
                          label: const Text('Rechazar',
                              style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _accion(true),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
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
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado vacío
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyEvidencias extends StatelessWidget {
  final bool puedePublicar;

  const _EmptyEvidencias({required this.puedePublicar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.camera_enhance_outlined,
            size: 48,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sin evidencias aún',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            puedePublicar
                ? 'Sé el primero en agregar una foto si encuentras algo relevante para la búsqueda.'
                : 'No se registraron evidencias fotográficas en esta búsqueda.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
