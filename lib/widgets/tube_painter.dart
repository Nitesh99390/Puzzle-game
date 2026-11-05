import 'dart:math';

import 'package:flutter/material.dart';

import '../style/palette.dart';

/// One visible liquid band: colour id + amount in "units" (can be fractional
/// while a pour is animating).
class LiquidBand {
  const LiquidBand(this.color, this.units);
  final int color;
  final double units;
}

/// Groups a tube's colour list into contiguous bands (bottom -> top).
List<LiquidBand> bandsOf(List<int> colors) {
  final out = <LiquidBand>[];
  for (final c in colors) {
    if (out.isNotEmpty && out.last.color == c) {
      out[out.length - 1] = LiquidBand(c, out.last.units + 1);
    } else {
      out.add(LiquidBand(c, 1));
    }
  }
  return out;
}

/// Paints a glossy glass test tube with layered liquid.
///
/// * [tilt]    – rotation (radians) applied by the parent; liquid surface is
///               counter-slanted so it stays level with gravity.
/// * [slosh]   – 0..1 amplitude of the surface wave (after a pour).
/// * [phase]   – wave phase.
/// * [glow]    – selection glow strength 0..1.
/// * [complete]– 0..1 completion effect (cap + rim glow).
class TubePainter extends CustomPainter {
  TubePainter({
    required this.bands,
    required this.capacity,
    this.tilt = 0,
    this.slosh = 0,
    this.phase = 0,
    this.glow = 0,
    this.complete = 0,
    this.hint = 0,
    this.seed = 0,
  });

  final List<LiquidBand> bands;
  final int capacity;
  final double tilt;
  final double slosh;
  final double phase;
  final double glow;
  final double complete;
  final double hint;
  final int seed;

  static const double lip = 7;

  /// Outer tube outline in local coordinates.
  static Path bodyPath(Size s, {double inset = 0}) {
    final w = s.width - inset * 2;
    final r = w / 2;
    final top = lip + inset * 0.5;
    final bottom = s.height - inset;
    final left = inset;
    return Path()
      ..moveTo(left, top)
      ..lineTo(left, bottom - r)
      ..arcToPoint(
        Offset(left + w, bottom - r),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(left + w, top)
      ..close();
  }

  /// Height from the bottom of the inner tube that one unit of liquid fills.
  static double unitHeight(Size s, int capacity) =>
      (s.height - lip - 18) / capacity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outer = bodyPath(size);
    const inset = 4.0;
    final inner = bodyPath(size, inset: inset);

    // ---- Glow (selection / hint / completion) -----------------------------
    final glowColor = complete > 0
        ? Color.lerp(Palette.gold, Palette.indiaGreen, 0.35)!
        : hint > 0 && glow == 0
        ? Palette.cyan
        : Palette.gold;
    final glowAmt = max(glow, max(hint * 0.9, complete * 0.85));
    if (glowAmt > 0.01) {
      canvas.drawPath(
        outer,
        Paint()
          ..color = glowColor.withValues(alpha: 0.55 * glowAmt)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + 8 * glowAmt)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8,
      );
    }

    // ---- Back glass -------------------------------------------------------
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.12),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Offset.zero & size),
    );

    // ---- Liquid -----------------------------------------------------------
    canvas.save();
    canvas.clipPath(inner);
    final unitH = unitHeight(size, capacity);
    final bottom = h - inset;
    var y = bottom;
    // Surface stays level with gravity while tilted: slope = -tan(tilt)
    // across the tube width, clamped so it never looks like a diagonal streak.
    final unitH0 = unitHeight(size, capacity);
    final maxDelta = unitH0 * 0.85;
    final deltaY = (tan(tilt.clamp(-1.3, 1.3)) * w).clamp(-maxDelta, maxDelta);
    final total = bands.fold<double>(0, (a, b) => a + b.units);
    var acc = 0.0;
    for (var i = 0; i < bands.length; i++) {
      final b = bands[i];
      if (b.units <= 0.001) continue;
      final bandH = b.units * unitH;
      final top = y - bandH;
      acc += b.units;
      final isTop = (acc - total).abs() < 0.001;
      final base = Palette.liquids[b.color % Palette.liquids.length];
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.lerp(base, Colors.black, 0.18)!,
            Color.lerp(base, Colors.white, 0.18)!,
            base,
            Color.lerp(base, Colors.black, 0.28)!,
          ],
          stops: const [0, 0.28, 0.6, 1],
        ).createShader(Rect.fromLTRB(0, top, w, y));

      // Each band's top edge is slanted the same way; lower edge is the
      // previous band's top (y) -> bands overlap a little to avoid seams.
      final path = Path();
      const l = 0.0;
      final r = w;
      final topL = top + deltaY / 2;
      final topR = top - deltaY / 2;
      // Bottom edge is `y` (with a hair of overlap to hide seams).
      final bottomEdge = y + 0.8;
      path.moveTo(l, bottomEdge);
      path.lineTo(l, topL);
      if (isTop && slosh > 0.001) {
        // Wavy surface.
        const steps = 12;
        for (var s = 1; s <= steps; s++) {
          final x = l + (r - l) * s / steps;
          final base = topL + (topR - topL) * s / steps;
          final wave = sin(phase + s / steps * pi * 2) * 3.2 * slosh;
          path.lineTo(x, base + wave);
        }
      } else {
        path.lineTo(r, topR);
      }
      path.lineTo(r, bottomEdge);
      path.close();
      canvas.drawPath(path, paint);

      if (isTop) {
        // Glossy meniscus line.
        canvas.drawLine(
          Offset(l + 3, topL + 1.5),
          Offset(r - 3, topR + 1.5),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }

      // Subtle bubbles inside the band.
      final rnd = Random(seed * 31 + i * 7 + b.color);
      final bubble = Paint()..color = Colors.white.withValues(alpha: 0.22);
      final count = (b.units * 1.5).round();
      for (var k = 0; k < count; k++) {
        final bx = 6 + rnd.nextDouble() * (w - 12);
        final by = y - 4 - rnd.nextDouble() * max(0.0, bandH - 8);
        canvas.drawCircle(Offset(bx, by), 1 + rnd.nextDouble() * 1.8, bubble);
      }
      y = top;
    }
    canvas.restore();

    // ---- Front glass highlights -------------------------------------------
    // Left vertical shine.
    canvas.save();
    canvas.clipPath(outer);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, lip + 8, w * 0.13, h - lip - w * 0.55),
        Radius.circular(w * 0.1),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.08),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    // Right soft edge shine.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.78, lip + 14, w * 0.06, h * 0.5),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.restore();

    // Outline.
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.7),
          ],
        ).createShader(Offset.zero & size),
    );

    // Rim (lip).
    final rim = RRect.fromRectAndRadius(
      Rect.fromLTWH(-3, 0, w + 6, lip + 3),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      rim,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.75),
            Colors.white.withValues(alpha: 0.35),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rim.outerRect),
    );

    // ---- Completion cap ---------------------------------------------------
    if (complete > 0.01) {
      final c = Curves.easeOutBack.transform(complete.clamp(0, 1));
      final capH = 14.0;
      final capW = w + 4;
      final dy = -capH * (1 - c) * 2.5;
      final cap = RRect.fromRectAndCorners(
        Rect.fromLTWH(-2, -capH + 6 + dy, capW, capH),
        topLeft: const Radius.circular(7),
        topRight: const Radius.circular(7),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );
      canvas.drawRRect(
        cap,
        Paint()
          ..color = Colors.white.withValues(alpha: c.clamp(0, 1))
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE89A), Color(0xFFE59A12)],
          ).createShader(cap.outerRect),
      );
      canvas.drawLine(
        Offset(4, cap.top + 4),
        Offset(capW - 8, cap.top + 4),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TubePainter o) =>
      o.tilt != tilt ||
      o.slosh != slosh ||
      o.phase != phase ||
      o.glow != glow ||
      o.complete != complete ||
      o.hint != hint ||
      o.capacity != capacity ||
      !_sameBands(o.bands, bands);

  static bool _sameBands(List<LiquidBand> a, List<LiquidBand> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].color != b[i].color || a[i].units != b[i].units) return false;
    }
    return true;
  }
}
