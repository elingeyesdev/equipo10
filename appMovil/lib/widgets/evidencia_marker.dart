import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Marcador personalizado para evidencias fotográficas en el mapa.
/// Muestra la miniatura de la foto capturada dentro de un pin con
/// estilo "polaroid", con un badge de cámara para diferenciarlo
/// visualmente del marcador LPP y de las pistas de información.
class EvidenciaMarker extends StatelessWidget {
  /// URL de la foto de la evidencia capturada (puede ser null).
  final String? fotoUrl;

  /// Nombre del voluntario que capturó la evidencia.
  final String? nombreVoluntario;

  const EvidenciaMarker({
    super.key,
    this.fotoUrl,
    this.nombreVoluntario,
  });

  // Colores de la paleta de evidencias (Morado)
  static const Color _colorBorde = Color(0xFF8B5CF6); // Purple-500
  static const Color _colorFondo = Color(0xFFF5F3FF); // Purple-50
  static const Color _colorBadge = Color(0xFFA78BFA); // Purple-400

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Contenedor principal tipo "polaroid" ──────────────────────────
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Marco del pin (estilo polaroid)
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: _colorBorde, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: fotoUrl != null && fotoUrl!.isNotEmpty
                    ? Image(
                        image: CachedNetworkImageProvider(fotoUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultIcon(),
                        frameBuilder: (_, child, frame, __) => child,
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : _loadingSpinner(),
                      )
                    : _defaultIcon(),
              ),
            ),

            // Badge de cámara (arriba a la derecha)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _colorBadge,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.photo_camera,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),

        // ── Triángulo del pin ─────────────────────────────────────────────
        CustomPaint(
          size: const Size(14, 8),
          painter: _PinTrianglePainter(color: _colorBorde),
        ),

        // ── Etiqueta con nombre del voluntario ────────────────────────────
        if (nombreVoluntario != null && nombreVoluntario!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _colorFondo,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _colorBorde.withValues(alpha: 0.4)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              nombreVoluntario!,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _colorBorde,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _defaultIcon() {
    return const ColoredBox(
      color: _colorFondo,
      child: Icon(
        Icons.photo_camera,
        color: _colorBorde,
        size: 30,
      ),
    );
  }

  Widget _loadingSpinner() {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _colorBorde,
        ),
      ),
    );
  }
}

/// Pinta el triángulo inferior del pin.
class _PinTrianglePainter extends CustomPainter {
  final Color color;
  _PinTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
