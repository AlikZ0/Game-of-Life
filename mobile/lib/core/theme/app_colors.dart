import 'package:flutter/material.dart';

/// Central color tokens for Life Quest.
///
/// Dark-first: the app defaults to the dark palette, with a matching light
/// palette for users who prefer it. Semantic colors (rarity, difficulty) are
/// shared across both themes so game data reads consistently.
abstract final class AppColors {
  const AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF7C5CFF); // electric violet
  static const Color accentSoft = Color(0xFF9B82FF);
  static const Color accentDeep = Color(0xFF5B3FE0);
  static const Color secondary = Color(0xFF35D0BA); // teal
  static const Color tertiary = Color(0xFFFF7A9A); // pink

  // ── Dark surfaces ─────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0B0B12);
  static const Color darkSurface = Color(0xFF14141F);
  static const Color darkSurfaceHi = Color(0xFF1C1C2B);
  static const Color darkCard = Color(0xFF191926);
  static const Color darkBorder = Color(0xFF2A2A3D);

  // ── Light surfaces ────────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF6F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHi = Color(0xFFEFEFF6);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE3E3EE);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF4F4FA);
  static const Color textSecondaryDark = Color(0xFFA6A6C0);
  static const Color textPrimaryLight = Color(0xFF16161E);
  static const Color textSecondaryLight = Color(0xFF5C5C72);

  // ── Feedback ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF3ED598);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5470);
  static const Color info = Color(0xFF4DA3FF);

  // ── Game accents ──────────────────────────────────────────────────────────
  static const Color xp = Color(0xFF7C5CFF);
  static const Color gold = Color(0xFFFFC848);
  static const Color hp = Color(0xFFFF5470);
  static const Color energy = Color(0xFF35D0BA);

  /// Rarity → color (matches Prisma `Rarity` enum).
  static const Map<String, Color> rarity = {
    'BRONZE': Color(0xFFCD7F32),
    'SILVER': Color(0xFFB6C0D0),
    'GOLD': Color(0xFFFFC848),
    'LEGENDARY': Color(0xFFB14BFF),
  };

  /// Difficulty → color (matches Prisma `Difficulty` enum).
  static const Map<String, Color> difficulty = {
    'TRIVIAL': Color(0xFF7C8AA5),
    'EASY': Color(0xFF3ED598),
    'MEDIUM': Color(0xFF4DA3FF),
    'HARD': Color(0xFFFFB020),
    'EPIC': Color(0xFFFF5470),
  };

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF5B3FE0), Color(0xFF7C5CFF), Color(0xFFB14BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD780), Color(0xFFFFC848)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
