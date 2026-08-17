import 'package:flutter/material.dart';

abstract final class AppColors {
  static const emerald = Color(0xFF00866C);
  static const emeraldDark = Color(0xFF006552);
  static const blue = Color(0xFF2869F6);
  static const navy = Color(0xFF101D2F);
  static const ink = Color(0xFF172235);
  static const mist = Color(0xFFF4F7F8);
  static const amber = Color(0xFFE2A91B);
  static const coral = Color(0xFFDE594B);
}

ThemeData buildLightTheme({bool highContrast = false}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.emerald,
    brightness: Brightness.light,
    primary: highContrast ? AppColors.emeraldDark : AppColors.emerald,
    secondary: AppColors.blue,
    surface: Colors.white,
  );
  return _buildTheme(
    scheme,
    brightness: Brightness.light,
    highContrast: highContrast,
  ).copyWith(
    scaffoldBackgroundColor: highContrast ? Colors.white : AppColors.mist,
  );
}

ThemeData buildDarkTheme({bool highContrast = false}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF36D0AC),
    brightness: Brightness.dark,
    primary: const Color(0xFF4ED7B6),
    secondary: const Color(0xFF7BA7FF),
    surface: const Color(0xFF18263A),
  );
  return _buildTheme(
    scheme,
    brightness: Brightness.dark,
    highContrast: highContrast,
  ).copyWith(scaffoldBackgroundColor: const Color(0xFF0E1929));
}

ThemeData _buildTheme(
  ColorScheme scheme, {
  required Brightness brightness,
  required bool highContrast,
}) {
  final dark = brightness == Brightness.dark;
  final border = highContrast
      ? scheme.onSurface.withValues(alpha: 0.55)
      : scheme.outlineVariant.withValues(alpha: dark ? 0.65 : 0.82);
  final theme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
  );
  return theme.copyWith(
    textTheme: theme.textTheme.copyWith(
      displaySmall: theme.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.06,
      ),
      headlineMedium: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      headlineSmall: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
      labelLarge: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border),
      ),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF122034) : const Color(0xFFF8FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: theme.chipTheme.copyWith(
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      groupAlignment: -0.82,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
