import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/reporte_model.dart';
import '../../services/encuesta_service.dart';

class EncuestaDialog extends StatefulWidget {
  final ReporteModel reporte;
  final String usuarioId;
  /// true = coordinador que cerró la búsqueda; false = voluntario participante.
  final bool isCoordinador;

  const EncuestaDialog({
    super.key,
    required this.reporte,
    required this.usuarioId,
    this.isCoordinador = false,
  });

  static Future<void> show(
    BuildContext context,
    ReporteModel reporte,
    String usuarioId, {
    bool isCoordinador = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EncuestaDialog(
        reporte: reporte,
        usuarioId: usuarioId,
        isCoordinador: isCoordinador,
      ),
    );
  }

  @override
  State<EncuestaDialog> createState() => _EncuestaDialogState();
}

class _EncuestaDialogState extends State<EncuestaDialog> {
  int _puntuacion = 0;
  final _comentarioCtrl = TextEditingController();
  bool _isLoading = false;
  final _encuestaService = EncuestaService();

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_puntuacion == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una estrella antes de enviar.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final exito = await _encuestaService.enviarEncuesta(
      reporteId: widget.reporte.id,
      usuarioId: widget.usuarioId,
      puntuacion: _puntuacion,
      comentario: _comentarioCtrl.text.trim().isNotEmpty
          ? _comentarioCtrl.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gracias por tus comentarios.')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo enviar (sin conexión). Tu opinión se guardará y se enviará cuando vuelva la red.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      // Cerrar igualmente — la cola offline reintentará
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.reporte.titulo;
    final String descripcion = widget.isCoordinador
        ? 'El operativo "$titulo" ha sido cerrado. ¿Qué tal salió la coordinación? Tu evaluación ayuda a mejorar el sistema.'
        : 'Participaste en la búsqueda "$titulo". Cuéntanos tu experiencia como voluntario para seguir mejorando.';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.isCoordinador ? 'Cierre de Operativo' : 'Operativo Finalizado',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(descripcion, style: const TextStyle(fontSize: 13, height: 1.4)),
            const SizedBox(height: 20),
            const Text(
              '¿Qué tan satisfecho/a estás con el operativo?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 10),
            // Estrellas — FittedBox evita overflow en pantallas pequeñas
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _puntuacion = index + 1),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Icon(
                      index < _puntuacion
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber.shade700,
                      size: 34,
                    ),
                  );
                }),
              ),
            ),
            if (_puntuacion > 0) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  ['', 'Muy mal', 'Regular', 'Bien', 'Muy bien', 'Excelente'][_puntuacion],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Comentario (opcional):',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: '¿Algo que mejorar?',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Saltar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _enviar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Enviar'),
        ),
      ],
    );
  }
}
