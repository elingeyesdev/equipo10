import 'package:flutter/material.dart';

class AppTheme {
  // Paleta: Azul profundo + Azul brillante (Estilo Web Amigate)
  static const Color primary = Color(0xFF1E3A8A);      // Azul oscuro (Tailwind blue-900)
  static const Color primaryLight = Color(0xFF3B82F6);  // Azul vibrante (Tailwind blue-500)
  static const Color accent = Color(0xFF7C3AED);        // Púrpura (Tailwind violet-600)
  static const Color accentLight = Color(0xFFA78BFA);   // Púrpura claro
  
  // Colores semánticos
  static const Color success = Color(0xFF10B981);       // Verde esmeralda
  static const Color danger = Color(0xFFEF4444);        // Rojo coral
  static const Color warning = Color(0xFFF59E0B);       // Ámbar
  static const Color info = Color(0xFF06B6D4);          // Cian
  
  // Fondos y texto
  static const Color background = Color(0xFFF8FAFC);    // Gris azulado muy claro (Slate 50)
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);   // Texto principal (Slate 800)
  static const Color textSecondary = Color(0xFF64748B); // Texto secundario (Slate 500)
  static const Color border = Color(0xFFE2E8F0);        // Bordes suaves (Slate 200)

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: primaryLight,
          surface: surface,
          error: danger,
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary, width: 1.5),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryLight, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: const TextStyle(color: textSecondary),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: border, width: 1),
          ),
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      );
}
