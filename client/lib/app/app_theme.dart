import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _paper = Color(0xFFF4EFE7);
  static const _paperStrong = Color(0xFFFFFBF5);
  static const _navy = Color(0xFF18314F);
  static const _terracotta = Color(0xFFC76A43);
  static const _sage = Color(0xFF799F9A);
  static const _ink = Color(0xFF1E2430);

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _terracotta,
        brightness: Brightness.light,
        primary: _navy,
        secondary: _terracotta,
        surface: _paperStrong,
      ),
      scaffoldBackgroundColor: _paper,
      useMaterial3: true,
    );

    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme)
        .copyWith(
          displayLarge: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 50,
          ),
          displayMedium: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 40,
          ),
          displaySmall: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 32,
          ),
          headlineMedium: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
          headlineSmall: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
          titleLarge: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          titleMedium: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          bodyLarge: GoogleFonts.manrope(height: 1.35, fontSize: 16),
          bodyMedium: GoogleFonts.manrope(height: 1.35, fontSize: 14),
          labelLarge: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        )
        .apply(bodyColor: _ink, displayColor: _navy);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _navy,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: _paperStrong,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE8DED0)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _navy,
          side: const BorderSide(color: Color(0xFFCDC1AE)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _navy,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0D3C2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0D3C2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _terracotta, width: 1.4),
        ),
      ),
      dividerColor: const Color(0xFFE4D9CB),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _navy,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        KnightLinkPalette(
          navy: _navy,
          terracotta: _terracotta,
          sage: _sage,
          paper: _paper,
          paperStrong: _paperStrong,
          ink: _ink,
        ),
      ],
    );
  }
}

@immutable
class KnightLinkPalette extends ThemeExtension<KnightLinkPalette> {
  const KnightLinkPalette({
    required this.navy,
    required this.terracotta,
    required this.sage,
    required this.paper,
    required this.paperStrong,
    required this.ink,
  });

  final Color navy;
  final Color terracotta;
  final Color sage;
  final Color paper;
  final Color paperStrong;
  final Color ink;

  @override
  KnightLinkPalette copyWith({
    Color? navy,
    Color? terracotta,
    Color? sage,
    Color? paper,
    Color? paperStrong,
    Color? ink,
  }) {
    return KnightLinkPalette(
      navy: navy ?? this.navy,
      terracotta: terracotta ?? this.terracotta,
      sage: sage ?? this.sage,
      paper: paper ?? this.paper,
      paperStrong: paperStrong ?? this.paperStrong,
      ink: ink ?? this.ink,
    );
  }

  @override
  KnightLinkPalette lerp(ThemeExtension<KnightLinkPalette>? other, double t) {
    if (other is! KnightLinkPalette) {
      return this;
    }

    return KnightLinkPalette(
      navy: Color.lerp(navy, other.navy, t) ?? navy,
      terracotta: Color.lerp(terracotta, other.terracotta, t) ?? terracotta,
      sage: Color.lerp(sage, other.sage, t) ?? sage,
      paper: Color.lerp(paper, other.paper, t) ?? paper,
      paperStrong: Color.lerp(paperStrong, other.paperStrong, t) ?? paperStrong,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
    );
  }
}
