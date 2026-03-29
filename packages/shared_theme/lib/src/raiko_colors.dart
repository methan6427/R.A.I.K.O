import 'package:flutter/material.dart';

abstract final class RaikoColors {
  static const background = Color(0xFF0B1020);
  static const backgroundDeep = Color(0xFF060914);
  static const backgroundRaised = Color(0xFF11192B);
  static const card = Color(0xFF121A2F);
  static const cardElevated = Color(0xFF18233C);
  static const accent = Color(0xFF8FB8FF);
  static const accentStrong = Color(0xFF55E6FF);
  static const accentSoft = Color(0xFF5C78FF);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const border = Color(0xFF243250);
  static const borderStrong = Color(0xFF34507D);
  static const textPrimary = Color(0xFFF4F7FB);
  static const textSecondary = Color(0xFFA7B4D0);
  static const textMuted = Color(0xFF6D7C9E);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF09101F),
      Color(0xFF0C1830),
      Color(0xFF09101A),
    ],
  );

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xEE18233C),
      Color(0xDD10192E),
    ],
  );
}
