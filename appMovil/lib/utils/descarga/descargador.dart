import 'descargador_interface.dart';
import 'descargador_stub.dart'
    if (dart.library.html) 'descargador_web.dart'
    if (dart.library.io) 'descargador_mobile.dart';

class Descargador {
  static final DescargadorInterface _impl = obtenerDescargador();

  static Future<void> descargarArchivo(String url, String nombreArchivo) {
    return _impl.descargarArchivo(url, nombreArchivo);
  }

  static Future<void> descargarTexto(String contenido, String nombreArchivo, String mimeType) {
    return _impl.descargarTexto(contenido, nombreArchivo, mimeType);
  }
}
