import 'package:flutter/material.dart';

/// Central colour palette & typography for Color Pour – Neta Edition.
///
/// Dark, premium "night-sky" look with Indian tricolour accents.
class Palette {
  Palette._();

  // Backgrounds
  static const Color bgTop = Color(0xFF140B2E);
  static const Color bgMid = Color(0xFF24145A);
  static const Color bgBottom = Color(0xFF3A1670);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC9C1E8);
  static const Color textMuted = Color(0xFF8D84B5);

  // Accents
  static const Color saffron = Color(0xFFFF9933);
  static const Color indiaGreen = Color(0xFF1FB34A);
  static const Color chakraBlue = Color(0xFF3D5AFE);
  static const Color gold = Color(0xFFFFC94A);
  static const Color pink = Color(0xFFFF4D8D);
  static const Color cyan = Color(0xFF36E2FF);
  static const Color violet = Color(0xFF9D6BFF);
  static const Color danger = Color(0xFFFF5470);

  // Glass surfaces
  static Color glass([double a = 0.10]) => Colors.white.withValues(alpha: a);
  static Color glassBorder([double a = 0.22]) =>
      Colors.white.withValues(alpha: a);

  static const LinearGradient tricolor = LinearGradient(
    colors: [saffron, Color(0xFFFFFFFF), indiaGreen],
  );

  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB347), Color(0xFFFF6A3D)],
  );
  static const LinearGradient blueButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B8CFF), Color(0xFF7A4DFF)],
  );
  static const LinearGradient greenButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3BE38A), Color(0xFF119C6B)],
  );
  static const LinearGradient pinkButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6FA5), Color(0xFFE5337A)],
  );
  static const LinearGradient goldButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE07A), Color(0xFFFFA928)],
  );

  /// Liquid colours used by the puzzle (index = colour id). Chosen to be
  /// vivid and clearly distinguishable from each other.
  static const List<Color> liquids = [
    Color(0xFFFF3B5C), // red
    Color(0xFF2F7BFF), // blue
    Color(0xFF22D39B), // emerald
    Color(0xFFFF9A1F), // saffron orange
    Color(0xFFA05CFF), // purple
    Color(0xFFFFE03B), // yellow
    Color(0xFF9BF06B), // lime
    Color(0xFFFF5FC8), // pink
    Color(0xFF8A5A3C), // brown
    Color(0xFF3DE3FF), // sky
    Color(0xFFE8E8F0), // pearl white
    Color(0xFF3B2BB8), // indigo
  ];

  static const String displayFont = 'Baloo';
  static const String bodyFont = 'Fredoka';

  static const TextStyle display = TextStyle(
    fontFamily: displayFont,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    height: 1.05,
  );

  static const TextStyle body = TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
}
