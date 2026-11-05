import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/level_state.dart';
import '../style/palette.dart';
import 'tube_painter.dart';
import 'tube_view.dart';

/// Callback for tap outcomes (fires immediately after a tap).
typedef OutcomeCallback = void Function(TapOutcome outcome);

/// The playing field. Lays the tubes out in rows and choreographs the pour:
///
///   1. lift + fly the source tube next to the target
///   2. tilt and pour a liquid stream (bands transfer smoothly)
///   3. splash droplets, slosh the target, fly back home
///
/// One [Ticker] drives the pour and the particle system, and it only runs
/// while something is actually animating.
class GameBoard extends StatefulWidget {
  const GameBoard({
    super.key,
    required this.state,
    required this.onOutcome,
    required this.onPourLanded,
  });

  final LevelState state;
  final OutcomeCallback onOutcome;
  final OutcomeCallback onPourLanded;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _PourAnim {
  _PourAnim({
    required this.outcome,
    required this.fromBefore,
    required this.toBefore,
  }) : pourMs = 240.0 + outcome.amount * 130.0;

  final TapOutcome outcome;
  final List<int> fromBefore;
  final List<int> toBefore;
  final double pourMs;
  static const double flyMs = 280;
  static const double backMs = 300;
  double elapsed = 0;
  bool landed = false;

  int get from => outcome.from!;
  int get to => outcome.to!;
  int get color => outcome.color!;
  double get total => flyMs + pourMs + backMs;
  bool get done => elapsed >= total;

  double get fly => (elapsed / flyMs).clamp(0, 1);
  double get pour => ((elapsed - flyMs) / pourMs).clamp(0, 1);
  double get back => ((elapsed - flyMs - pourMs) / backMs).clamp(0, 1);

  /// Fraction of the liquid that has arrived (lags the stream slightly).
  double get transfer =>
      Curves.easeInOut.transform(((pour - 0.12) / 0.8).clamp(0.0, 1.0));
}

class _Particle {
  _Particle(this.pos, this.vel, this.color, this.size, this.life, this.star);
  Offset pos;
  Offset vel;
  final Color color;
  final double size;
  final double life;
  final bool star;
  double age = 0;
}

class _Stream {
  const _Stream({
    required this.from,
    required this.to,
    required this.color,
    required this.width,
    required this.bend,
  });
  final Offset from;
  final Offset to;
  final Color color;
  final double width;
  final double bend;
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;
  _PourAnim? _pour;
  final List<_Particle> _particles = [];
  final Map<int, int> _sloshTicks = {};
  final _rng = Random();
  int _lastResetTick = 0;
  List<Rect> _slots = const [];
  double _tubeW = 50;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  LevelState get s => widget.state;

  @override
  void initState() {
    super.initState();
    _lastResetTick = s.resetTick;
    s.addListener(_onState);
  }

  @override
  void didUpdateWidget(GameBoard old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      old.state.removeListener(_onState);
      widget.state.addListener(_onState);
      _cancelPour();
      _particles.clear();
      _sloshTicks.clear();
      _lastResetTick = widget.state.resetTick;
      _enter.forward(from: 0);
    }
  }

  void _onState() {
    if (s.resetTick != _lastResetTick) {
      _lastResetTick = s.resetTick;
      _cancelPour();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    s.removeListener(_onState);
    _ticker.dispose();
    _enter.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- ticking
  void _ensureTicking() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration now) {
    final dt = _last == Duration.zero
        ? 16.0
        : (now - _last).inMicroseconds / 1000.0;
    _last = now;
    final step = dt.clamp(0, 40).toDouble();

    final p = _pour;
    if (p != null) {
      p.elapsed += step;
      if (p.pour > 0.1 && p.pour < 0.95) _spawnSplash(p);
      if (!p.landed && p.pour >= 1) _land(p);
      if (p.done) _pour = null;
    }
    _stepParticles(step / 1000);

    if (_pour == null && _particles.isEmpty) _ticker.stop();
    if (mounted) setState(() {});
  }

  void _land(_PourAnim p) {
    p.landed = true;
    _sloshTicks[p.to] = (_sloshTicks[p.to] ?? 0) + 1;
    _sloshTicks[p.from] = (_sloshTicks[p.from] ?? 0) + 1;
    if (p.outcome.completedTube) _burst(p.to, p.color);
    widget.onPourLanded(p.outcome);
  }

  void _cancelPour() {
    final p = _pour;
    if (p != null && !p.landed) {
      p.landed = true;
      widget.onPourLanded(p.outcome);
    }
    _pour = null;
  }

  /// Instantly finish a running pour (used when the player taps quickly).
  void _fastForward() {
    final p = _pour;
    if (p == null) return;
    if (!p.landed) _land(p);
    _pour = null;
  }

  // ------------------------------------------------------------- particles
  Offset _surfacePoint(int tube, double units) {
    final r = _slots[tube];
    final unitH = TubePainter.unitHeight(r.size, s.capacity);
    return Offset(r.center.dx, r.bottom - 4 - units * unitH);
  }

  void _spawnSplash(_PourAnim p) {
    if (_rng.nextDouble() > 0.55) return;
    final units = p.toBefore.length + p.outcome.amount * p.transfer;
    final at = _surfacePoint(p.to, units);
    final c = Palette.liquids[p.color % Palette.liquids.length];
    _particles.add(
      _Particle(
        at + Offset((_rng.nextDouble() - 0.5) * _tubeW * 0.4, 0),
        Offset((_rng.nextDouble() - 0.5) * 120, -60 - _rng.nextDouble() * 110),
        Color.lerp(c, Colors.white, _rng.nextDouble() * 0.3)!,
        1.4 + _rng.nextDouble() * 2.2,
        0.35 + _rng.nextDouble() * 0.25,
        false,
      ),
    );
  }

  void _burst(int tube, int color) {
    final r = _slots[tube];
    final origin = Offset(r.center.dx, r.top + 4);
    final c = Palette.liquids[color % Palette.liquids.length];
    for (var i = 0; i < 34; i++) {
      final a = -pi / 2 + (_rng.nextDouble() - 0.5) * pi * 1.3;
      final speed = 140 + _rng.nextDouble() * 260;
      final star = i % 3 == 0;
      _particles.add(
        _Particle(
          origin,
          Offset(cos(a) * speed, sin(a) * speed),
          star ? Palette.gold : Color.lerp(c, Colors.white, 0.2)!,
          star ? 4 + _rng.nextDouble() * 3 : 2 + _rng.nextDouble() * 3,
          0.7 + _rng.nextDouble() * 0.6,
          star,
        ),
      );
    }
    _ensureTicking();
  }

  void _stepParticles(double dt) {
    for (final pt in _particles) {
      pt.age += dt;
      pt.vel = Offset(pt.vel.dx * (1 - dt * 1.2), pt.vel.dy + 520 * dt);
      pt.pos += pt.vel * dt;
    }
    _particles.removeWhere((pt) => pt.age >= pt.life);
  }

  // ------------------------------------------------------------------ input
  void _tap(int index) {
    if (_pour != null) _fastForward();
    final sel = s.selected;
    final fromBefore = sel != null ? List<int>.of(s.tubes[sel]) : null;
    final toBefore = List<int>.of(s.tubes[index]);
    final outcome = s.tapTube(index);
    if (outcome.result == TapResult.poured && fromBefore != null) {
      _pour = _PourAnim(
        outcome: outcome,
        fromBefore: fromBefore,
        toBefore: toBefore,
      );
      _ensureTicking();
    }
    widget.onOutcome(outcome);
  }

  // ----------------------------------------------------------------- layout
  void _layout(Size size) {
    final n = s.tubes.length;
    final perRow = n <= 5 ? n : (n / 2).ceil();
    final rows = (n / perRow).ceil();
    const gap = 14.0;
    final w = min(68.0, (size.width - 16) / perRow - gap + 4);
    final rowSpace = size.height / rows;
    final h = (min(w * 3.45, rowSpace - 62)).clamp(120.0, 300.0).toDouble();
    _tubeW = w;
    final slots = <Rect>[];
    final contentH = rows * (h + 52) - 52;
    final top0 = max(34.0, (size.height - contentH) / 2 + 8);
    for (var r = 0; r < rows; r++) {
      final start = r * perRow;
      final count = min(perRow, n - start);
      final rowW = count * w + (count - 1) * gap;
      final left0 = (size.width - rowW) / 2;
      for (var k = 0; k < count; k++) {
        slots.add(
          Rect.fromLTWH(left0 + k * (w + gap), top0 + r * (h + 52), w, h),
        );
      }
    }
    _slots = slots;
  }

  List<LiquidBand> _displayBands(int i) {
    final p = _pour;
    if (p != null) {
      final moved = p.outcome.amount * p.transfer;
      if (i == p.from) {
        final b = bandsOf(p.fromBefore);
        if (b.isEmpty) return b;
        final last = b.removeLast();
        return [...b, LiquidBand(last.color, last.units - moved)];
      }
      if (i == p.to) {
        final b = bandsOf(p.toBefore);
        if (b.isNotEmpty && b.last.color == p.color) {
          final last = b.removeLast();
          return [...b, LiquidBand(last.color, last.units + moved)];
        }
        return [...b, LiquidBand(p.color, moved)];
      }
    }
    return bandsOf(s.tubes[i]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        _layout(Size(c.maxWidth, c.maxHeight));
        final p = _pour;
        final hint = s.activeHint;
        final children = <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: s.clearSelection,
            ),
          ),
        ];

        for (var i = 0; i < _slots.length && i < s.tubes.length; i++) {
          final r = _slots[i];
          final enterT = ((_enter.value * 1.7 - i * 0.055) / 0.7).clamp(
            0.0,
            1.0,
          );
          final enterCurve = Curves.easeOutBack.transform(enterT);
          final hiddenForPour = p != null && i == p.from;
          final completeShown =
              s.isTubeComplete(i) && !(p != null && i == p.to && !p.landed);
          children.add(
            Positioned(
              left: r.left - 15,
              top: r.top - 40,
              width: r.width + 30,
              height: r.height + 48,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _tap(i),
                child: Opacity(
                  opacity: hiddenForPour ? 0 : enterT,
                  child: Transform.translate(
                    offset: Offset(0, (1 - enterCurve) * -90),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 40, 15, 8),
                      child: TubeView(
                        key: ValueKey('tube-${s.level.number}-$i'),
                        bands: _displayBands(i),
                        capacity: s.capacity,
                        width: r.width,
                        height: r.height,
                        selected: s.selected == i,
                        complete: completeShown,
                        hinted:
                            hint != null && (hint.from == i || hint.to == i),
                        shakeTick: s.lastIllegalTube == i ? s.illegalTick : 0,
                        sloshTick: _sloshTicks[i] ?? 0,
                        seed: i,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (p != null) children.add(_buildPouringTube(p));

        children.add(
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FxPainter(
                  particles: _particles,
                  stream: p == null ? null : _streamGeometry(p),
                ),
              ),
            ),
          ),
        );

        return Stack(clipBehavior: Clip.none, children: children);
      },
    );
  }

  // --------------------------------------------------- pouring choreography
  bool _pourRight(_PourAnim p) =>
      _slots[p.to].center.dx >= _slots[p.from].center.dx;

  double _tiltAt(_PourAnim p) {
    final dir = _pourRight(p) ? 1.0 : -1.0;
    final fullness = p.fromBefore.length / s.capacity;
    final start = 0.85 + (1 - fullness) * 0.30;
    const end = 1.30;
    double t;
    if (p.pour <= 0) {
      t = Curves.easeInOutCubic.transform(p.fly) * start;
    } else if (p.back <= 0) {
      t = start + (end - start) * Curves.easeOut.transform(p.pour);
    } else {
      t = end * (1 - Curves.easeInOutCubic.transform(p.back));
    }
    return t * dir;
  }

  /// Pivot (mouth) position of the pouring tube, in board coordinates.
  Offset _pivotAt(_PourAnim p) {
    final from = _slots[p.from];
    final to = _slots[p.to];
    final right = _pourRight(p);
    final home = Offset(
      right ? from.right : from.left,
      from.top - from.height * 0.11,
    );
    final target = Offset(
      to.center.dx + (right ? 2 : -2),
      to.top - to.height * 0.24,
    );
    if (p.pour <= 0) {
      return Offset.lerp(home, target, Curves.easeInOutCubic.transform(p.fly))!;
    }
    if (p.back <= 0) return target;
    return Offset.lerp(
      target,
      home,
      Curves.easeInOutCubic.transform(p.back),
    )!;
  }

  Widget _buildPouringTube(_PourAnim p) {
    final pivot = _pivotAt(p);
    final right = _pourRight(p);
    final r = _slots[p.from];
    return Positioned(
      left: right ? pivot.dx - r.width : pivot.dx,
      top: pivot.dy,
      width: r.width,
      height: r.height,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: _tiltAt(p),
          alignment: right ? Alignment.topRight : Alignment.topLeft,
          child: TubeView(
            key: const ValueKey('pouring-tube'),
            bands: _displayBands(p.from),
            capacity: s.capacity,
            width: r.width,
            height: r.height,
            tilt: _tiltAt(p),
            seed: p.from,
          ),
        ),
      ),
    );
  }

  _Stream? _streamGeometry(_PourAnim p) {
    if (p.pour <= 0 || p.pour >= 1) return null;
    final start = _pivotAt(p);
    final units = p.toBefore.length + p.outcome.amount * p.transfer;
    final end = _surfacePoint(p.to, units);
    // Head grows down at the start, tail falls away at the end.
    final head = (p.pour / 0.18).clamp(0.0, 1.0);
    final tail = ((p.pour - 0.8) / 0.2).clamp(0.0, 1.0);
    final env = sin(pi * p.pour).clamp(0.4, 1.0);
    return _Stream(
      from: Offset.lerp(start, end, tail)!,
      to: Offset.lerp(start, end, head)!,
      color: Palette.liquids[p.color % Palette.liquids.length],
      width: _tubeW * 0.18 * env,
      bend: _pourRight(p) ? 1 : -1,
    );
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter({required this.particles, required this.stream});
  final List<_Particle> particles;
  final _Stream? stream;

  @override
  void paint(Canvas canvas, Size size) {
    final st = stream;
    if (st != null && (st.to - st.from).distance > 1) {
      final ctrl = Offset(st.from.dx + st.bend * 6, st.from.dy + 8);
      final path = Path()
        ..moveTo(st.from.dx, st.from.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, st.to.dx, st.to.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = st.color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = st.width + 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = st.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = st.width,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = max(1, st.width * 0.25),
      );
    }

    final paint = Paint();
    for (final p in particles) {
      final a = (1 - p.age / p.life).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: a);
      if (p.star) {
        _drawSparkle(canvas, p.pos, p.size * (0.6 + 0.4 * a), paint);
      } else {
        canvas.drawCircle(p.pos, p.size, paint);
      }
    }
  }

  void _drawSparkle(Canvas c, Offset o, double r, Paint paint) {
    final path = Path()
      ..moveTo(o.dx, o.dy - r * 1.6)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r * 1.6, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r * 1.6)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r * 1.6, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r * 1.6)
      ..close();
    c.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FxPainter oldDelegate) => true;
}
