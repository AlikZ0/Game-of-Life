import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles the dark-first [ThemeData] used by [MaterialApp.router].
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        bg: AppColors.darkBg,
        surface: AppColors.darkSurface,
        surfaceHi: AppColors.darkSurfaceHi,
        card: AppColors.darkCard,
        border: AppColors.darkBorder,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceMuted: AppColors.textSecondaryDark,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        bg: AppColors.lightBg,
        surface: AppColors.lightSurface,
        surfaceHi: AppColors.lightSurfaceHi,
        card: AppColors.lightCard,
        border: AppColors.lightBorder,
        onSurface: AppColors.textPrimaryLight,
        onSurfaceMuted: AppColors.textSecondaryLight,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surfaceHi,
    required Color card,
    required Color border,
    required Color onSurface,
    required Color onSurfaceMuted,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.black,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.black,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceHi,
      outline: border,
      outlineVariant: border,
    );

    final TextTheme textTheme = AppTypography.textTheme(onSurface, onSurfaceMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      textTheme: textTheme,
      canvasColor: bg,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rLg,
          side: BorderSide(color: border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: border, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHi,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        hintStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceMuted),
        prefixIconColor: onSurfaceMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: AppColors.accent, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: AppColors.danger, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHi,
        selectedColor: AppColors.accent,
        side: BorderSide(color: border),
        labelStyle: textTheme.labelMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rPill),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: onSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : onSurfaceMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(textTheme.labelSmall),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rLg),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHi,
        contentTextStyle: textTheme.bodyMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: Colors.transparent,
      ),
    );
  }
}
