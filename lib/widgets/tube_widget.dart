import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../style/palette.dart';

/// A single test tube holding stacked colour segments.
///
/// Animations (flutter_animate):
/// * selected  -> lifts up with a springy slide
/// * pourTick  -> squash & stretch bounce after liquid moves
/// * shakeTick -> horizontal shake on an illegal move
/// * complete  -> shimmer + gentle pulse when a tube is solved
class TubeWidget extends StatelessWidget {
  const TubeWidget({
    super.key,
    required this.colors,
    required this.capacity,
    required this.selected,
    required this.complete,
    required this.pourTick,
    required this.shakeTick,
    required this.onTap,
    this.width = 56,
    this.height = 200,
  });

  final List<int> colors;
  final int capacity;
  final bool selected;
  final bool complete;
  final int pourTick;
  final int shakeTick;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final segH = (height - 18) / capacity;

    Widget glass = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(5, 12, 5, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        border: Border.all(
          color: complete ? Palette.accentGreen : Palette.ink,
          width: complete ? 4 : 3,
        ),
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(8),
          bottom: Radius.circular(width / 2),
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: Palette.accentYellow.withValues(alpha: 0.9),
              blurRadius: 18,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(3),
          bottom: Radius.circular(width / 2 - 5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (var i = colors.length - 1; i >= 0; i--)
              _Segment(
                // Key by position+colour so new liquid fades/slides in.
                key: ValueKey('seg-$i-${colors[i]}-$pourTick'),
                color: Palette.liquids[colors[i] % Palette.liquids.length],
                height: segH,
                isTop: i == colors.length - 1,
                animateIn: pourTick > 0 && i == colors.length - 1,
              ),
          ],
        ),
      ),
    );

    if (complete) {
      glass = glass
          .animate(key: ValueKey('complete-$pourTick'))
          .scaleXY(end: 1.06, duration: 180.ms, curve: Curves.easeOut)
          .then()
          .scaleXY(end: 1 / 1.06, duration: 260.ms, curve: Curves.elasticOut)
          .shimmer(
            duration: 900.ms,
            color: Colors.white.withValues(alpha: 0.8),
          );
    }

    // Pour bounce: squash & stretch (only after a real pour).
    if (pourTick > 0) {
      glass = glass
          .animate(key: ValueKey('pour-$pourTick'))
          .scaleY(
            begin: 0.9,
            end: 1,
            alignment: Alignment.bottomCenter,
            duration: 480.ms,
            curve: Curves.elasticOut,
          );
    }
    // Illegal move shake.
    if (shakeTick > 0) {
      glass = glass
          .animate(key: ValueKey('shake-$shakeTick'))
          .shakeX(hz: 6, amount: 5, duration: 380.ms);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 28),
        child: AnimatedSlide(
          offset: Offset(0, selected ? -0.14 : 0),
          duration: const Duration(milliseconds: 260),
          curve: selected ? Curves.easeOutBack : Curves.bounceOut,
          child: glass,
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.color,
    required this.height,
    required this.isTop,
    required this.animateIn,
  });

  final Color color;
  final double height;
  final bool isTop;
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    final seg = Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(color, Colors.white, 0.25)!,
            color,
            Color.lerp(color, Colors.black, 0.15)!,
          ],
          stops: const [0, 0.45, 1],
        ),
        border: isTop
            ? Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 2,
                ),
              )
            : null,
      ),
    );
    if (!animateIn) return seg;
    return seg
        .animate()
        .slideY(begin: -0.8, duration: 260.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 180.ms);
  }
}
