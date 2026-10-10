import 'package:flutter/material.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/data/models/app_settings.dart';

/// Builds the app theme from the user's settings (high contrast, etc.).
abstract final class AppTheme {
  static ThemeData build(AppSettings settings) {
    final p = settings.highContrast ? AppPalette.contrast : AppPalette.standard;
    final scheme = ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: p.accent,
      onPrimary: p.onAccent,
      surface: p.card,
      onSurface: p.text,
      outline: p.border,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      dividerColor: p.border,
      extensions: [p],
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: p.text,
            displayColor: p.text,
          ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          side: BorderSide(color: p.textMuted),
        ),
      ),
    );
  }
}
