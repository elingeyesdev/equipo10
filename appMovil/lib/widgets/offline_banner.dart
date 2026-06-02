import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Barra de estado que se muestra en la parte superior de la pantalla cuando
/// el dispositivo pierde la conexión a internet y desaparece automáticamente
/// cuando la conexión se restaura.
///
/// Uso recomendado: envolver el [body] del [Scaffold] con este widget.
///
/// ```dart
/// Scaffold(
///   body: OfflineBanner(child: miContenido),
/// )
/// ```
///
/// E9.1 — Módulo Offline: Indicador visual del estado de red para el usuario.
class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  final ConnectivityService _connectivity = ConnectivityService();
  StreamSubscription<bool>? _subscription;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  bool _mostrarBanner = false;
  // Cuánto tiempo mostrar el banner "Conexión restaurada" antes de ocultarlo
  static const _duracionMensajeOk = Duration(seconds: 2);
  Timer? _ocultarTimer;

  @override
  void initState() {
    super.initState();

    // Animación de deslizamiento hacia abajo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Estado inicial (sin animación)
    _mostrarBanner = !_connectivity.isOnline;
    if (_mostrarBanner) _controller.value = 1.0;

    // Escuchar cambios futuros
    _subscription = _connectivity.statusStream.listen(_onStatusChange);
  }

  void _onStatusChange(bool online) {
    _ocultarTimer?.cancel();

    if (!online) {
      // Sin red → mostrar banner rojo inmediatamente
      setState(() => _mostrarBanner = true);
      _controller.forward();
    } else {
      // Volvió la red → mostrar brevemente el banner verde y luego ocultar
      setState(() => _mostrarBanner = true);
      _controller.forward();
      _ocultarTimer = Timer(_duracionMensajeOk, () {
        if (mounted) {
          _controller.reverse().then((_) {
            if (mounted) setState(() => _mostrarBanner = false);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
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
            child: _BannerContent(isOnline: _connectivity.isOnline),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Contenido visual del banner. Se renderiza diferente según el estado de red.
class _BannerContent extends StatelessWidget {
  final bool isOnline;
  const _BannerContent({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: isOnline ? const Color(0xFF10B981) : const Color(0xFFDC2626),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isOnline
                  ? 'Conexión restaurada'
                  : 'Sin conexión — modo sin red activado',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
