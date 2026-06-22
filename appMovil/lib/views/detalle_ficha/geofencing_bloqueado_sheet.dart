import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../models/reporte_model.dart';
import '../../widgets/map_tile_layer.dart';
import '../../theme/app_theme.dart';

/// Bottom Sheet que se muestra cuando el voluntario intenta iniciar la búsqueda
/// pero no está dentro del cuadrante asignado. Muestra un mini-mapa con la
/// zona objetivo y la posición actual del usuario para orientarlo.
class GeofencingBloqueadoSheet extends StatefulWidget {
  final ReporteModel ficha;
  final Position? posicionActual;

  const GeofencingBloqueadoSheet({
    super.key,
    required this.ficha,
    this.posicionActual,
  });

  /// Muestra el bottom sheet de bloqueo por geofencing.
  static Future<void> show(
    BuildContext context, {
    required ReporteModel ficha,
    Position? posicionActual,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GeofencingBloqueadoSheet(
        ficha: ficha,
        posicionActual: posicionActual,
      ),
    );
  }

  @override
  State<GeofencingBloqueadoSheet> createState() =>
      _GeofencingBloqueadoSheetState();
}

class _GeofencingBloqueadoSheetState extends State<GeofencingBloqueadoSheet> {
  bool _useSatellite = false;

  /// Calcula la distancia en metros desde la posición actual al borde más
  /// cercano del cuadrante. Devuelve null si faltan datos.
  double? _calcularDistanciaAlCuadrante() {
    final pos = widget.posicionActual;
    final ficha = widget.ficha;
    if (pos == null ||
        ficha.cuadranteLatMin == null ||
        ficha.cuadranteLatMax == null ||
        ficha.cuadranteLngMin == null ||
        ficha.cuadranteLngMax == null) {
      return null;
    }

    // Punto más cercano dentro del rectángulo del cuadrante
    final closestLat =
        pos.latitude.clamp(ficha.cuadranteLatMin!, ficha.cuadranteLatMax!);
    final closestLng =
        pos.longitude.clamp(ficha.cuadranteLngMin!, ficha.cuadranteLngMax!);

    return Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      closestLat,
      closestLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ficha = widget.ficha;
    final pos = widget.posicionActual;
    final distancia = _calcularDistanciaAlCuadrante();

    // Ajustar cámara para que se vean tanto el cuadrante como la posición actual
    CameraFit? cameraFit;
    if (ficha.cuadranteLatMin != null && pos != null) {
      cameraFit = CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([
          LatLng(ficha.cuadranteLatMin!, ficha.cuadranteLngMin!),
          LatLng(ficha.cuadranteLatMax!, ficha.cuadranteLngMax!),
          LatLng(pos.latitude, pos.longitude),
        ]),
        padding: const EdgeInsets.all(40),
      );
    }

    final LatLng centerMapa;
    if (ficha.cuadranteLatMin != null) {
      centerMapa = LatLng(
        (ficha.cuadranteLatMin! + ficha.cuadranteLatMax!) / 2,
        (ficha.cuadranteLngMin! + ficha.cuadranteLngMax!) / 2,
      );
    } else if (pos != null) {
      centerMapa = LatLng(pos.latitude, pos.longitude);
    } else {
      centerMapa = const LatLng(0, 0);
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ─────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Icono + título ──────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.location_off, color: Colors.red, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fuera del área de búsqueda',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Debes estar dentro del cuadrante asignado para activar el tracking.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Distancia estimada ──────────────────────────────────────────
          if (distancia != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFFF9800).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.near_me, size: 16, color: Color(0xFFE65100)),
                  const SizedBox(width: 6),
                  Text(
                    distancia < 1000
                        ? 'Estás a ${distancia.round()} m del área'
                        : 'Estás a ${(distancia / 1000).toStringAsFixed(1)} km del área',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Mini mapa ───────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: centerMapa,
                        initialZoom: 13.5,
                        initialCameraFit: cameraFit,
                        interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none),
                      ),
                      children: [
                        MapTileLayer(useSatellite: _useSatellite),

                        // Polígono del cuadrante objetivo (en naranja/rojo)
                        if (ficha.cuadranteLatMin != null)
                          PolygonLayer(
                            polygons: [
                              Polygon(
                                points: [
                                  LatLng(ficha.cuadranteLatMax!,
                                      ficha.cuadranteLngMin!),
                                  LatLng(ficha.cuadranteLatMax!,
                                      ficha.cuadranteLngMax!),
                                  LatLng(ficha.cuadranteLatMin!,
                                      ficha.cuadranteLngMax!),
                                  LatLng(ficha.cuadranteLatMin!,
                                      ficha.cuadranteLngMin!),
                                ],
                                color: AppTheme.primary.withOpacity(0.2),
                                borderColor: AppTheme.primary,
                                borderStrokeWidth: 2.5,
                              ),
                            ],
                          ),

                        // Posición actual del usuario (punto azul)
                        if (pos != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(pos.latitude, pos.longitude),
                                width: 36,
                                height: 36,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.blue, width: 2),
                                  ),
                                  child: const Icon(Icons.person_pin_circle,
                                      color: Colors.blue, size: 20),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Leyenda del mapa
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _LegendItem(
                            color: AppTheme.primary, label: 'Zona objetivo'),
                        if (pos != null)
                          _LegendItem(color: Colors.blue, label: 'Tu posición'),
                      ],
                    ),
                  ),

                  // Toggle satélite
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _useSatellite = !_useSatellite),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          _useSatellite ? 'Mapa' : 'Satélite',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Instrucción ─────────────────────────────────────────────────
          const Text(
            'Dirígete al área azul del mapa. Una vez dentro, el tracking se activará automáticamente.',
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),

          const SizedBox(height: 20),

          // ── Botón cerrar ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Entendido',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget interno: ítem de leyenda ──────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
