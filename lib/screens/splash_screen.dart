import 'dart:math';

import 'package:flutter/material.dart';

import '../style/palette.dart';

/// Animated first-load screen: tricolour pour, logo reveal, tagline.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  late final AnimationController _text = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _fill.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _text.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    await _exit.forward();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _fill.dispose();
    _text.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.0).animate(_exit),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 230,
            width: 120,
            child: AnimatedBuilder(
              animation: _fill,
              builder: (context, _) => CustomPaint(
                painter: _SplashTubePainter(_fill.value),
              ),
            ),
          ),
          const SizedBox(height: 26),
          FadeTransition(
            opacity: _text,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: _text, curve: Curves.easeOutBack),
              ),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (r) => Palette.tricolor.createShader(r),
                    child: const Text(
                      'COLOR POUR',
                      style: TextStyle(
                        fontFamily: Palette.displayFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 44,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Text(
                    'NETA EDITION',
                    style: TextStyle(
                      fontFamily: Palette.bodyFont,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 6,
                      color: Palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashTubePainter extends CustomPainter {
  _SplashTubePainter(this.t);
  final double t;

  static const _cols = [
    Palette.saffron,
    Colors.white,
    Palette.indiaGreen,
    Palette.chakraBlue,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 14, size.width - 12, size.height - 20);
    final rr = RRect.fromRectAndRadius(
      rect,
      Radius.circular((size.width - 12) / 2),
    );
    canvas.drawRRect(
      rr,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.save();
    canvas.clipRRect(rr);
    final fillH = (size.height - 20) * Curves.easeInOutCubic.transform(t);
    final bottom = rect.bottom;
    for (var i = 0; i < _cols.length; i++) {
      final segH = (size.height - 20) / _cols.length;
      final top = bottom - (i + 1) * segH;
      final visible = (bottom - fillH - top).clamp(0.0, segH);
      if (visible <= 0) continue;
      final r = Rect.fromLTWH(rect.left, bottom - fillH, rect.width, visible);
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color.lerp(_cols[i], Colors.black, 0.2)!,
              Color.lerp(_cols[i], Colors.white, 0.25)!,
              _cols[i],
            ],
          ).createShader(r),
      );
    }
    // Wave on the surface.
    if (t < 1) {
      final y = bottom - fillH;
      final wave = Path()..moveTo(rect.left, y);
      for (var x = 0.0; x <= rect.width; x += 6) {
        wave.lineTo(
          rect.left + x,
          y + sin(x / 14 + t * 14) * 3 * (1 - t),
        );
      }
      wave
        ..lineTo(rect.right, bottom)
        ..lineTo(rect.left, bottom)
        ..close();
      canvas.drawPath(
        wave,
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
    }
    canvas.restore();
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.6),
    );
    // Bubbles rising.
    for (var i = 0; i < 7; i++) {
      final phase = (t * 1.4 + i * 0.17) % 1;
      final x = rect.left + 12 + (i * 37) % (rect.width - 24);
      final y = rect.bottom - phase * fillH;
      if (y < rect.bottom - fillH) continue;
      canvas.drawCircle(
        Offset(x, y),
        2 + (i % 3),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5 * (1 - phase)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashTubePainter old) => old.t != t;
}
