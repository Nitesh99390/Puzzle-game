import 'package:flutter/material.dart';

/// Central colour palette for Color Pour.
class Palette {
  Palette._();

  static const Color ink = Color(0xFF352B42);
  static const Color inkLight = Color(0xFF6B5E7A);
  static const Color trueWhite = Color(0xFFFFFFFF);

  static const Color backgroundMain = Color(0xFFFFFFD1);
  static const Color backgroundLevelSelection = Color(0xFFA2DCC7);
  static const Color backgroundPlaySession = Color(0xFFFFEBB5);
  static const Color backgroundSettings = Color(0xFFBFC8E3);

  static const Color accentPink = Color(0xFFEF476F);
  static const Color accentYellow = Color(0xFFFFD166);
  static const Color accentGreen = Color(0xFF06D6A0);
  static const Color accentBlue = Color(0xFF118AB2);

  /// Liquid colours used by the puzzle (index = colour id).
  static const List<Color> liquids = [
    Color(0xFFE63946), // red
    Color(0xFF457B9D), // blue
    Color(0xFF2A9D8F), // teal
    Color(0xFFF4A261), // orange
    Color(0xFF9B5DE5), // purple
    Color(0xFFFFD60A), // yellow
    Color(0xFF80ED99), // mint
    Color(0xFFF15BB5), // pink
    Color(0xFF6D4C41), // brown
    Color(0xFF00BBF9), // sky
    Color(0xFF8D99AE), // grey
    Color(0xFF3A0CA3), // indigo
  ];

  static const String displayFont = 'Permanent Marker';
}
