import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

Future<bool> showAbandonarOperativoDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => const _ReportDialog(
      titulo: 'Abandonar operativo',
      contenido: '¿Estás seguro de que deseas retirarte de esta búsqueda? '
          'Tu recorrido hasta ahora quedará guardado.',
      labelConfirmar: 'Abandonar operativo',
      colorConfirmar: AppTheme.accent,
      textoColorConfirmar: AppTheme.darkDark,
    ),
  );
  return result == true;
}

Future<bool> showEliminarReporteDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => const _ReportDialog(
      titulo: 'Eliminar reporte',
      contenido: '¿Estás seguro de que deseas eliminar este reporte? '
          'Esta acción no se puede deshacer.',
      labelConfirmar: 'Eliminar reporte',
      colorConfirmar: Colors.red,
      textoColorConfirmar: Colors.white,
    ),
  );
  return result == true;
}

// ─────────────────────────────────────────────────────────────────────────────

class _ReportDialog extends StatelessWidget {
  final String titulo;
  final String contenido;
  final String labelConfirmar;
  final Color colorConfirmar;
  final Color textoColorConfirmar;

  const _ReportDialog({
    required this.titulo,
    required this.contenido,
    required this.labelConfirmar,
    required this.colorConfirmar,
    required this.textoColorConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              contenido,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Botón de acción peligrosa — arriba
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorConfirmar,
                  foregroundColor: textoColorConfirmar,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  labelConfirmar,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Cancelar — abajo, área de toque amplia
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
