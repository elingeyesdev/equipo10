import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:printing/printing.dart';

import '../../theme/app_theme.dart';

/// Vista de preview y descarga del reporte PDF final del operativo.
///
/// Recibe los [pdfBytes] ya generados (o un [Future] que los genere)
/// y los muestra en el visor nativo de [PdfPreview] con opciones
/// de compartir e imprimir.
class ReportePdfPreview extends StatelessWidget {
  /// Título del operativo — se usa como nombre de archivo al compartir.
  final String tituloOperativo;

  /// Bytes del PDF ya generado.
  final Uint8List pdfBytes;

  const ReportePdfPreview({
    super.key,
    required this.tituloOperativo,
    required this.pdfBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte PDF'),
        backgroundColor: AppTheme.darkBase,
        foregroundColor: Colors.white,
        actions: [
          // Botón de compartir adicional en el AppBar
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartir PDF',
            onPressed: () => _compartirPdf(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.primary.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reporte final de: $tituloOperativo',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Visor PDF nativo
          Expanded(
            child: PdfPreview(
              build: (_) async => pdfBytes,
              pdfFileName: 'Echoes_Reporte_${tituloOperativo.replaceAll(' ', '_')}.pdf',
              allowPrinting: true,
              allowSharing: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              loadingWidget: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text(
                      'Cargando vista previa...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              actions: [
                PdfPreviewAction(
                  icon: const Icon(Icons.download_rounded),
                  onPressed: (context, build, pageFormat) async {
                    // La acción de descarga/compartir la maneja el sistema nativo
                    // a través del botón de share que ya incluye PdfPreview.
                    await Printing.sharePdf(
                      bytes: pdfBytes,
                      filename: 'Echoes_Reporte_${tituloOperativo.replaceAll(' ', '_')}.pdf',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _compartirPdf(BuildContext context) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Echoes_Reporte_${tituloOperativo.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Helper: Captura del mapa como imagen
// ────────────────────────────────────────────────────────────────────────────

/// Captura el widget del mapa identificado por [mapKey] como una imagen PNG.
///
/// Retorna `null` si la captura falla. Llamar ANTES de generar el PDF
/// para que [PdfReporteService.generarReportePDF] reciba [mapaImagenBytes].
Future<Uint8List?> capturarMapaComoImagen(GlobalKey mapKey) async {
  try {
    final RenderRepaintBoundary boundary =
        mapKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  } catch (e) {
    return null;
  }
}
