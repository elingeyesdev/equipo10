import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/tile_cache_service.dart';
import '../theme/app_theme.dart';

/// Capa base del mapa con estrategia **Cache-First → Network-Fallback**.
///
/// - [useSatellite] = true  → Mapbox Satellite-Streets (token en .env).
/// - [useSatellite] = false → OpenStreetMap (gratuito, sin token).
///
/// Ambas fuentes usan [CachingTileProvider] para almacenar tiles en disco y
/// servirlos sin conexión una vez descargados.
///
/// E9.2 — Módulo Offline: Caché de teselas del mapa para el área operativa.
class MapTileLayer extends StatelessWidget {
  final bool useSatellite;
  const MapTileLayer({super.key, this.useSatellite = true});

  @override
  Widget build(BuildContext context) {
    final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    final useMapbox =
        useSatellite && mapboxToken.isNotEmpty && mapboxToken.startsWith('pk.');

    if (useMapbox) {
      return TileLayer(
        urlTemplate:
            'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
        additionalOptions: {'accessToken': mapboxToken},
        userAgentPackageName: 'com.elingeyesdev.equipo10.app.v3',
        // E9.2: TileProvider con caché local — Cache-First
        tileProvider: CachingTileProvider(
          storeName: TileCacheService.defaultStore,
          additionalOptions: {'accessToken': mapboxToken},
        ),
        errorTileCallback: (tile, error, stackTrace) {
          debugPrint(
              '[MapTileLayer] Tile ${tile.coordinates} no disponible: $error');
        },
      );
    }

    // OpenStreetMap — también con caché
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.elingeyesdev.equipo10.app.v3',
      tileProvider: CachingTileProvider(
        storeName: '${TileCacheService.defaultStore}_carto_v1',
      ),
      errorTileCallback: (tile, error, stackTrace) {
        debugPrint(
            '[MapTileLayer] Tile OSM ${tile.coordinates} no disponible: $error');
      },
    );
  }
}

/// Botón flotante reutilizable para alternar entre vista satelital y callejera.
class MapLayerToggleButton extends StatelessWidget {
  final bool useSatellite;
  final VoidCallback onToggle;
  final String? heroTag;

  const MapLayerToggleButton({
    super.key,
    required this.useSatellite,
    required this.onToggle,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.primary,
      elevation: 4,
      label: Text(
        useSatellite ? 'Callejero' : 'Satélite',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      icon: Icon(useSatellite ? Icons.map_outlined : Icons.satellite_alt,
          size: 18),
      onPressed: onToggle,
    );
  }
}
