import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../perfil/perfil_publico_view.dart';
import '../widgets/nombre_con_insignia.dart';

class ComentariosSection extends StatefulWidget {
  final List<Map<String, dynamic>> comentarios;
  final String currentUserId;
  final bool puedeComentar;
  final bool esCreadorDelReporte;
  final bool hasMore;
  final Future<bool> Function(String texto) onEnviar;
  final Future<void> Function(String comentarioId) onEliminar;
  final Future<void> Function() onCargarMas;
  final Future<void> Function() onRefresh;

  const ComentariosSection({
    super.key,
    required this.comentarios,
    required this.currentUserId,
    required this.puedeComentar,
    required this.esCreadorDelReporte,
    required this.hasMore,
    required this.onEnviar,
    required this.onEliminar,
    required this.onCargarMas,
    required this.onRefresh,
  });

  @override
  State<ComentariosSection> createState() => _ComentariosSectionState();
}

class _ComentariosSectionState extends State<ComentariosSection> {
  final TextEditingController _ctrl = TextEditingController();
  Timer? _pollingTimer;
  bool _cargandoMas = false;

  @override
  void initState() {
    super.initState();
    // Polling cada 30 segundos mientras la tab está visible
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      widget.onRefresh();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comentarios ciudadanos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.comentarios.isEmpty)
          const Text(
            'No hay comentarios aún. ¡Sé el primero en escribir!',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.comentarios.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final c = widget.comentarios[index];
              return _ComentarioBurbuja(
                comentario: c,
                currentUserId: widget.currentUserId,
                esCreadorDelReporte: widget.esCreadorDelReporte,
                onEliminar: widget.onEliminar,
              );
            },
          ),

        // Botón "Cargar más"
        if (widget.hasMore) ...[
          const SizedBox(height: 12),
          Center(
            child: _cargandoMas
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton.icon(
                    onPressed: () async {
                      setState(() => _cargandoMas = true);
                      await widget.onCargarMas();
                      if (mounted) setState(() => _cargandoMas = false);
                    },
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: const Text('Cargar más comentarios'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                    ),
                  ),
          ),
        ],

        const SizedBox(height: 16),
        if (widget.puedeComentar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: 'Añadir comentario...',
                      counterText: '',
                      filled: true,
                      fillColor: AppTheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: IconButton(
                    icon:
                        const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () async {
                      final texto = _ctrl.text.trim();
                      if (texto.isEmpty) return;
                      _ctrl.clear();
                      final ok = await widget.onEnviar(texto);
                      if (!ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se pudo enviar el comentario. Verifica tu conexión e intenta de nuevo.',
                              style: TextStyle(color: AppTheme.darkDark),
                            ),
                            backgroundColor: AppTheme.accent,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ComentarioBurbuja extends StatelessWidget {
  final Map<String, dynamic> comentario;
  final String currentUserId;
  final bool esCreadorDelReporte;
  final Future<void> Function(String comentarioId) onEliminar;

  const _ComentarioBurbuja({
    required this.comentario,
    required this.currentUserId,
    required this.esCreadorDelReporte,
    required this.onEliminar,
  });

  static String _timestamp(String? fechaRaw) {
    if (fechaRaw == null) return '';
    try {
      final dt = DateTime.parse(fechaRaw).toLocal();
      final now = DateTime.now();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final horaStr = '$hh:$mm';

      final mismoDia = dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day;
      if (mismoDia) return horaStr;

      final ayer = now.subtract(const Duration(days: 1));
      final esAyer = dt.year == ayer.year &&
          dt.month == ayer.month &&
          dt.day == ayer.day;
      if (esAyer) return 'ayer $horaStr';

      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')} $horaStr';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final autorId = comentario['usuario_id'] as String?;
    final autorNombre = comentario['usuario'] != null
        ? comentario['usuario']['nombre'] as String?
        : null;
    final avatarUrl = comentario['usuario'] != null
        ? comentario['usuario']['foto_url'] as String?
        : null;
    final texto = comentario['texto'] as String? ?? '';
    final ts = _timestamp(
      (comentario['created_at'] ?? comentario['creado_en'])?.toString(),
    );
    final esPropio = autorId == currentUserId;
    final puedeEliminar = esPropio || esCreadorDelReporte;
    final comentarioId = comentario['id']?.toString() ?? '';

    final burbuja = GestureDetector(
      onLongPress: puedeEliminar
          ? () => _confirmarEliminacion(context, comentarioId)
          : null,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: esPropio
              ? AppTheme.primary.withValues(alpha: 0.10)
              : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esPropio ? 16 : 4),
            bottomRight: Radius.circular(esPropio ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkBase.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!esPropio && autorNombre != null) ...[
              GestureDetector(
                onTap: () {
                  if (autorId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerfilPublicoView(usuarioId: autorId),
                      ),
                    );
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NombreConInsignia(
                      nombre: autorNombre,
                      oro: comentario['usuario']?['rescates_oro'] ?? 0,
                      plataBronce: comentario['usuario']?['evidencias_plata_bronce'] ?? 0,
                      baseStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              texto,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
            if (ts.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (puedeEliminar)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: GestureDetector(
                        onTap: () =>
                            _confirmarEliminacion(context, comentarioId),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  Text(
                    ts,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (esPropio) {
      return Align(alignment: Alignment.centerRight, child: burbuja);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatarUrl != null && avatarUrl.isNotEmpty)
            CircleAvatar(
              radius: 16,
              backgroundImage: CachedNetworkImageProvider(avatarUrl),
              backgroundColor: Colors.transparent,
            )
          else
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: Text(
                (autorNombre != null && autorNombre.isNotEmpty)
                    ? autorNombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          const SizedBox(width: 8),
          burbuja,
        ],
      ),
    );
  }

  Future<void> _confirmarEliminacion(
      BuildContext context, String comentarioId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar comentario'),
        content:
            const Text('¿Estás seguro de que deseas eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await onEliminar(comentarioId);
    }
  }
}
