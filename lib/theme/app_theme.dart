import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static TextStyle display({
    double size = 32,
    FontWeight weight = FontWeight.w700,
    Color color = Colors.white,
    double? height,
    double letterSpacing = -0.4,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = EdgeColors.slate300,
    double? height,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = Colors.white,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  static TextStyle eyebrow() => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: EdgeColors.accent,
        letterSpacing: 2.4,
      );

  static TextStyle label() => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: EdgeColors.muted,
        letterSpacing: 1.2,
      );

  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: EdgeColors.bg,
      canvasColor: EdgeColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: EdgeColors.accent,
        secondary: EdgeColors.accentHi,
        surface: EdgeColors.card,
        onPrimary: EdgeColors.bg,
        onSurface: Colors.white,
        error: EdgeColors.danger,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: EdgeColors.slate300,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      splashFactory: InkRipple.splashFactory,
      splashColor: EdgeColors.accent.withOpacity(0.10),
      highlightColor: EdgeColors.accent.withOpacity(0.06),
      dividerColor: EdgeColors.white06,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EdgeColors.surface.withOpacity(0.7),
        hintStyle: sans(size: 14, color: EdgeColors.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EdgeColors.white08),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EdgeColors.white08),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: EdgeColors.accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EdgeColors.danger),
        ),
      ),
    );
  }
}
