import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale for Life Quest.
///
/// Display / headings use **Sora** (geometric, premium), body uses **Inter**
/// (highly legible). Built on top of a base [TextTheme] so it inherits the
/// correct on-surface color per theme.
abstract final class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(Color onSurface, Color onSurfaceMuted) {
    final TextTheme display = GoogleFonts.soraTextTheme();
    final TextTheme body = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: onSurface,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: onSurface,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.45,
        color: onSurface,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
        color: onSurface,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.4,
        color: onSurfaceMuted,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: onSurface,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: onSurfaceMuted,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: onSurfaceMuted,
      ),
    );
  }

  /// Tabular numerals for stat readouts (XP, gold counters).
  static TextStyle numeric(TextStyle base) => base.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
