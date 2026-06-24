import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';

class ConfiguracionView extends StatefulWidget {
  const ConfiguracionView({super.key});

  @override
  State<ConfiguracionView> createState() => _ConfiguracionViewState();
}

class _ConfiguracionViewState extends State<ConfiguracionView> {
  LocationPermission _locationPermission = LocationPermission.denied;
  bool _isLoadingCache = false;

  @override
  void initState() {
    super.initState();
    _revisarPermisos();
  }

  Future<void> _revisarPermisos() async {
    final perm = await Geolocator.checkPermission();
    setState(() => _locationPermission = perm);
  }

  Future<void> _limpiarCache() async {
    setState(() => _isLoadingCache = true);
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await CachedNetworkImage.evictFromCache('');
      await DefaultCacheManager().emptyCache();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isLoadingCache = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Caché de imágenes limpiada correctamente'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color gpsColor;
    String gpsText;
    IconData gpsIcon;

    switch (_locationPermission) {
      case LocationPermission.always:
        gpsColor = AppTheme.success;
        gpsText = 'Óptimo (permitido todo el tiempo)';
        gpsIcon = Icons.location_on;
        break;
      case LocationPermission.whileInUse:
        gpsColor = AppTheme.warning;
        gpsText = 'Restringido (solo en uso)';
        gpsIcon = Icons.location_on_outlined;
        break;
      default:
        gpsColor = AppTheme.danger;
        gpsText = 'Denegado';
        gpsIcon = Icons.location_off;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: AppTheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppTheme.primary),
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Permisos de Ubicación ──────────────────────────────────────────
          const _SeccionHeader(titulo: 'Permisos de ubicación'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(gpsIcon, color: gpsColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estado del GPS',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              gpsText,
                              style: TextStyle(
                                  color: gpsColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'La aplicación requiere permisos "Todo el tiempo" para trazar tu recorrido de búsqueda correctamente aunque apagues la pantalla.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Geolocator.openAppSettings();
                        _revisarPermisos();
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Abrir ajustes del sistema'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Almacenamiento ─────────────────────────────────────────────────
          const _SeccionHeader(titulo: 'Almacenamiento'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.cleaning_services,
                  color: AppTheme.accentDark, size: 28),
              title: const Text('Limpiar caché',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Mapas e imágenes temporales',
                  style: TextStyle(fontSize: 12)),
              trailing: _isLoadingCache
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _isLoadingCache ? null : _limpiarCache,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionHeader extends StatelessWidget {
  final String titulo;
  const _SeccionHeader({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
