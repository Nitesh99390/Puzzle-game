import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../style/palette.dart';

/// Full-screen confetti celebration driven by a [ConfettiController].
///
/// Fires from three emitters (top-centre blast plus two side cannons) so
/// the whole screen is covered.
class CelebrationOverlay extends StatelessWidget {
  const CelebrationOverlay({super.key, required this.controller});

  final ConfettiController controller;

  static const _colors = [
    Palette.accentPink,
    Palette.accentYellow,
    Palette.accentGreen,
    Palette.accentBlue,
    Color(0xFF9B5DE5),
    Color(0xFFF15BB5),
  ];

  Path _star(Size size) {
    const points = 5;
    final half = size.width / 2;
    final inner = half / 2.5;
    final path = Path();
    const step = pi / points;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? half : inner;
      final a = i * step - pi / 2;
      final p = Offset(half + r * cos(a), half + r * sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: controller,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              emissionFrequency: 0.06,
              maxBlastForce: 32,
              minBlastForce: 12,
              gravity: 0.18,
              colors: _colors,
              createParticlePath: _star,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: controller,
              blastDirection: -pi / 4,
              numberOfParticles: 25,
              emissionFrequency: 0.08,
              maxBlastForce: 45,
              minBlastForce: 20,
              gravity: 0.25,
              colors: _colors,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: controller,
              blastDirection: -3 * pi / 4,
              numberOfParticles: 25,
              emissionFrequency: 0.08,
              maxBlastForce: 45,
              minBlastForce: 20,
              gravity: 0.25,
              colors: _colors,
            ),
          ),
        ],
      ),
    );
  }
}
