import 'package:flutter/material.dart';

import '../services/neta_voices.dart';
import '../style/palette.dart';

/// Floating speech bubble that shows which neta is "speaking" a meme line.
/// Appears above the board, animated in/out, and auto-hides.
class NetaSpeechBubble extends StatelessWidget {
  const NetaSpeechBubble({super.key, required this.line, this.compact = false});

  final VoiceLine? line;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = line;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(anim),
          alignment: Alignment.center,
          child: child,
        ),
      ),
      child: l == null
          ? const SizedBox(height: 0, width: double.infinity)
          : Container(
              key: ValueKey(l.id),
              constraints: BoxConstraints(maxWidth: compact ? 340 : 380),
              margin: EdgeInsets.symmetric(horizontal: compact ? 8 : 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: l.neta.gradient),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: l.neta.gradient.last.withValues(alpha: 0.5),
                    blurRadius: 22,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      l.neta.short,
                      style: const TextStyle(
                        fontFamily: Palette.bodyFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.neta.fullName.toUpperCase(),
                          style: TextStyle(
                            fontFamily: Palette.bodyFont,
                            fontSize: 9.5,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        Text(
                          '“${l.caption}”',
                          style: const TextStyle(
                            fontFamily: Palette.bodyFont,
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _SpeakerIcon(),
                ],
              ),
            ),
    );
  }
}

class _SpeakerIcon extends StatefulWidget {
  const _SpeakerIcon();

  @override
  State<_SpeakerIcon> createState() => _SpeakerIconState();
}

class _SpeakerIconState extends State<_SpeakerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Icon(
          Icons.graphic_eq_rounded,
          size: 16 + 4 * _c.value,
          color: Colors.white.withValues(alpha: 0.6 + 0.4 * _c.value),
        ),
      ),
    );
  }
}
