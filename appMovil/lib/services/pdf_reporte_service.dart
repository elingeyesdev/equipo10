// import 'dart:typed_data'; removed

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img_pkg;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:latlong2/latlong.dart';
import 'mapbox_static_service.dart';

/// Servicio encargado de ensamblar el PDF final del operativo.
///
/// Recibe el mapa de datos consolidados devuelto por [ReporteService.obtenerDatosReporteFinal]
/// y devuelve el PDF como [Uint8List] listo para ser mostrado en [PdfPreview].
class PdfReporteService {
  // ─── Paleta de la app ───────────────────────────────────────────────────────
  static const _primary = PdfColor.fromInt(0xFF3F7AC5);
  static const _primaryDark = PdfColor.fromInt(0xFF2D5A9A);
  static const _accent = PdfColor.fromInt(0xFFE9C978);
  static const _darkBase = PdfColor.fromInt(0xFF353F4C);
  static const _textSecondary = PdfColor.fromInt(0xFF3F4B5B);
  static const _backgroundLight = PdfColor.fromInt(0xFFF8F8F8);
  static const _success = PdfColor.fromInt(0xFF16A34A);
  static const _warning = PdfColor.fromInt(0xFFF59E0B);
  static const _danger = PdfColor.fromInt(0xFFEF4444);
  static const _border = PdfColor.fromInt(0xFFDFDFDF);

  /// Genera el PDF completo del operativo.
  ///
  /// [datos] es el Map retornado por el endpoint `/reportes/{id}/reporte-final`.
  /// [onProgress] recibe actualizaciones de progreso: (paso, mensaje, porcentaje 0.0–1.0).
  Future<Uint8List> generarReportePDF({
    required Map<String, dynamic> datos,
    void Function(String paso, String mensaje, double porcentaje)? onProgress,
  }) async {
    try {
      return await _generarReportePDFInterno(datos: datos, onProgress: onProgress);
    } catch (e) {
      debugPrint('[PDF] Error generando reporte: $e');
      rethrow;
    }
  }

  Future<Uint8List> _generarReportePDFInterno({
    required Map<String, dynamic> datos,
    void Function(String paso, String mensaje, double porcentaje)? onProgress,
  }) async {
    // 1. Obtener mapas estáticos de Mapbox
    onProgress?.call('mapa', 'Descargando mapas satelitales...', 0.05);
    Uint8List? mapaRutasBytes;
    Uint8List? mapaEvidenciasBytes;

    try {
      final lat = double.tryParse(datos['latitud']?.toString() ?? '');
      final lng = double.tryParse(datos['longitud']?.toString() ?? '');
      final lpp = (lat != null && lng != null) ? LatLng(lat, lng) : null;

      final cuadrante = (datos['mapa_cuadrante'] as List<LatLng>?) ?? [];
      final rutas = (datos['mapa_rutas'] as List<List<LatLng>>?) ?? [];

      final urlRutas = MapboxStaticService.obtenerMapaRutasUrl(
        cuadrante: cuadrante,
        rutasVoluntarios: rutas,
        lpp: lpp,
      );
      if (urlRutas != null) {
        mapaRutasBytes = await _descargarImagenRaw(urlRutas);
      }

      final evidencias = (datos['evidencias'] as List?)
              ?.map((e) {
                if (e['estado'] == 'approved') {
                  final eLat = double.tryParse(e['lat']?.toString() ?? '');
                  final eLng = double.tryParse(e['lng']?.toString() ?? '');
                  if (eLat != null && eLng != null) return LatLng(eLat, eLng);
                }
                return null;
              })
              .whereType<LatLng>()
              .toList() ??
          [];

      final urlEvidencias = MapboxStaticService.obtenerMapaEvidenciasUrl(
        evidenciasAprobadas: evidencias,
        lpp: lpp,
      );
      if (urlEvidencias != null) {
        mapaEvidenciasBytes = await _descargarImagenRaw(urlEvidencias);
      }
    } catch (e) {
      debugPrint('Error al obtener mapas estáticos: $e');
    }

    // Pre-descargar imágenes de evidencias con reporte de progreso
    onProgress?.call(
        'imagenes', 'Descargando evidencias fotográficas...', 0.20);
    final List<Map<String, dynamic>> listEvidencias =
        List<Map<String, dynamic>>.from(datos['evidencias'] ?? []);
    final List<_ImagenCargada> imagenesEvidencias =
        await _cargarImagenes(listEvidencias, onProgress: onProgress);

    // Imagen principal del reporte (si aplica)
    onProgress?.call('imagenes', 'Descargando imagen principal...', 0.5);
    _ImagenCargada? imagenPrincipal;
    final String? primeraImg = datos['primera_imagen']?.toString();
    if (primeraImg != null && primeraImg.isNotEmpty) {
      final bytes = await _descargarYOptimizar(primeraImg);
      if (bytes != null) {
        imagenPrincipal = _ImagenCargada(url: primeraImg, bytes: bytes);
      }
    }

    onProgress?.call('ensamblando', 'Ensamblando documento PDF...', 0.75);

    // Permite que la UI actualice la animación al 75% antes de lanzar el isolate
    await Future.delayed(const Duration(milliseconds: 150));

    final params = _PdfParams(
      datos,
      mapaRutasBytes,
      mapaEvidenciasBytes,
      imagenesEvidencias,
      imagenPrincipal,
    );

    // Ejecuta el ensamblado pesado (pdf.addPage y pdf.save) en un Isolate de fondo
    return await compute(_ensamblarPdfIsolate, params);
  }

  Future<Uint8List?> _descargarImagenRaw(String url) async {
    for (int intento = 0; intento < 2; intento++) {
      try {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          return res.bodyBytes;
        }
      } catch (e) {
        debugPrint('[PDF] Error descargando mapa (intento ${intento + 1}): $e');
      }
    }
    return null;
  }

  /// Método asíncrono interno que corre en background para ensamblar y guardar el PDF
  Future<Uint8List> _generarReportePDFSync(
    Map<String, dynamic> datosOriginales,
    Uint8List? mapaRutasBytes,
    Uint8List? mapaEvidenciasBytes,
    List<_ImagenCargada> imagenesEvidencias,
    _ImagenCargada? imagenPrincipal,
  ) async {
    // Sanitizar datos para eliminar emojis y caracteres no soportados por Helvetica (Latin-1)
    final datos = _limpiarDatos(datosOriginales) as Map<String, dynamic>;

    final pdf = pw.Document(
      title: 'Reporte Final - ${datos['titulo'] ?? 'Operativo'}',
      author: 'Echoes App',
      creator: 'Echoes',
    );

    // Cargar fuente base (usa la fuente por defecto del paquete pdf que es
    // latin, suficiente para español)
    final ttfNormal = pw.Font.helvetica();
    final ttfBold = pw.Font.helveticaBold();

    final baseTheme = pw.ThemeData.withFont(
      base: ttfNormal,
      bold: ttfBold,
    );

    // ── Página 1: Encabezado + Ficha del Operativo ─────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        theme: baseTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildEncabezado(ctx, datos, ttfBold),
        footer: (ctx) => _buildPiePagina(ctx, ttfNormal),
        build: (ctx) => [
          _buildFichaOperativo(datos, imagenPrincipal, ttfNormal, ttfBold),
          pw.SizedBox(height: 20),
          _buildSeccionEstadisticasRapidas(datos, ttfNormal, ttfBold),
        ],
      ),
    );

    // ── Página 2: Mapa de Ruta Final ─────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        theme: baseTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildEncabezado(ctx, datos, ttfBold),
            _buildSeccionMapaRutas(mapaRutasBytes, datos, ttfNormal, ttfBold),
            pw.SizedBox(height: 32),
            _buildSeccionMapaEvidencias(
                mapaEvidenciasBytes, datos, ttfNormal, ttfBold),
          ],
        ),
      ),
    );

    // ── Página 3+: Galería de Fotos ──────────────────────────────────────────
    if (imagenesEvidencias.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          theme: baseTheme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (ctx) => _buildEncabezado(ctx, datos, ttfBold),
          footer: (ctx) => _buildPiePagina(ctx, ttfNormal),
          build: (ctx) => [
            _buildSeccionGaleria(imagenesEvidencias, ttfNormal, ttfBold),
          ],
        ),
      );
    }

    // ── Página Final: Resumen Estadístico Completo ───────────────────────────
    pdf.addPage(
      pw.MultiPage(
        theme: baseTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildEncabezado(ctx, datos, ttfBold),
        footer: (ctx) => _buildPiePagina(ctx, ttfNormal),
        build: (ctx) => [
          _buildSeccionEstadisticasCompletas(datos, ttfNormal, ttfBold),
        ],
      ),
    );

    return pdf.save();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Secciones del PDF
  // ────────────────────────────────────────────────────────────────────────────

  /// Encabezado de cada página con logo textual + título del operativo.
  pw.Widget _buildEncabezado(
    pw.Context ctx,
    Map<String, dynamic> datos,
    pw.Font ttfBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Logo textual "ECHOES"
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _primary,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'ECHOES',
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 14,
                  color: PdfColors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'REPORTE FINAL DE OPERATIVO',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 9,
                    color: _textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.Text(
                  'Generado: ${_formatFechaHora(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 8, color: _textSecondary),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _primary, thickness: 2),
        pw.SizedBox(height: 4),
      ],
    );
  }

  /// Pie de página con número de página.
  pw.Widget _buildPiePagina(pw.Context ctx, pw.Font ttfNormal) {
    return pw.Column(
      children: [
        pw.Divider(color: _border, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Echoes - Sistema de Búsqueda Sectorizada',
              style: pw.TextStyle(fontSize: 7, color: _textSecondary),
            ),
            pw.Text(
              'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 7, color: _textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  /// Sección 1: Ficha descriptiva del operativo.
  pw.Widget _buildFichaOperativo(
    Map<String, dynamic> datos,
    _ImagenCargada? imagenPrincipal,
    pw.Font ttfNormal,
    pw.Font ttfBold,
  ) {
    final estado = datos['estado']?.toString() ?? 'activo';
    final estadoColor = _colorEstado(estado);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Título de sección
        _buildSectionTitle('[ FICHA DEL OPERATIVO ]', ttfBold),
        pw.SizedBox(height: 12),

        // Tarjeta principal
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: _border, width: 0.5),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          padding: const pw.EdgeInsets.all(16),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Columna de datos
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Título
                    pw.Text(
                      datos['titulo'] ?? 'Sin título',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 18,
                        color: _darkBase,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    // Badge de estado
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: estadoColor.shade(0.15),
                        border: pw.Border.all(color: estadoColor, width: 0.8),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        estado.toUpperCase(),
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 9,
                          color: estadoColor,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 14),
                    // Datos clave en tabla 2 columnas
                    _buildInfoGrid([
                      _InfoItem('Categoría', datos['categoria'] ?? 'N/A'),
                      _InfoItem('Fecha de reporte',
                          _formatFecha(datos['fecha_reporte']?.toString())),
                      _InfoItem('Fecha del evento',
                          _formatFecha(datos['fecha_perdida']?.toString())),
                      _InfoItem(
                          'Cuadrante', datos['cuadrante_nombre'] ?? 'N/A'),
                      _InfoItem('Nivel de expansión',
                          '${datos['nivel_expansion'] ?? 1} / ${datos['max_expansion'] ?? 10}'),
                      _InfoItem('Contacto',
                          datos['telefono_contacto'] ?? 'No disponible'),
                    ], ttfNormal, ttfBold),
                    // Descripción
                    pw.SizedBox(height: 14),
                    pw.Text(
                      'Descripción:',
                      style: pw.TextStyle(
                          font: ttfBold, fontSize: 10, color: _darkBase),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: _backgroundLight,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        datos['descripcion'] ?? 'Sin descripción.',
                        style: pw.TextStyle(
                            fontSize: 10,
                            color: _textSecondary,
                            lineSpacing: 2),
                      ),
                    ),
                    // Dirección de referencia
                    if (datos['direccion_referencia'] != null) ...[
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          pw.Text('Dirección: ',
                              style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                          pw.Flexible(
                            child: pw.Text(
                              datos['direccion_referencia'].toString(),
                              style: pw.TextStyle(
                                  fontSize: 10, color: _textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Recompensa si aplica
                    if (datos['recompensa'] != null &&
                        datos['recompensa'] != 0) ...[
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFFEF3C7),
                          border: pw.Border.all(color: _accent, width: 0.8),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          '[ Recompensa: S/ ${datos['recompensa']} ]',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 10,
                            color: PdfColor.fromInt(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                    // Características adicionales
                    if (datos['caracteristicas'] is Map &&
                        (datos['caracteristicas'] as Map).isNotEmpty) ...[
                      pw.SizedBox(height: 14),
                      pw.Text(
                        'Características adicionales:',
                        style: pw.TextStyle(
                            font: ttfBold, fontSize: 10, color: _darkBase),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children:
                            (datos['caracteristicas'] as Map).entries.map((e) {
                          final clave = e.key.toString();
                          final valor = e.value?.toString() ?? '';
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: _backgroundLight,
                              border: pw.Border.all(color: _border, width: 0.5),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              '$clave: $valor',
                              style: pw.TextStyle(
                                  fontSize: 9, color: _textSecondary),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              // Imagen principal si existe
              if (imagenPrincipal != null) ...[
                pw.SizedBox(width: 16),
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    children: [
                      pw.ClipRRect(
                        horizontalRadius: 8,
                        verticalRadius: 8,
                        child: pw.Image(
                          pw.MemoryImage(imagenPrincipal.bytes),
                          fit: pw.BoxFit.cover,
                          height: 160,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Foto Principal',
                        style: pw.TextStyle(fontSize: 8, color: _textSecondary),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Sección de estadísticas rápidas (tarjetas).
  pw.Widget _buildSeccionEstadisticasRapidas(
    Map<String, dynamic> datos,
    pw.Font ttfNormal,
    pw.Font ttfBold,
  ) {
    final stats = datos['estadisticas'] as Map<String, dynamic>? ?? {};
    final totalVoluntarios = stats['total_voluntarios'] ?? 0;
    final totalEvidencias = stats['total_evidencias'] ?? 0;
    final evidenciasAprobadas = stats['evidencias_aprobadas'] ?? 0;
    final cuadrantesExpandidos = stats['cuadrantes_expandidos'] ?? 1;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('[ RESUMEN RÁPIDO ]', ttfBold),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            _buildStatCard(
                'Voluntarios', '$totalVoluntarios', _primary, ttfBold),
            pw.SizedBox(width: 8),
            _buildStatCard('Evidencias', '$totalEvidencias', _warning, ttfBold),
            pw.SizedBox(width: 8),
            _buildStatCard(
                'Aprobadas', '$evidenciasAprobadas', _success, ttfBold),
            pw.SizedBox(width: 8),
            _buildStatCard('Cuadrantes', '$cuadrantesExpandidos',
                PdfColors.indigo, ttfBold),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSeccionMapaRutas(
    Uint8List? mapaBytes,
    Map<String, dynamic> datos,
    pw.Font ttfNormal,
    pw.Font ttfBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 16),
        _buildSectionTitle('[ MAPA DE RUTA DE VOLUNTARIOS ]', ttfBold),
        pw.SizedBox(height: 12),
        pw.Container(
          width: 531,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.5),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: mapaBytes != null
              ? pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(
                    pw.MemoryImage(mapaBytes),
                    fit: pw.BoxFit.contain,
                  ),
                )
              : _buildMapaPlaceholder(datos, ttfNormal, ttfBold),
        ),
        pw.SizedBox(height: 10),
        // Leyenda del mapa
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _buildLeyendaItem('Punto de Última Posición', _danger, ttfNormal),
            pw.SizedBox(width: 16),
            _buildLeyendaItem('Recorrido Voluntarios', _warning, ttfNormal),
            pw.SizedBox(width: 16),
            _buildLeyendaItem('Cuadrante de Búsqueda', _primary, ttfNormal),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSeccionMapaEvidencias(
    Uint8List? mapaBytes,
    Map<String, dynamic> datos,
    pw.Font ttfNormal,
    pw.Font ttfBold,
  ) {
    if (mapaBytes == null) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('[ MAPA DE EVIDENCIAS APROBADAS ]', ttfBold),
        pw.SizedBox(height: 12),
        pw.Container(
          width: 531,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.5),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(
              pw.MemoryImage(mapaBytes),
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        // Leyenda del mapa
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _buildLeyendaItem('Punto de Última Posición', _danger, ttfNormal),
            pw.SizedBox(width: 16),
            _buildLeyendaItem('Evidencia Aprobada', _primary, ttfNormal),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildMapaPlaceholder(
    Map<String, dynamic> datos,
    pw.Font ttfNormal,
    pw.Font ttfBold,
  ) {
    final lat = datos['latitud']?.toString() ?? 'N/A';
    final lng = datos['longitud']?.toString() ?? 'N/A';
    final cuadrante = datos['cuadrante_nombre'] ?? 'N/A';

    return pw.Container(
      height: 380,
      padding: const pw.EdgeInsets.all(24),
      color: _backgroundLight,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            '[ MAPA DE RUTA ]',
            style: pw.TextStyle(
              font: ttfBold,
              fontSize: 18,
              color: _primary,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'La captura del mapa interactivo se incluye\ncuando se genera el reporte desde la aplicación.',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 11, color: _textSecondary),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _border),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _buildInfoRow('Coordenadas (LPP)', 'Lat: $lat  |  Lng: $lng',
                    ttfNormal, ttfBold),
                pw.Divider(color: _border, thickness: 0.5),
                _buildInfoRow(
                    'Cuadrante Asignado', cuadrante, ttfNormal, ttfBold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sección 3: Galería de fotos de evidencias aprobadas.
  pw.Widget _buildSeccionGaleria(
    List<_ImagenCargada> imagenes,
    pw.Font ttfNormal,
    pw.Font ttfBold,
  ) {
    const int columnas = 2;
    final rows = <pw.Widget>[];

    rows.add(_buildSectionTitle('[ GALERÍA DE EVIDENCIAS ]', ttfBold));
    rows.add(pw.SizedBox(height: 12));

    // Construir grid de 2 columnas
    for (int i = 0; i < imagenes.length; i += columnas) {
      final rowItems = <pw.Widget>[];

      for (int j = 0; j < columnas; j++) {
        final idx = i + j;
        if (idx < imagenes.length) {
          final img = imagenes[idx];
          rowItems.add(
            pw.Expanded(
              child: pw.Container(
                margin: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _border, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.ClipRRect(
                      horizontalRadius: 6,
                      verticalRadius: 0,
                      child: pw.Image(
                        pw.MemoryImage(img.bytes),
                        height: 160,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (img.descripcion != null &&
                              img.descripcion!.isNotEmpty)
                            pw.Text(
                              img.descripcion!,
                              style: pw.TextStyle(
                                  fontSize: 8, color: _textSecondary),
                              maxLines: 2,
                            ),
                          if (img.fecha != null)
                            pw.Text(
                              _formatFechaHora(img.fecha!),
                              style: pw.TextStyle(
                                  fontSize: 7, color: _textSecondary),
                            ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: _success.shade(0.15),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              'APROBADA',
                              style: pw.TextStyle(
                                  font: ttfBold, fontSize: 7, color: _success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          rowItems.add(pw.Expanded(child: pw.SizedBox()));
        }
      }

      rows.add(pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: rowItems,
      ));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: rows,
    );
  }

  /// Sección 4: Estadísticas completas con barras proporcionales.
  pw.Widget _buildSeccionEstadisticasCompletas(
    Map<String, dynamic> datos,
    pw.Font ttfNormal,
    pw.Font ttfBold,
  ) {
    final stats = datos['estadisticas'] as Map<String, dynamic>? ?? {};

    final totalVoluntarios = (stats['total_voluntarios'] ?? 0) as num;
    final tiempoTotalMinutos = (stats['tiempo_total_minutos'] ?? 0) as num;
    final tiempoActivoMinutos = (stats['tiempo_activo_minutos'] ?? 0) as num;
    final distanciaKm = (stats['distancia_total_km'] ?? 0.0) as num;
    final totalEvidencias = (stats['total_evidencias'] ?? 0) as num;
    final evidenciasAprobadas = (stats['evidencias_aprobadas'] ?? 0) as num;
    final evidenciasRechazadas = (stats['evidencias_rechazadas'] ?? 0) as num;
    final cuadrantesExpandidos = (stats['cuadrantes_expandidos'] ?? 1) as num;
    final nivelExpansion = (datos['nivel_expansion'] ?? 1) as num;
    final maxExpansion = (datos['max_expansion'] ?? 10) as num;

    final horasTotales = tiempoTotalMinutos ~/ 60;
    final minutosTotales = tiempoTotalMinutos % 60;
    final horasActivo = tiempoActivoMinutos ~/ 60;
    final minutosActivo = tiempoActivoMinutos % 60;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('[ RESUMEN ESTADÍSTICO COMPLETO ]', ttfBold),
        pw.SizedBox(height: 16),

        // Tabla de datos clave
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.5),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Table(
            columnWidths: {
              0: const pw.FractionColumnWidth(0.5),
              1: const pw.FractionColumnWidth(0.5),
            },
            children: [
              _buildTableHeader(['Métrica', 'Valor'], ttfBold),
              _buildTableRow([
                'Total de voluntarios',
                '$totalVoluntarios participantes'
              ], ttfNormal, isAlternate: false),
              _buildTableRow([
                'Duración total del operativo',
                '${horasTotales}h ${minutosTotales}min'
              ], ttfNormal, isAlternate: true),
              _buildTableRow([
                'Tiempo activo de búsqueda',
                '${horasActivo}h ${minutosActivo}min'
              ], ttfNormal, isAlternate: false),
              _buildTableRow([
                'Distancia total cubierta',
                '${distanciaKm.toStringAsFixed(2)} km'
              ], ttfNormal, isAlternate: true),
              _buildTableRow([
                'Cuadrantes expandidos',
                '$cuadrantesExpandidos cuadrante(s)'
              ], ttfNormal, isAlternate: false),
              _buildTableRow([
                'Nivel de expansión alcanzado',
                '$nivelExpansion / $maxExpansion'
              ], ttfNormal, isAlternate: true),
              _buildTableRow([
                'Total de evidencias reportadas',
                '$totalEvidencias'
              ], ttfNormal, isAlternate: false),
              _buildTableRow(
                  ['Evidencias aprobadas', '$evidenciasAprobadas'], ttfNormal,
                  isAlternate: true),
              _buildTableRow(
                  ['Evidencias rechazadas', '$evidenciasRechazadas'], ttfNormal,
                  isAlternate: false),
            ],
          ),
        ),

        pw.SizedBox(height: 20),
        _buildSectionTitle('[ COBERTURA DE EVIDENCIAS ]', ttfBold),
        pw.SizedBox(height: 12),

        // Barra proporcional de evidencias
        if (totalEvidencias > 0) ...[
          _buildBarraProgreso(
            label: 'Aprobadas',
            valor: evidenciasAprobadas.toDouble(),
            maximo: totalEvidencias.toDouble(),
            color: _success,
            ttfNormal: ttfNormal,
            ttfBold: ttfBold,
          ),
          pw.SizedBox(height: 8),
          _buildBarraProgreso(
            label: 'Rechazadas',
            valor: evidenciasRechazadas.toDouble(),
            maximo: totalEvidencias.toDouble(),
            color: _danger,
            ttfNormal: ttfNormal,
            ttfBold: ttfBold,
          ),
          pw.SizedBox(height: 8),
          _buildBarraProgreso(
            label: 'Expansión',
            valor: nivelExpansion.toDouble(),
            maximo: maxExpansion.toDouble(),
            color: _primary,
            ttfNormal: ttfNormal,
            ttfBold: ttfBold,
          ),
        ] else
          pw.Text(
            'No se reportaron evidencias en este operativo.',
            style: pw.TextStyle(fontSize: 10, color: _textSecondary),
          ),

        pw.SizedBox(height: 24),
        _buildSeccionGraficoEvidencias(datos, ttfNormal, ttfBold),
        pw.SizedBox(height: 24),

        // Nota de cierre
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFEFF6FF),
            border: pw.Border.all(color: _primary, width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            'Este reporte fue generado automáticamente por el sistema Echoes al concluir el operativo de búsqueda. '
            'Todos los datos son registros reales del sistema y pueden ser utilizados como evidencia oficial.',
            style: pw.TextStyle(
                fontSize: 9, color: _primaryDark, lineSpacing: 1.5),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSeccionGraficoEvidencias(
    Map<String, dynamic> datos,
    pw.Font ttfNormal,
    pw.Font ttfBold,
  ) {
    final evidencias = datos['evidencias'] as List? ?? [];
    if (evidencias.isEmpty) return pw.SizedBox();

    // Agrupar evidencias por fecha (Día/Mes)
    final Map<String, int> conteoPorFecha = {};
    for (var ev in evidencias) {
      final fechaStr = ev['created_at']?.toString();
      if (fechaStr == null) continue;
      final dt = DateTime.tryParse(fechaStr);
      if (dt == null) continue;
      final dateKey =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
      conteoPorFecha[dateKey] = (conteoPorFecha[dateKey] ?? 0) + 1;
    }

    if (conteoPorFecha.isEmpty) return pw.SizedBox();

    // Si solo hay un día, agrupar por hora
    if (conteoPorFecha.keys.length == 1) {
      conteoPorFecha.clear();
      for (var ev in evidencias) {
        final fechaStr = ev['created_at']?.toString();
        if (fechaStr == null) continue;
        final dt = DateTime.tryParse(fechaStr);
        if (dt == null) continue;
        final dateKey = '${dt.hour.toString().padLeft(2, '0')}:00';
        conteoPorFecha[dateKey] = (conteoPorFecha[dateKey] ?? 0) + 1;
      }
    }

    final keys = conteoPorFecha.keys.toList();
    final values = keys.map((k) => conteoPorFecha[k]!).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
            '[ DISTRIBUCIÓN DE EVIDENCIAS EN EL TIEMPO ]', ttfBold),
        pw.SizedBox(height: 12),
        pw.Container(
          height: 180,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.5),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis.fromStrings(
                List<String>.generate(keys.length, (i) => keys[i]),
                marginStart: 30,
                marginEnd: 30,
                ticks: true,
              ),
              yAxis: pw.FixedAxis(
                List<int>.generate(
                  (values.isNotEmpty
                          ? values.reduce((a, b) => a > b ? a : b)
                          : 0) +
                      2,
                  (i) => i,
                ),
                ticks: true,
              ),
            ),
            datasets: [
              pw.BarDataSet(
                color: _primary,
                width: 15,
                data: List<pw.PointChartValue>.generate(
                  keys.length,
                  (i) => pw.PointChartValue(i.toDouble(), values[i].toDouble()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers de construcción de widgets
  // ────────────────────────────────────────────────────────────────────────────

  pw.Widget _buildSectionTitle(String title, pw.Font ttfBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(font: ttfBold, fontSize: 13, color: _darkBase),
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, width: 60, color: _accent),
      ],
    );
  }

  pw.Widget _buildStatCard(
      String label, String valor, PdfColor color, pw.Font ttfBold) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: color.shade(0.12),
          border: pw.Border.all(color: color.shade(0.4), width: 0.5),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              valor,
              style: pw.TextStyle(font: ttfBold, fontSize: 22, color: color),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, color: _textSecondary),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildInfoGrid(
      List<_InfoItem> items, pw.Font ttfNormal, pw.Font ttfBold) {
    final rows = <pw.Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : null;
      rows.add(
        pw.Row(
          children: [
            pw.Expanded(child: _buildInfoItemWidget(left, ttfNormal, ttfBold)),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: right != null
                  ? _buildInfoItemWidget(right, ttfNormal, ttfBold)
                  : pw.SizedBox(),
            ),
          ],
        ),
      );
      rows.add(pw.SizedBox(height: 8));
    }
    return pw.Column(children: rows);
  }

  pw.Widget _buildInfoItemWidget(
      _InfoItem item, pw.Font ttfNormal, pw.Font ttfBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          item.label,
          style: pw.TextStyle(fontSize: 8, color: _textSecondary),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          item.value,
          style: pw.TextStyle(font: ttfBold, fontSize: 10, color: _darkBase),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(
      String label, String value, pw.Font ttfNormal, pw.Font ttfBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: ttfBold, fontSize: 10, color: _textSecondary)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, color: _darkBase)),
        ],
      ),
    );
  }

  pw.Widget _buildLeyendaItem(String label, PdfColor color, pw.Font ttfNormal) {
    return pw.Row(
      children: [
        pw.Container(width: 12, height: 4, color: color),
        pw.SizedBox(width: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _textSecondary)),
      ],
    );
  }

  pw.TableRow _buildTableHeader(List<String> headers, pw.Font ttfBold) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: _primary),
      children: headers
          .map((h) => pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                ),
              ))
          .toList(),
    );
  }

  pw.TableRow _buildTableRow(List<String> cells, pw.Font ttfNormal,
      {required bool isAlternate}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isAlternate ? _backgroundLight : PdfColors.white,
      ),
      children: cells
          .asMap()
          .entries
          .map((entry) => pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: pw.Text(
                  entry.value,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _darkBase,
                    fontWeight: entry.key == 0
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                  ),
                ),
              ))
          .toList(),
    );
  }

  pw.Widget _buildBarraProgreso({
    required String label,
    required double valor,
    required double maximo,
    required PdfColor color,
    required pw.Font ttfNormal,
    required pw.Font ttfBold,
  }) {
    final porcentaje = maximo > 0 ? (valor / maximo).clamp(0.0, 1.0) : 0.0;
    final pct = (porcentaje * 100).toStringAsFixed(1);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style:
                    pw.TextStyle(font: ttfBold, fontSize: 9, color: _darkBase)),
            pw.Text(
              '${valor.toInt()} / ${maximo.toInt()} ($pct%)',
              style: pw.TextStyle(fontSize: 9, color: _textSecondary),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Stack(
          children: [
            // Fondo completo de la barra
            pw.Container(
              height: 10,
              width: 531,
              decoration: pw.BoxDecoration(
                color: _border,
                borderRadius: pw.BorderRadius.circular(5),
              ),
            ),
            // Relleno proporcional — ancho útil A4 con márgenes de 32pt a cada lado = ~531pt
            if (valor > 0)
              pw.Container(
                height: 10,
                width: 531 * porcentaje < 10 ? 10 : 531 * porcentaje,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Utilidades de descarga y optimización de imágenes (E13.3)
  // ────────────────────────────────────────────────────────────────────────────

  /// Descarga, redimensiona y comprime una imagen a JPEG calidad 60%
  /// para reducir el tamaño final del PDF.
  ///
  /// Algoritmo:
  ///   1. Descarga bytes crudos vía HTTP (timeout 15s)
  ///   2. Decodifica con el paquete `image`
  ///   3. Redimensiona a máximo 1200px de ancho (mantiene ratio)
  ///   4. Re-codifica como JPEG al 60% de calidad
  ///
  /// Retorna null si la descarga falla. Retorna los bytes originales
  /// si la decodificación/compresión falla (fallback seguro).
  Future<Uint8List?> _descargarYOptimizar(String url) async {
    for (int intento = 0; intento < 2; intento++) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(
              const Duration(seconds: 20),
            );
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          continue;
        }
        final originalBytes = response.bodyBytes;
        final Uint8List? optimizados =
            await compute(_optimizarImagenIsolate, originalBytes);
        return optimizados ?? originalBytes;
      } catch (e) {
        debugPrint('[PDF] Error descargando imagen (intento ${intento + 1}): $e');
      }
    }
    return null;
  }

  /// Descarga y optimiza todas las evidencias aprobadas de la lista,
  /// reportando progreso imagen por imagen a través de [onProgress].
  Future<List<_ImagenCargada>> _cargarImagenes(
    List<Map<String, dynamic>> evidencias, {
    void Function(String paso, String mensaje, double porcentaje)? onProgress,
  }) async {
    final result = <_ImagenCargada>[];
    final aprobadas = evidencias
        .where((e) => e['estado'] == 'approved' || e['estado'] == 'approved')
        .toList();

    // Si no hay filtro por estado usamos las aprobadas; de lo contrario tomamos todas
    final aCargar = aprobadas.isNotEmpty
        ? aprobadas
        : evidencias
            .where((e) => e['foto_url'] != null || e['url'] != null)
            .toList();

    // Limitar a 12 imágenes para evitar OOM en dispositivos con poca RAM
    const int maxImagenes = 12;
    final aCargarLimitado = aCargar.length > maxImagenes
        ? aCargar.sublist(0, maxImagenes)
        : aCargar;
    final total = aCargarLimitado.length;
    if (total == 0) return result;

    for (int i = 0; i < total; i++) {
      final ev = aCargarLimitado[i];
      final url = ev['foto_url']?.toString() ?? ev['url']?.toString();
      if (url == null || url.isEmpty) continue;

      // Reportar progreso: 10% – 50% proporcional a imágenes descargadas
      final progresoDescarga = 0.10 + (0.40 * ((i + 1) / total));
      onProgress?.call(
        'imagenes',
        'Optimizando imagen ${i + 1} de $total...',
        progresoDescarga,
      );

      try {
        final bytes = await _descargarYOptimizar(url);
        if (bytes != null) {
          result.add(_ImagenCargada(
            url: url,
            bytes: bytes,
            descripcion: ev['descripcion']?.toString(),
            fecha: ev['created_at'] != null
                ? DateTime.tryParse(ev['created_at'].toString())
                : null,
          ));
        }
      } catch (e) {
        debugPrint('[PDF] Error procesando imagen $i: $e');
      }
    }
    return result;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers de formato
  // ────────────────────────────────────────────────────────────────────────────

  PdfColor _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return _success;
      case 'pausado':
        return _warning;
      case 'resuelto':
      case 'terminado':
      case 'cerrado':
        return _textSecondary;
      default:
        return _textSecondary;
    }
  }

  String _formatFecha(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatFechaHora(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Data classes internas
// ────────────────────────────────────────────────────────────────────────────

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}

class _ImagenCargada {
  final String url;
  final Uint8List bytes;
  final String? descripcion;
  final DateTime? fecha;

  const _ImagenCargada({
    required this.url,
    required this.bytes,
    this.descripcion,
    this.fecha,
  });
}

class _PdfParams {
  final Map<String, dynamic> datos;
  final Uint8List? mapaRutasBytes;
  final Uint8List? mapaEvidenciasBytes;
  final List<_ImagenCargada> imagenesEvidencias;
  final _ImagenCargada? imagenPrincipal;

  const _PdfParams(
    this.datos,
    this.mapaRutasBytes,
    this.mapaEvidenciasBytes,
    this.imagenesEvidencias,
    this.imagenPrincipal,
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Funciones Top-Level para Isolate (compute)
// ────────────────────────────────────────────────────────────────────────────

/// Elimina emojis y caracteres no soportados por la fuente Helvetica (Latin1)
dynamic _limpiarDatos(dynamic valor) {
  if (valor is String) {
    var limpio = valor.replaceAll('–', '-').replaceAll('—', '-');
    // Deja solo caracteres ASCII básicos y caracteres extendidos Latin-1 (acentos)
    limpio = limpio.replaceAll(
        RegExp(r'[^\x00-\x7F\xC0-\xFF\s\.,;:!?()\[\]{}"\x27\-\+]'), '');
    return limpio;
  } else if (valor is List) {
    return valor.map((e) => _limpiarDatos(e)).toList();
  } else if (valor is Map) {
    return valor.map((k, v) => MapEntry(k.toString(), _limpiarDatos(v)));
  }
  return valor;
}

/// Ejecuta el ensamblado del PDF en un isolate de fondo
Future<Uint8List> _ensamblarPdfIsolate(_PdfParams args) async {
  final service = PdfReporteService();
  return await service._generarReportePDFSync(
    args.datos,
    args.mapaRutasBytes,
    args.mapaEvidenciasBytes,
    args.imagenesEvidencias,
    args.imagenPrincipal,
  );
}

/// Ejecuta la compresión de imagen pesada en un isolate
Uint8List? _optimizarImagenIsolate(Uint8List originalBytes) {
  if (originalBytes.isEmpty) return null;
  try {
    final imagen = img_pkg.decodeImage(originalBytes);
    if (imagen == null) return originalBytes;

    // Reducir más agresivamente en archivos grandes para evitar OOM
    const int anchoMaximo = 900;
    final img_pkg.Image imagenOptimizada = imagen.width > anchoMaximo
        ? img_pkg.copyResize(imagen, width: anchoMaximo)
        : imagen;

    final List<int> comprimidos =
        img_pkg.encodeJpg(imagenOptimizada, quality: 55);
    final resultado = Uint8List.fromList(comprimidos);
    // Si la compresión aumentó el tamaño, devolver originales
    return resultado.length < originalBytes.length ? resultado : originalBytes;
  } catch (_) {
    return originalBytes;
  }
}
