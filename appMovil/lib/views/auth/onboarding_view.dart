import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import 'login_view.dart';

/// Pantalla de onboarding que se muestra solo la primera vez.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.campaign_rounded,
      title: 'Reporta en segundos',
      subtitle:
          'Crea un reporte con foto, ubicación y descripción. Tu comunidad se entera de inmediato.',
      gradientColors: [Color(0xFF0F1F5C), Color(0xFF1E3A8A)],
      iconColor: Color(0xFF7DAFFF),
    ),
    _SlideData(
      icon: Icons.people_alt_rounded,
      title: 'Únete a la búsqueda',
      subtitle:
          'Coordina con voluntarios en tiempo real. El mapa muestra cuadrantes y recorridos activos.',
      gradientColors: [Color(0xFF1A0E4E), Color(0xFF3B1FA8)],
      iconColor: Color(0xFFA78BFA),
    ),
    _SlideData(
      icon: Icons.location_on_rounded,
      title: 'Evidencias con GPS',
      subtitle:
          'Sube fotos geolocalizadas desde el campo. Las evidencias aparecen en el mapa al instante.',
      gradientColors: [Color(0xFF0B2240), Color(0xFF0C4A6E)],
      iconColor: Color(0xFF38BDF8),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const LoginView(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Slides ────────────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _SlideScreen(data: _slides[i]),
          ),

          // ── Barra superior: dots + skip ───────────────────────────────
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  // Dots de progreso
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _currentPage ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? Colors.white
                              : Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Skip
                  if (_currentPage < _slides.length - 1)
                    GestureDetector(
                      onTap: _finish,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1),
                        ),
                        child: const Text(
                          'Saltar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Botón inferior ────────────────────────────────────────────
          Positioned(
            left: 28,
            right: 28,
            bottom: 52,
            child: _AnimatedButton(
              isLast: _currentPage == _slides.length - 1,
              onTap: _nextPage,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide individual ──────────────────────────────────────────────────────────
class _SlideScreen extends StatelessWidget {
  final _SlideData data;
  const _SlideScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: data.gradientColors,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          // Espacio abajo para el botón (54px alto + 52 bottom + margen)
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 130),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Círculo de fondo + icono en el mismo Stack centrado
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Círculo decorativo
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: data.iconColor.withOpacity(0.12),
                      ),
                    ),
                    // Icono con glassmorphism
                    ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: data.iconColor.withOpacity(0.18),
                            border: Border.all(
                              color: data.iconColor.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            data.icon,
                            size: 64,
                            color: data.iconColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Título
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 16),

              // Subtítulo (sin \n, se envuelve solo con el padding lateral)
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.70),
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Botón animado ─────────────────────────────────────────────────────────────
class _AnimatedButton extends StatefulWidget {
  final bool isLast;
  final VoidCallback onTap;
  const _AnimatedButton({required this.isLast, required this.onTap});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 54,
          decoration: BoxDecoration(
            color: widget.isLast
                ? Colors.white
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: widget.isLast
                ? null
                : Border.all(
                    color: Colors.white.withOpacity(0.4), width: 1.5),
            boxShadow: widget.isLast
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: widget.isLast ? AppTheme.primary : Colors.white,
              letterSpacing: 0.2,
            ),
            child: Text(widget.isLast ? 'Comenzar' : 'Siguiente'),
          ),
        ),
      ),
    );
  }
}

// ── Modelo de datos de slide ──────────────────────────────────────────────────
class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color iconColor;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.iconColor,
  });
}
