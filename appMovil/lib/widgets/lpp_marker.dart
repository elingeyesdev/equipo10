import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Marcador personalizado para el Punto LPP (Último Punto de Paradero).
/// Muestra la foto de la persona desaparecida dentro de un pin circular,
/// con su nombre debajo. Si no hay foto, muestra un icono de persona.
class LppMarker extends StatelessWidget {
  /// URL de la foto de la persona (puede ser null).
  final String? fotoUrl;

  /// Nombre o título del reporte (persona desaparecida).
  final String? nombre;

  /// Color principal del marcador (opcional, por defecto rojo).
  final Color? color;

  const LppMarker({
    super.key,
    this.fotoUrl,
    this.nombre,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pin con foto
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: color ?? const Color(0xFFD32F2F), width: 3),
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
                ? CachedNetworkImage(
                    imageUrl: fotoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _defaultIcon(),
                    placeholder: (_, __) => _loadingSpinner(),
                  )
                : _defaultIcon(),
          ),
        ),

        // Triángulo del pin
        CustomPaint(
          size: const Size(14, 8),
          painter: _PinTrianglePainter(color: color ?? const Color(0xFFD32F2F)),
        ),
      ],
    );
  }

  Widget _defaultIcon() {
    return Container(
      color: const Color(0xFFFFEBEE),
      child: Icon(
        Icons.person,
        color: color ?? const Color(0xFFD32F2F),
        size: 32,
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
          color: color ?? const Color(0xFFD32F2F),
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
