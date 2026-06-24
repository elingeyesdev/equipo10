import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import 'login_view.dart';

/// Pantalla de onboarding que se muestra solo la primera vez.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.campaign_rounded,
      title: 'Reporta en segundos',
      subtitle:
          'Crea un reporte con foto, ubicación y descripción. Tu comunidad se entera de inmediato.',
    ),
    _SlideData(
      icon: Icons.people_alt_rounded,
      title: 'Únete a la búsqueda',
      subtitle:
          'Coordina con voluntarios en tiempo real. El mapa muestra cuadrantes y recorridos activos.',
    ),
    _SlideData(
      icon: Icons.location_on_rounded,
      title: 'Evidencias con GPS',
      subtitle:
          'Sube fotos geolocalizadas desde el campo. Las evidencias aparecen en el mapa al instante.',
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Column(
          children: [
            // ── Zona hero con el PageView de slides ──────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlideHero(
                  data: _slides[i],
                  currentPage: _currentPage,
                  totalPages: _slides.length,
                  onSkip: _finish,
                ),
              ),
            ),

            // ── Panel inferior fijo (blanco) ──────────────────────────────
            _BottomPanel(
              slides: _slides,
              currentPage: _currentPage,
              onNext: _nextPage,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero superior (cambia con el PageView) ────────────────────────────────────
class _SlideHero extends StatelessWidget {
  final _SlideData data;
  final int currentPage;
  final int totalPages;
  final VoidCallback onSkip;

  const _SlideHero({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.darkBase],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Círculo decorativo grande (fondo)
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Círculo decorativo pequeño (fondo)
            Positioned(
              bottom: 30,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Contenido del hero
            Column(
              children: [
                // Barra superior: marca + skip
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      // Logotipo textual
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'ECHOES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (currentPage < totalPages - 1)
                        GestureDetector(
                          onTap: onSkip,
                          child: Text(
                            'Saltar',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Icono central
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Anillo exterior (accent dorado)
                        Container(
                          width: 196,
                          height: 196,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            // Círculo interior con el icono
                            child: Container(
                              width: 148,
                              height: 148,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                data.icon,
                                size: 68,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Panel inferior fijo ───────────────────────────────────────────────────────
class _BottomPanel extends StatelessWidget {
  final List<_SlideData> slides;
  final int currentPage;
  final VoidCallback onNext;

  const _BottomPanel({
    required this.slides,
    required this.currentPage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final slide = slides[currentPage];
    final isLast = currentPage == slides.length - 1;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14353F4C),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra accent dorada decorativa
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Título animado
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                key: ValueKey(currentPage),
                child: Text(
                  slide.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkBase,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Subtítulo animado
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Text(
                slide.subtitle,
                key: ValueKey('sub_$currentPage'),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.65,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Dots + Botón en la misma fila
            Row(
              children: [
                // Dots de progreso
                Row(
                  children: List.generate(
                    slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(right: 6),
                      width: i == currentPage ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == currentPage
                            ? AppTheme.primary
                            : AppTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const Spacer(),

                // Botón Siguiente / Comenzar
                _NextButton(isLast: isLast, onTap: onNext),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ── Botón Siguiente / Comenzar ────────────────────────────────────────────────
class _NextButton extends StatefulWidget {
  final bool isLast;
  final VoidCallback onTap;

  const _NextButton({required this.isLast, required this.onTap});

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
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
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: 52,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isLast ? 28 : 20,
          ),
          decoration: BoxDecoration(
            color: widget.isLast ? AppTheme.accent : AppTheme.primary,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: (widget.isLast ? AppTheme.accent : AppTheme.primary)
                    .withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  widget.isLast ? 'Comenzar' : 'Siguiente',
                  key: ValueKey(widget.isLast),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: widget.isLast ? AppTheme.darkDark : Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  widget.isLast
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  key: ValueKey('icon_${widget.isLast}'),
                  size: 18,
                  color: widget.isLast ? AppTheme.darkDark : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Modelo de datos ───────────────────────────────────────────────────────────
class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
