import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';

/// Servicio para interactuar con la API Static Images de Mapbox.
/// Permite generar URLs de imágenes estáticas auto-encuadradas
/// con trazados (polylines) y marcadores.
class MapboxStaticService {
  static String get _token => dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  static const String _baseUrl =
      'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/static';

  /// Genera la URL del mapa que muestra las rutas de voluntarios y el cuadrante.
  static String? obtenerMapaRutasUrl({
    required List<LatLng> cuadrante,
    required List<List<LatLng>> rutasVoluntarios,
    LatLng? lpp,
  }) {
    if (_token.isEmpty) return null;

    final List<String> overlays = [];

    // 1. Agregar Polígono del Cuadrante (azul claro translúcido)
    if (cuadrante.isNotEmpty) {
      // Para cerrar el polígono, el último punto debe ser igual al primero
      final puntosPoligono = List<LatLng>.from(cuadrante);
      if (puntosPoligono.first != puntosPoligono.last) {
        puntosPoligono.add(puntosPoligono.first);
      }
      final polylineStr = encodePolyline(puntosPoligono);
      // path-strokeWidth+strokeColor-strokeOpacity+fillColor-fillOpacity
      overlays.add(
          'path-2+2196F3-0.8+2196F3-0.15(${Uri.encodeComponent(polylineStr)})');
    }

    // 2. Agregar Polylines de voluntarios (amarillo/naranja)
    for (final ruta in rutasVoluntarios) {
      if (ruta.length > 1) {
        final polylineStr = encodePolyline(ruta);
        // path-strokeWidth+strokeColor-strokeOpacity
        overlays.add('path-4+F59E0B-0.8(${Uri.encodeComponent(polylineStr)})');
      }
    }

    // 3. Agregar marcador LPP (rojo)
    if (lpp != null) {
      overlays.add('pin-l+D32F2F(${lpp.longitude},${lpp.latitude})');
    }

    if (overlays.isEmpty) return null;

    final overlaysPath = overlays.join(',');
    // auto = ajusta el zoom y centro para que quepan todos los overlays
    // 800x500@2x = resolución de la imagen (retina)
    return '$_baseUrl/$overlaysPath/auto/800x500@2x?padding=50&access_token=$_token';
  }

  /// Genera la URL del mapa que muestra exclusivamente las evidencias aprobadas.
  static String? obtenerMapaEvidenciasUrl({
    required List<LatLng> evidenciasAprobadas,
    LatLng? lpp,
  }) {
    if (_token.isEmpty) return null;

    final List<String> overlays = [];

    // 1. Agregar marcador LPP (rojo oscuro)
    if (lpp != null) {
      overlays.add('pin-l+D32F2F(${lpp.longitude},${lpp.latitude})');
    }

    // 2. Agregar pines de evidencias (azul)
    for (final ev in evidenciasAprobadas) {
      overlays.add('pin-s+2196F3(${ev.longitude},${ev.latitude})');
    }

    if (overlays.isEmpty) return null;

    final overlaysPath = overlays.join(',');
    return '$_baseUrl/$overlaysPath/auto/800x500@2x?padding=50&access_token=$_token';
  }

  /// Algoritmo de codificación Polyline (formato de Google)
  /// Convierte una lista de coordenadas en un string comprimido para URLs.
  static String encodePolyline(List<LatLng> coordinates) {
    int lastLat = 0;
    int lastLng = 0;
    final StringBuffer result = StringBuffer();

    for (final point in coordinates) {
      final int lat = (point.latitude * 1e5).round();
      final int lng = (point.longitude * 1e5).round();

      final int dLat = lat - lastLat;
      final int dLng = lng - lastLng;

      _encode(dLat, result);
      _encode(dLng, result);

      lastLat = lat;
      lastLng = lng;
    }

    return result.toString();
  }

  static void _encode(int v, StringBuffer result) {
    v = v < 0 ? ~(v << 1) : v << 1;
    while (v >= 0x20) {
      result.write(String.fromCharCode((0x20 | (v & 0x1f)) + 63));
      v >>= 5;
    }
    result.write(String.fromCharCode(v + 63));
  }
}
