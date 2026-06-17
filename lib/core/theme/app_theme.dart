import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color seed = Color(0xFF5B4FE9);

  /// Paleta kolorów przypisywanych przedmiotom (po kolei).
  static const List<Color> subjectPalette = [
    Color(0xFF5B4FE9),
    Color(0xFF00897B),
    Color(0xFFF4511E),
    Color(0xFFD81B60),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
  ];

  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }
}
