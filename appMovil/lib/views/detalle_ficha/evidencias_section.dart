import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/evidencia_model.dart';
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

  const EvidenciasSection({
    super.key,
    required this.reporteId,
    required this.usuarioId,
    required this.puedePublicar,
  });

  @override
  State<EvidenciasSection> createState() => _EvidenciasSectionState();
}

class _EvidenciasSectionState extends State<EvidenciasSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvidenciaViewModel>().cargarEvidencias(widget.reporteId);
    });
  }

  Future<void> _onAgregarEvidencia() async {
    final vm = context.read<EvidenciaViewModel>();

    // ── Paso 1: elegir fuente ─────────────────────────────────────────
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

    // ── Paso 2: capturar foto + GPS ───────────────────────────────────
    bool capturo = false;
    if (fuente == 'camara') {
      capturo = await vm.capturarFoto();
    } else {
      capturo = await vm.seleccionarDeGaleria();
    }

    if (!capturo || !mounted) return;

    // ── Paso 3: abrir formulario de publicación ───────────────────────
    await _mostrarDialogoPublicar(vm);
  }

  Future<void> _mostrarDialogoPublicar(EvidenciaViewModel vm) async {
    // IMPORTANTE: capturamos todos los datos del ViewModel ANTES de abrir
    // el modal, para no usar context.watch() dentro del BottomSheet y así
    // evitar el error "Assertion failed: _dependents.isEmpty is not true"
    // que ocurre cuando el Provider es disposed mientras el modal está activo.
    final bytesSnapshot = vm.bytesPreview != null
        ? Uint8List.fromList(vm.bytesPreview!)
        : null;
    final tienePosicion = vm.tienePosicion;
    final latSnapshot = vm.latTemporal;
    final lngSnapshot = vm.lngTemporal;

    final descripcionCtrl = TextEditingController();

    // El modal retorna: '' = éxito, String con contenido = error, null = canceló
    final resultado = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PublicarEvidenciaSheet(
        descripcionCtrl: descripcionCtrl,
        bytesPreview: bytesSnapshot,
        tienePosicion: tienePosicion,
        latitud: latSnapshot,
        longitud: lngSnapshot,
        // Callback sin contexto del modal — usa el vm capturado arriba
        onPublicar: (descripcion) => vm.publicarEvidencia(
          reporteId: widget.reporteId,
          usuarioId: widget.usuarioId,
          descripcion: descripcion,
        ),
        onGetErrorMessage: () => vm.errorMessage,
      ),
    );

    descripcionCtrl.dispose();

    if (!mounted) return;

    if (resultado == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Evidencia publicada exitosamente'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else if (resultado != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
    // null = el usuario canceló, no hacemos nada
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EvidenciaViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Encabezado ──────────────────────────────────────────────────
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
            if (vm.evidencias.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${vm.evidencias.length}',
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

        // ── Botón de captura ─────────────────────────────────────────────
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

        // ── Lista / estado vacío ─────────────────────────────────────────
        if (vm.cargando)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (vm.evidencias.isEmpty)
          _EmptyEvidencias(puedePublicar: widget.puedePublicar)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vm.evidencias.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) =>
                _EvidenciaCard(evidencia: vm.evidencias[i]),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulario de publicación: NO escucha al ViewModel con context.watch().
// Todos los datos del ViewModel llegan como parámetros inmutables para evitar
// el error de "Provider disposed while still having dependents".
// ─────────────────────────────────────────────────────────────────────────────
class _PublicarEvidenciaSheet extends StatefulWidget {
  final TextEditingController descripcionCtrl;
  final Uint8List? bytesPreview;
  final bool tienePosicion;
  final double? latitud;
  final double? longitud;
  final Future<bool> Function(String descripcion) onPublicar;
  final String? Function() onGetErrorMessage;

  const _PublicarEvidenciaSheet({
    required this.descripcionCtrl,
    required this.bytesPreview,
    required this.tienePosicion,
    required this.latitud,
    required this.longitud,
    required this.onPublicar,
    required this.onGetErrorMessage,
  });

  @override
  State<_PublicarEvidenciaSheet> createState() =>
      _PublicarEvidenciaSheetState();
}

class _PublicarEvidenciaSheetState extends State<_PublicarEvidenciaSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _publicando = false;
  String _statusTexto = 'Subiendo foto...';

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _publicando = true;
      _statusTexto = 'Subiendo foto...';
    });

    // Tras ~1s actualizamos el texto a "Guardando..." (estimativo)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _publicando) {
        setState(() => _statusTexto = 'Guardando evidencia...');
      }
    });

    final ok = await widget.onPublicar(widget.descripcionCtrl.text.trim());

    if (!mounted) return;

    if (ok) {
      // '' = señal de éxito para el caller
      Navigator.of(context).pop('');
    } else {
      final errorMsg = widget.onGetErrorMessage() ?? 'Error al publicar.';
      // Cerramos pasando el mensaje de error para mostrarlo en el snackbar
      Navigator.of(context).pop(errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const Text(
                  'Publicar evidencia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Preview de la foto
                if (widget.bytesPreview != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      widget.bytesPreview!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 8),

                // Info GPS
                Row(
                  children: [
                    Icon(
                      widget.tienePosicion
                          ? Icons.location_on
                          : Icons.location_off,
                      size: 14,
                      color: widget.tienePosicion
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.tienePosicion
                            ? 'Ubicación: ${widget.latitud!.toStringAsFixed(5)}, ${widget.longitud!.toStringAsFixed(5)}'
                            : 'Sin ubicación GPS (se publicará sin coordenadas)',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.tienePosicion
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Campo de descripción
                TextFormField(
                  controller: widget.descripcionCtrl,
                  maxLines: 3,
                  maxLength: 400,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción de la evidencia *',
                    hintText:
                        'Ej: Encontré el collar en la esquina del parque central...',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'La descripción es obligatoria';
                    }
                    if (v.trim().length < 5) {
                      return 'Descripción muy corta';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Progreso o botones
                if (_publicando)
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          _statusTexto,
                          style:
                              const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _publicar,
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: const Text('Publicar evidencia'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 46),
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card individual de evidencia
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
          // Foto
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: CachedNetworkImage(
                    imageUrl: evidencia.fotoUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 200,
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      child:
                          const Center(child: CircularProgressIndicator()),
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

          // Descripción y metadatos
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidencia.descripcion,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),

                if (evidencia.lat != null && evidencia.lng != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 13, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text(
                        '${evidencia.lat!.toStringAsFixed(5)}, ${evidencia.lng!.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (evidencia.lat != null) const SizedBox(height: 8),

                Row(
                  children: [
                    if (evidencia.avatarUsuario != null &&
                        evidencia.avatarUsuario!.isNotEmpty)
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: CachedNetworkImageProvider(
                            evidencia.avatarUsuario!),
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
                        evidencia.nombreUsuario ?? 'Voluntario',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _tiempoRelativo(evidencia.creadoEn),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
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
                ? 'Sé el primero en agregar una foto si encuentras algo relevante.'
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
