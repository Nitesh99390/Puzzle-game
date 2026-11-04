import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/audio_controller.dart';
import '../style/palette.dart';

/// Chunky game-style button with a press "squash" and click sound.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = Palette.accentPink,
    this.width = 240,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final double width;
  final bool compact;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  void _handleTap() {
    final audio = context.read<AudioController>();
    audio.ensureMusicStarted();
    audio.playSfx(Sfx.button);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final base = enabled ? widget.color : Colors.grey.shade400;
    final h = widget.compact ? 48.0 : 60.0;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              _handleTap();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Container(
          width: widget.width,
          height: h,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Palette.ink, width: 3),
            boxShadow: [
              BoxShadow(color: Palette.ink, offset: Offset(0, _down ? 1 : 5)),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: Palette.trueWhite,
                  size: widget.compact ? 22 : 26,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: Palette.displayFont,
                  fontSize: widget.compact ? 20 : 26,
                  color: Palette.trueWhite,
                  shadows: const [
                    Shadow(color: Palette.ink, offset: Offset(1.5, 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round icon button used in top bars, with a bounce-in entrance.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = Palette.trueWhite,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final btn = Material(
      color: enabled ? color : Colors.grey.shade300,
      shape: const CircleBorder(
        side: BorderSide(color: Palette.ink, width: 2.5),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled
            ? () {
                final audio = context.read<AudioController>();
                audio.ensureMusicStarted();
                audio.playSfx(Sfx.button);
                onPressed!();
              }
            : null,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: enabled ? Palette.ink : Colors.grey,
            size: 26,
          ),
        ),
      ),
    );
    return (tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn)
        .animate()
        .scale(
          begin: const Offset(0.4, 0.4),
          duration: 450.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 200.ms);
  }
}
