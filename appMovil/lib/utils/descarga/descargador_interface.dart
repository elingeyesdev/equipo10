abstract class DescargadorInterface {
  Future<void> descargarArchivo(String url, String nombreArchivo);
  Future<void> descargarTexto(
      String contenido, String nombreArchivo, String mimeType);
}
