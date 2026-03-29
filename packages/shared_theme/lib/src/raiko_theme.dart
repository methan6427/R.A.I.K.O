import 'package:flutter/material.dart';
import 'raiko_colors.dart';

ThemeData buildRaikoTheme() {
  const baseTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      height: 1.05,
      letterSpacing: -0.8,
      color: RaikoColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: RaikoColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: RaikoColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: RaikoColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      height: 1.45,
      color: RaikoColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.45,
      color: RaikoColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: RaikoColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      color: RaikoColors.textMuted,
    ),
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: RaikoColors.accent,
    brightness: Brightness.dark,
    primary: RaikoColors.accent,
    secondary: RaikoColors.accentStrong,
    surface: RaikoColors.card,
    error: RaikoColors.danger,
  );

  return ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Segoe UI',
    scaffoldBackgroundColor: RaikoColors.background,
    colorScheme: colorScheme,
    textTheme: baseTextTheme,
    useMaterial3: true,
    canvasColor: Colors.transparent,
    dividerColor: RaikoColors.border,
    cardTheme: CardThemeData(
      color: RaikoColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: RaikoColors.borderStrong),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RaikoColors.backgroundRaised,
      labelStyle: const TextStyle(color: RaikoColors.textSecondary),
      hintStyle: const TextStyle(color: RaikoColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: RaikoColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: RaikoColors.accentStrong),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: RaikoColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: baseTextTheme.labelLarge,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: RaikoColors.textPrimary,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: RaikoColors.card,
      selectedColor: RaikoColors.accent,
      disabledColor: RaikoColors.border,
      side: const BorderSide(color: RaikoColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(color: RaikoColors.textPrimary, fontWeight: FontWeight.w600),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: RaikoColors.accent,
      textColor: RaikoColors.textPrimary,
    ),
  );
}
