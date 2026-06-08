import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/reporte_model.dart';
import '../../services/encuesta_service.dart';

class EncuestaDialog extends StatefulWidget {
  final ReporteModel reporte;
  final String usuarioId;

  const EncuestaDialog({
    super.key,
    required this.reporte,
    required this.usuarioId,
  });

  static Future<void> show(BuildContext context, ReporteModel reporte, String usuarioId) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Forzar interacción (pueden cerrarla con botón "Saltar")
      builder: (ctx) => EncuestaDialog(reporte: reporte, usuarioId: usuarioId),
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
    if (_puntuacion == 0) return; // Validación de UI

    setState(() => _isLoading = true);
    
    final exito = await _encuestaService.enviarEncuesta(
      reporteId: widget.reporte.id,
      usuarioId: widget.usuarioId,
      puntuacion: _puntuacion,
      comentario: _comentarioCtrl.text.trim().isNotEmpty ? _comentarioCtrl.text.trim() : null,
    );

    if (!mounted) return;
    
    setState(() => _isLoading = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por tus comentarios!')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.star_rate_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 8),
          Text('¡Operativo Finalizado!'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El reporte "${widget.reporte.titulo}" ha sido marcado como resuelto. '
              'Queremos conocer tu experiencia como voluntario para mejorar el sistema.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Qué tan satisfecho estás con la organización del operativo?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            // Estrellas (Likert)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _puntuacion = index + 1),
                  icon: Icon(
                    index < _puntuacion ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.orange,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text(
              'Comentarios adicionales (opcional):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: '¿Cómo podríamos mejorar?',
                hintStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
          onPressed: (_puntuacion == 0 || _isLoading) ? null : _enviar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Enviar'),
        ),
      ],
    );
  }
}
