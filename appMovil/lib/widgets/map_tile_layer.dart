import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Un widget reutilizable que proporciona la capa base del mapa.
/// [useSatellite] = true → Mapbox Satellite-Streets (requiere token en .env)
/// [useSatellite] = false → OpenStreetMap (gratuito, sin token)
class MapTileLayer extends StatelessWidget {
  final bool useSatellite;
  const MapTileLayer({super.key, this.useSatellite = true});

  @override
  Widget build(BuildContext context) {
    final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

    // Vista satelital (Mapbox) si hay token y se solicita
    if (useSatellite && mapboxToken.isNotEmpty) {
      return TileLayer(
        urlTemplate:
            'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
        additionalOptions: {'accessToken': mapboxToken},
        userAgentPackageName: 'com.equipo10.echoes',
      );
    }

    // Vista callejera (OpenStreetMap) — gratuita y sin token
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.equipo10.echoes',
    );
  }
}

/// Botón flotante reutilizable para alternar entre vista satelital y callejera.
class MapLayerToggleButton extends StatelessWidget {
  final bool useSatellite;
  final VoidCallback onToggle;
  final String heroTag;

  const MapLayerToggleButton({
    super.key,
    required this.useSatellite,
    required this.onToggle,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1B5E20),
      elevation: 4,
      label: Text(
        useSatellite ? 'Callejero' : 'Satélite',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      icon: Icon(useSatellite ? Icons.map_outlined : Icons.satellite_alt, size: 18),
      onPressed: onToggle,
    );
  }
}
