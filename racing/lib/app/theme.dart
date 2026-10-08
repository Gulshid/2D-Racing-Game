import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color seed = Color(0xFFFF5A1F);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1F3A),
      );
}
