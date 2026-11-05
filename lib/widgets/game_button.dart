import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/audio_controller.dart';
import '../style/palette.dart';

/// Large gradient button with press physics, shine sweep and haptics.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = Palette.primaryButton,
    this.width = 260,
    this.height = 62,
    this.compact = false,
    this.subtitle,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final double width;
  final double height;
  final bool compact;
  final String? subtitle;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  void _handleTap() {
    HapticFeedback.lightImpact();
    final audio = context.read<AudioController>();
    audio.ensureMusicStarted();
    audio.playSfx(Sfx.button);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final h = widget.compact ? 46.0 : widget.height;
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
        scale: _down ? 0.955 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: widget.width,
          height: h,
          decoration: BoxDecoration(
            gradient: enabled
                ? widget.gradient
                : const LinearGradient(
                    colors: [Color(0xFF4A4460), Color(0xFF3A3550)],
                  ),
            borderRadius: BorderRadius.circular(h / 2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: (enabled ? widget.gradient.colors.first : Colors.black)
                    .withValues(alpha: enabled ? 0.42 : 0.2),
                blurRadius: _down ? 8 : 18,
                offset: Offset(0, _down ? 3 : 9),
                spreadRadius: _down ? 0 : 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Top gloss.
              Positioned(
                left: 14,
                right: 14,
                top: 4,
                height: h * 0.34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(h),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: Colors.white,
                        size: widget.compact ? 20 : 26,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontFamily: Palette.displayFont,
                            fontWeight: FontWeight.w800,
                            fontSize: widget.compact ? 18 : 24,
                            color: Colors.white,
                            letterSpacing: 0.2,
                            shadows: const [
                              Shadow(
                                color: Color(0x66000000),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontFamily: Palette.bodyFont,
                              fontSize: widget.compact ? 10 : 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
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

/// Round glass icon button used in top bars.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badge,
    this.size = 46,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final btn = GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              final audio = context.read<AudioController>();
              audio.ensureMusicStarted();
              audio.playSfx(Sfx.button);
              onPressed!();
            }
          : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.13 : 0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: enabled ? 0.28 : 0.12),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: size * 0.5,
              color: enabled ? Colors.white : Colors.white24,
            ),
            if (badge != null)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: const BoxDecoration(
                    color: Palette.gold,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Palette.bgTop,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return Tooltip(
      message: tooltip ?? '',
      child: btn,
    );
  }
}

/// Frosted glass card container.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.margin,
    this.tint,
    this.glow,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final EdgeInsets? margin;
  final Color? tint;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          if (glow != null)
            BoxShadow(
              color: glow!.withValues(alpha: 0.35),
              blurRadius: 26,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: tint == null
          ? child
          : DecoratedBox(
              decoration: BoxDecoration(
                color: tint!.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: child,
            ),
    );
  }
}
