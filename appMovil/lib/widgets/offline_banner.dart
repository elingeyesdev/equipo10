import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Barra de estado que se muestra en la parte superior de la pantalla cuando:
///   - El dispositivo pierde la conexión (rojo), o
///   - La latencia supera el umbral configurado (amarillo — modo lento).
///
/// Desaparece automáticamente al restaurarse una conexión de buena calidad.
///
/// E9.1 — Módulo Offline: Indicador visual de estado de red.
/// E9.4 — Módulo Offline: Indicador de latencia alta / señal débil.
class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  final ConnectivityService _connectivity = ConnectivityService();

  StreamSubscription<bool>? _statusSub;
  StreamSubscription<int>? _latencySub;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  bool _mostrarBanner = false;
  _BannerEstado _estado = _BannerEstado.sinRed;
  Timer? _ocultarTimer;

  static const _duracionMensajeOk = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Estado inicial
    _evaluarEstado();

    // Suscripción a cambios de conectividad
    _statusSub = _connectivity.statusStream.listen((_) => _evaluarEstado());

    // Suscripción a cambios de latencia
    _latencySub = _connectivity.latencyStream.listen((_) => _evaluarEstado());
  }

  void _evaluarEstado() {
    _ocultarTimer?.cancel();

    if (!_connectivity.isOnline) {
      _mostrar(_BannerEstado.sinRed);
    } else if (_connectivity.isHighLatency) {
      _mostrar(_BannerEstado.latenciaAlta);
    } else {
      // Red normal: si había un banner activo, mostramos brevemente "OK"
      if (_mostrarBanner) {
        _mostrar(_BannerEstado.restaurada);
        _ocultarTimer = Timer(_duracionMensajeOk, () {
          if (mounted) {
            _controller.reverse().then((_) {
              if (mounted) setState(() => _mostrarBanner = false);
            });
          }
        });
      }
    }
  }

  void _mostrar(_BannerEstado nuevoEstado) {
    if (!mounted) return;
    setState(() {
      _mostrarBanner = true;
      _estado = nuevoEstado;
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _latencySub?.cancel();
    _ocultarTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_mostrarBanner)
          SlideTransition(
            position: _slideAnimation,
            child: _BannerContent(
              estado: _estado,
              latencyMs: _connectivity.latencyMs,
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

enum _BannerEstado { sinRed, latenciaAlta, restaurada }

/// Contenido visual del banner — tres estados con colores distintos.
class _BannerContent extends StatelessWidget {
  final _BannerEstado estado;
  final int latencyMs;
  const _BannerContent({required this.estado, required this.latencyMs});

  @override
  Widget build(BuildContext context) {
    final (color, icon, mensaje) = switch (estado) {
      _BannerEstado.sinRed => (
          const Color(0xFFDC2626),
          Icons.wifi_off_rounded,
          'Sin conexión — datos desde caché local',
        ),
      _BannerEstado.latenciaAlta => (
          const Color(0xFFF59E0B),
          Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
          'Señal débil (${latencyMs}ms) — mostrando datos locales',
        ),
      _BannerEstado.restaurada => (
          const Color(0xFF10B981),
          Icons.wifi,
          'Conexión restaurada',
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                mensaje,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
