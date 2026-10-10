import 'package:flutter/material.dart';

/// Spacing, radius and touch-target sizes used across the app.
abstract final class AppSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double radius = 14;

  /// Minimum height of a tappable button (comfortable for thumbs).
  static const double touch = 52;
}

/// Colours of the app. There are two sets: standard, and high contrast
/// (black, white and stronger accents for readability).
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.highContrast,
    required this.background,
    required this.card,
    required this.cardSelected,
    required this.panel,
    required this.accent,
    required this.onAccent,
    required this.gold,
    required this.info,
    required this.danger,
    required this.text,
    required this.textMuted,
    required this.border,
  });

  static const AppPalette standard = AppPalette(
    highContrast: false,
    background: Color(0xFF0B1F3A),
    card: Color(0xFF13294A),
    cardSelected: Color(0xFF1D3B66),
    panel: Color(0xB30B1F3A),
    accent: Color(0xFFFF5A1F),
    onAccent: Color(0xFFFFFFFF),
    gold: Color(0xFFFFC107),
    info: Color(0xFF29B6F6),
    danger: Color(0xFFE53935),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xFFC9D3E3),
    border: Color(0x33FFFFFF),
  );

  static const AppPalette contrast = AppPalette(
    highContrast: true,
    background: Color(0xFF000000),
    card: Color(0xFF000000),
    cardSelected: Color(0xFF262626),
    panel: Color(0xFF000000),
    accent: Color(0xFFFF8A3D),
    onAccent: Color(0xFF000000),
    gold: Color(0xFFFFE600),
    info: Color(0xFF6EE7FF),
    danger: Color(0xFFFF5252),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xFFEDEDED),
    border: Color(0xFFFFFFFF),
  );

  /// The palette for the current theme (falls back to standard).
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? standard;

  final bool highContrast;
  final Color background;
  final Color card;
  final Color cardSelected;
  final Color panel;
  final Color accent;
  final Color onAccent;
  final Color gold;
  final Color info;
  final Color danger;
  final Color text;
  final Color textMuted;
  final Color border;

  @override
  AppPalette copyWith() => this;

  @override
  ThemeExtension<AppPalette> lerp(
    ThemeExtension<AppPalette>? other,
    double t,
  ) =>
      (other is AppPalette && t >= 0.5) ? other : this;
}
