import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Un widget reutilizable que proporciona la capa base del mapa.
/// Intenta usar Mapbox si existe un token en el .env,
/// de lo contrario utiliza OpenStreetMap de forma gratuita.
class MapTileLayer extends StatelessWidget {
  const MapTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    
    // Si hay un token de Mapbox configurado, usamos su API
    if (mapboxToken.isNotEmpty) {
      return TileLayer(
        urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
        additionalOptions: {
          'accessToken': mapboxToken,
        },
        userAgentPackageName: 'com.equipo10.echoes',
      );
    }

    // Fallback a OpenStreetMap
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.equipo10.echoes',
    );
  }
}
