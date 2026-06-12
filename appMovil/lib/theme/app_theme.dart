import 'package:flutter/material.dart';

class AppTheme {
  // ─── Paleta de identidad Echoes ────────────────────────────────────────────

  // Grises neutros — fondos y divisores
  static const Color backgroundLight  = Color(0xFFF8F8F8); // Fondo principal
  static const Color background       = Color(0xFFECECEC); // Fondo alternativo / divisores
  static const Color backgroundDark   = Color(0xFFDFDFDF); // Bordes, chips

  // Dorado — accent, FAB, botones de acción
  static const Color accent           = Color(0xFFE9C978); // Accent base
  static const Color accentDark       = Color(0xFFE5C062); // Pressed / hover
  static const Color accentLight      = Color(0xFFEDD28E); // Chips suaves / fondo destacado

  // Azul — color primario interactivo
  static const Color primary          = Color(0xFF3F7AC5); // Azul oscuro — nav activo, brand
  static const Color primaryBase      = Color(0xFF5388CB); // Azul base — links, chips
  static const Color primaryLight     = Color(0xFF6796D1); // Texto secundario azulado

  // Carbón azulado — texto y AppBar
  static const Color darkBase         = Color(0xFF353F4C); // AppBar, elementos oscuros
  static const Color darkDark         = Color(0xFF2B333D); // Texto principal
  static const Color darkLight        = Color(0xFF3F4B5B); // Texto secundario

  // Aliases para compatibilidad y semántica clara
  static const Color textPrimary      = darkDark;
  static const Color textSecondary    = darkLight;
  static const Color secondary        = primaryLight;  // íconos inactivos nav
  static const Color surface          = Colors.white;
  static const Color border           = backgroundDark;

  // ─── Semánticos (convenciones universales de color) ───────────────────────
  static const Color success = Color(0xFF16A34A); // Verde  — estado Activo
  static const Color warning = Color(0xFFF59E0B); // Ámbar  — estado Pausado
  static const Color danger  = Color(0xFFEF4444); // Rojo   — errores y alertas
  static const Color info    = Color(0xFF5388CB); // Azul   — información

  // ─── ThemeData ────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: primaryBase,
      surface: surface,
      error: danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundLight,

    // AppBar interno: carbón azulado oscuro
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBase,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),

    // Botones elevados → dorado accent
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: darkDark,
        minimumSize: const Size(double.infinity, 50),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // Botones con contorno → dorado accent
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentDark,
        side: const BorderSide(color: accent, width: 1.5),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // Campos de texto: bordes redondeados, foco en azul primario
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: primaryBase, width: 2),
      ),
      filled: true,
      fillColor: surface,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: const TextStyle(color: darkLight),
    ),

    // Tarjetas: blancas con sombra derivada de darkBase
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Color.fromRGBO(
        (darkBase.r * 255).round(),
        (darkBase.g * 255).round(),
        (darkBase.b * 255).round(),
        0.10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: border, width: 0.8),
      ),
      color: surface,
      clipBehavior: Clip.antiAlias,
    ),

    // FAB → dorado accent, forma de píldora
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: darkDark,
      elevation: 4,
      shape: StadiumBorder(),
    ),

    // Bottom navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: darkLight,
    ),

    // Slider (radio de búsqueda)
    sliderTheme: SliderThemeData(
      activeTrackColor: accent,
      thumbColor: accentDark,
      inactiveTrackColor: border,
      overlayColor: accent.withValues(alpha: 0.2),
    ),

    // CheckboxTheme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),

    // Tipografía global
    textTheme: const TextTheme(
      titleLarge:  TextStyle(color: darkDark,  fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: darkDark,  fontWeight: FontWeight.w600),
      bodyLarge:   TextStyle(color: darkDark),
      bodyMedium:  TextStyle(color: darkBase),
      bodySmall:   TextStyle(color: darkLight),
      labelSmall:  TextStyle(color: darkLight),
    ),
  );
}