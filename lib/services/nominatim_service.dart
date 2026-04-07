import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LugarSugerido {
  final String nombre;
  final double lat;
  final double lng;

  LugarSugerido({required this.nombre, required this.lat, required this.lng});
}

class NominatimService {
  // Tipos de elementos geográficos que NO queremos mostrar (ruido)
  static const _tiposRuidosos = {
    'road', 'highway', 'path', 'footway', 'cycleway',
    'tertiary', 'secondary', 'primary', 'trunk', 'unclassified',
    'residential', 'service', 'track', 'motorway', 'living_street',
  };

  // Palabras de relleno que queremos eliminar de los nombres mostrados
  static const _palabrasRuido = [
    'Unnamed Road', 'Ende', 'Calle ', 'Avenida ', 'Pasaje ',
    'Callejón ', 'Carretera ', 'Camino ',
  ];

  /// Busca lugares en Santa Cruz, Bolivia usando Nominatim (sin API key).
  Future<List<LugarSugerido>> buscar(String query) async {
    if (query.trim().length < 3) return [];

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=8'
        '&countrycodes=bo'
        '&viewbox=-63.35,-17.65,-62.95,-17.95'
        '&bounded=0',
      );

      final response = await http.get(uri, headers: {
        'Accept-Language': 'es',
        'User-Agent': 'EchoesApp/1.0 (busqueda-rescate@echoes.bo)',
      });

      if (response.statusCode != 200) return [];

      final List<dynamic> data = json.decode(response.body);

      final resultados = <LugarSugerido>[];

      for (final item in data) {
        final type = item['type'] as String? ?? '';
        final category = item['class'] as String? ?? '';

        // Filtrar ruido de calles genéricas
        if (_tiposRuidosos.contains(type)) continue;
        if (category == 'highway') continue;

        final displayName = item['display_name'] as String? ?? '';
        if (displayName.toLowerCase().contains('unnamed')) continue;

        // Construir nombre limpio: solo la primera parte antes de la coma
        String nombreLimpio = displayName.split(',').first.trim();

        // Eliminar palabras de ruido del inicio
        for (final palabra in _palabrasRuido) {
          if (nombreLimpio.startsWith(palabra)) {
            nombreLimpio = nombreLimpio.substring(palabra.length).trim();
          }
        }

        // Agregar contexto: barrio o ciudad (segunda parte del display)
        final partes = displayName.split(',');
        if (partes.length > 1) {
          final contexto = partes[1].trim();
          if (contexto.isNotEmpty && contexto != nombreLimpio) {
            nombreLimpio = '$nombreLimpio, $contexto';
          }
        }

        if (nombreLimpio.isEmpty) continue;

        resultados.add(LugarSugerido(
          nombre: nombreLimpio,
          lat: double.tryParse(item['lat'] as String? ?? '') ?? 0,
          lng: double.tryParse(item['lon'] as String? ?? '') ?? 0,
        ));
      }

      return resultados;
    } catch (e) {
      debugPrint('NominatimService error: $e');
      return [];
    }
  }
}
