import 'dart:math';

import 'package:flutter/material.dart';

import 'tube_painter.dart';

/// A single animated tube. Owns its micro-animations:
/// selection lift, slosh wave, completion cap, illegal shake and hint pulse.
class TubeView extends StatefulWidget {
  const TubeView({
    super.key,
    required this.bands,
    required this.capacity,
    required this.width,
    required this.height,
    this.selected = false,
    this.complete = false,
    this.hinted = false,
    this.shakeTick = 0,
    this.sloshTick = 0,
    this.tilt = 0,
    this.seed = 0,
  });

  final List<LiquidBand> bands;
  final int capacity;
  final double width;
  final double height;
  final bool selected;
  final bool complete;
  final bool hinted;
  final int shakeTick;
  final int sloshTick;
  final double tilt;
  final int seed;

  @override
  State<TubeView> createState() => _TubeViewState();
}

class _TubeViewState extends State<TubeView> with TickerProviderStateMixin {
  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 220),
    value: widget.selected ? 1 : 0,
  );
  late final AnimationController _slosh = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
    value: 1,
  );
  late final AnimationController _complete = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
    value: widget.complete ? 1 : 0,
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  late final AnimationController _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final Animation<double> _liftCurve = CurvedAnimation(
    parent: _lift,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.hinted) _hint.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(TubeView old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      widget.selected ? _lift.forward() : _lift.reverse();
    }
    if (widget.sloshTick != old.sloshTick) _slosh.forward(from: 0);
    if (widget.shakeTick != old.shakeTick && widget.shakeTick > 0) {
      _shake.forward(from: 0);
    }
    if (widget.complete != old.complete) {
      widget.complete ? _complete.forward(from: 0) : _complete.value = 0;
    }
    if (widget.hinted != old.hinted) {
      if (widget.hinted) {
        _hint.repeat(reverse: true);
      } else {
        _hint
          ..stop()
          ..value = 0;
      }
    }
  }

  @override
  void dispose() {
    _lift.dispose();
    _slosh.dispose();
    _complete.dispose();
    _shake.dispose();
    _hint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_lift, _slosh, _complete, _shake, _hint]),
      builder: (context, _) {
        final lift = _liftCurve.value;
        final s = _shake.value;
        final shakeX = s >= 1 ? 0.0 : sin(s * pi * 6) * 7 * (1 - s);
        final c = _complete.value;
        final bounce = c >= 1 ? 0.0 : sin(c * pi) * 10;
        final sl = _slosh.value;
        final sloshAmp = sl >= 1 ? 0.0 : pow(1 - sl, 1.6).toDouble();
        return Transform.translate(
          offset: Offset(shakeX, -lift * widget.height * 0.11 - bounce),
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            painter: TubePainter(
              bands: widget.bands,
              capacity: widget.capacity,
              tilt: widget.tilt,
              slosh: sloshAmp,
              phase: sl * pi * 7,
              glow: lift.clamp(0, 1),
              complete: c,
              hint: widget.hinted ? 0.4 + 0.6 * _hint.value : 0,
              seed: widget.seed,
            ),
          ),
        );
      },
    );
  }
}
