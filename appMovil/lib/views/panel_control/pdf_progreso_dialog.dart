import 'package:flutter/material.dart';

/// Estado inmutable que describe el progreso actual de la generación del PDF.
class PdfProgreso {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final double porcentaje;
  final Color color;
  final bool esError;

  const PdfProgreso({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    required this.porcentaje,
    required this.color,
    required this.esError,
  });
}

class PdfProgresoDialog extends StatelessWidget {
  final ValueNotifier<PdfProgreso> progresoNotifier;

  const PdfProgresoDialog({super.key, required this.progresoNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PdfProgreso>(
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: progreso.esError
                      ? const Icon(
                          Icons.error_outline_rounded,
                          size: 56,
                          color: Color(0xFFEF4444),
                          key: ValueKey('error_icon'),
                        )
                      : progreso.porcentaje >= 1.0
                          ? const Icon(
                              Icons.check_circle_rounded,
                              size: 56,
                              color: Color(0xFF16A34A),
                              key: ValueKey('done_icon'),
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
                                        ? null
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
