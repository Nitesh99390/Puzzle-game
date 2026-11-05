import 'dart:math';

import 'package:flutter/material.dart';

import '../style/palette.dart';

/// Premium animated backdrop: deep gradient, slowly drifting light orbs and
/// twinkling stars. A single controller drives one CustomPainter inside a
/// RepaintBoundary, so it stays cheap even on low-end phones.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    this.child,
    this.colors = const [Palette.bgTop, Palette.bgMid, Palette.bgBottom],
    this.orbColors = const [
      Palette.saffron,
      Palette.violet,
      Palette.cyan,
      Palette.indiaGreen,
      Palette.pink,
    ],
  });

  final Widget? child;
  final List<Color> colors;
  final List<Color> orbColors;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();

  late final List<_Star> _stars;
  late final List<_Orb> _orbs;

  @override
  void initState() {
    super.initState();
    final r = Random(7);
    _stars = List.generate(
      60,
      (_) => _Star(
        Offset(r.nextDouble(), r.nextDouble()),
        0.6 + r.nextDouble() * 1.6,
        r.nextDouble() * pi * 2,
        1 + r.nextInt(3),
      ),
    );
    _orbs = List.generate(
      6,
      (i) => _Orb(
        Offset(r.nextDouble(), r.nextDouble()),
        0.22 + r.nextDouble() * 0.25,
        widget.orbColors[i % widget.orbColors.length],
        r.nextDouble() * pi * 2,
        0.04 + r.nextDouble() * 0.06,
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.colors,
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _BackgroundPainter(_c, _stars, _orbs),
            size: Size.infinite,
          ),
        ),
        ?widget.child,
      ],
    );
  }
}

class _Star {
  _Star(this.pos, this.size, this.phase, this.speed);
  final Offset pos;
  final double size;
  final double phase;
  final int speed;
}

class _Orb {
  _Orb(this.pos, this.radius, this.color, this.phase, this.drift);
  final Offset pos;
  final double radius;
  final Color color;
  final double phase;
  final double drift;
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.anim, this.stars, this.orbs) : super(repaint: anim);

  final Animation<double> anim;
  final List<_Star> stars;
  final List<_Orb> orbs;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value * pi * 2;
    final shortest = size.shortestSide;

    for (final o in orbs) {
      final c = Offset(
        (o.pos.dx + sin(t + o.phase) * o.drift) * size.width,
        (o.pos.dy + cos(t * 0.8 + o.phase) * o.drift) * size.height,
      );
      final r = o.radius * shortest * 1.4;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            o.color.withValues(alpha: 0.30),
            o.color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    final starPaint = Paint();
    for (final s in stars) {
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * s.speed * 6 + s.phase));
      starPaint.color = Colors.white.withValues(alpha: 0.55 * tw);
      canvas.drawCircle(
        Offset(s.pos.dx * size.width, s.pos.dy * size.height),
        s.size * (0.7 + 0.3 * tw),
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) => false;
}
