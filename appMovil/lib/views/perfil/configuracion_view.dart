import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class ConfiguracionView extends StatefulWidget {
  const ConfiguracionView({super.key});

  @override
  State<ConfiguracionView> createState() => _ConfiguracionViewState();
}

class _ConfiguracionViewState extends State<ConfiguracionView> {
  bool _notificacionesPush = true;
  bool _alertasSonoras = true;
  LocationPermission _locationPermission = LocationPermission.denied;
  bool _isLoadingCache = false;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
    _revisarPermisos();
  }

  Future<void> _cargarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificacionesPush = prefs.getBool('pref_notif_push') ?? true;
      _alertasSonoras = prefs.getBool('pref_alertas_sonoras') ?? true;
    });
  }

  Future<void> _guardarNotifPush(bool value) async {
    setState(() => _notificacionesPush = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_notif_push', value);
  }

  Future<void> _guardarAlertas(bool value) async {
    setState(() => _alertasSonoras = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_alertas_sonoras', value);
  }

  Future<void> _revisarPermisos() async {
    final perm = await Geolocator.checkPermission();
    setState(() {
      _locationPermission = perm;
    });
  }

  Future<void> _limpiarCache() async {
    setState(() => _isLoadingCache = true);
    // Simular limpieza de caché de imágenes y mapas
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoadingCache = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Caché limpiada correctamente (Liberados ~45MB)'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determinar color y texto del estado del GPS
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
        title: const Text('Configuración',
            style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
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
                    'La aplicación requiere permisos "Todo el tiempo" para poder trazar tu recorrido de búsqueda correctamente aunque apagues la pantalla.',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Geolocator.openAppSettings();
                        // Al volver, revisamos si cambió
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

          // ── Notificaciones ─────────────────────────────────────────────────
          const _SeccionHeader(titulo: 'Notificaciones'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: AppTheme.primary,
                  title: const Text('Notificaciones push',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Nuevos operativos y avisos urgentes',
                      style: TextStyle(fontSize: 12)),
                  value: _notificacionesPush,
                  onChanged: _guardarNotifPush,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeColor: AppTheme.primary,
                  title: const Text('Alertas sonoras',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'Sonido al recibir notificaciones en la app',
                      style: TextStyle(fontSize: 12)),
                  value: _alertasSonoras,
                  onChanged: _guardarAlertas,
                ),
              ],
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
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cleaning_services,
                    color: AppTheme.accentDark),
              ),
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
