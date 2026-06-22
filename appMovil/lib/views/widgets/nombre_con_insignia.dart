import 'package:flutter/material.dart';

class NombreConInsignia extends StatelessWidget {
  final String nombre;
  final int oro;
  final int plataBronce;
  final TextStyle? baseStyle;

  const NombreConInsignia({
    super.key,
    required this.nombre,
    this.oro = 0,
    this.plataBronce = 0,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = baseStyle?.color ?? Colors.blueGrey.shade800;
    IconData? badgeIcon;
    Color? badgeColor;

    if (oro > 0) {
      textColor = Colors.amber.shade700;
      badgeIcon = Icons.stars;
      badgeColor = Colors.amber.shade500;
    } else if (plataBronce >= 6) {
      textColor = Colors.blueGrey.shade600;
      badgeIcon = Icons.verified;
      badgeColor = Colors.blueGrey.shade400;
    } else if (plataBronce >= 1) {
      textColor = Colors.brown.shade500;
      badgeIcon = Icons.verified;
      badgeColor = Colors.brown.shade400;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            nombre,
            style: (baseStyle ?? const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)).copyWith(
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (badgeIcon != null) ...[
          const SizedBox(width: 4),
          Icon(badgeIcon, color: badgeColor, size: (baseStyle?.fontSize ?? 14) + 2),
        ],
      ],
    );
  }
}
