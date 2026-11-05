import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../style/palette.dart';

/// Full-screen confetti + tricolour ribbon celebration.
class CelebrationOverlay extends StatelessWidget {
  const CelebrationOverlay({super.key, required this.controller});

  final ConfettiController controller;

  static const _colors = [
    Palette.saffron,
    Palette.gold,
    Palette.indiaGreen,
    Palette.chakraBlue,
    Palette.pink,
    Palette.cyan,
    Colors.white,
  ];

  Path _star(Size size) {
    const points = 5;
    final half = size.width / 2;
    final inner = half / 2.4;
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

  Path _ribbon(Size size) => Path()
    ..addRect(
      Rect.fromLTWH(0, size.height * 0.35, size.width, size.height * 0.3),
    );

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
              numberOfParticles: 46,
              emissionFrequency: 0.045,
              maxBlastForce: 34,
              minBlastForce: 12,
              gravity: 0.16,
              colors: _colors,
              createParticlePath: _star,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: controller,
              blastDirection: -pi / 4,
              numberOfParticles: 30,
              emissionFrequency: 0.05,
              maxBlastForce: 52,
              minBlastForce: 22,
              gravity: 0.24,
              colors: _colors,
              createParticlePath: _ribbon,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: controller,
              blastDirection: -3 * pi / 4,
              numberOfParticles: 30,
              emissionFrequency: 0.05,
              maxBlastForce: 52,
              minBlastForce: 22,
              gravity: 0.24,
              colors: _colors,
              createParticlePath: _ribbon,
            ),
          ),
        ],
      ),
    );
  }
}
