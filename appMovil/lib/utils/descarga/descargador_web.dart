import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'descargador_interface.dart';

class DescargadorWeb implements DescargadorInterface {
  @override
  Future<void> descargarArchivo(String url, String nombreArchivo) async {
    try {
      final response = await http.get(Uri.parse(url));
      final blob = html.Blob([response.bodyBytes]);
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: blobUrl)
        ..target = '_self'
        ..download = nombreArchivo;
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();

      // Delay revoking slightly so the browser registers the download
      Future.delayed(const Duration(seconds: 5), () {
        html.Url.revokeObjectUrl(blobUrl);
      });
    } catch (e) {
      // Fallback if CORS or network issues prevent direct fetching
      final anchor = html.AnchorElement(href: url)
        ..target = '_blank'
        ..download = nombreArchivo;
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
    }
  }

  @override
  Future<void> descargarTexto(
      String contenido, String nombreArchivo, String mimeType) async {
    final blob = html.Blob([contenido], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = '_self'
      ..download = nombreArchivo;
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();

    Future.delayed(const Duration(seconds: 5), () {
      html.Url.revokeObjectUrl(url);
    });
  }
}

DescargadorInterface obtenerDescargador() => DescargadorWeb();
