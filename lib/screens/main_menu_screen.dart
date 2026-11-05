import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../game/game_logic.dart';
import '../services/audio_controller.dart';
import '../services/neta_voices.dart';
import '../services/progress_controller.dart';
import '../services/settings_controller.dart';
import '../style/palette.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_button.dart';
import '../widgets/neta_speech_bubble.dart';
import '../widgets/tube_painter.dart';
import 'level_selection_screen.dart';
import 'play_session_screen.dart';
import 'settings_screen.dart';
import 'soundboard_screen.dart';
import 'tutorial_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final settings = context.watch<SettingsController>();
    final audio = context.read<AudioController>();
    final saved = progress.storage.savedBoard;
    final resumeLevel = saved?.level ?? progress.nextLevelToPlay;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 6,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    RoundIconButton(
                      icon: settings.muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      tooltip: settings.muted ? 'Unmute' : 'Mute',
                      onPressed: settings.toggleMuted,
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: Icons.settings_rounded,
                      tooltip: 'Settings',
                      onPressed: () => Navigator.of(
                        context,
                      ).push(fadeRoute(const SettingsScreen())),
                    ),
                  ],
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 64, 22, 26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Logo(),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: Palette.tricolor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NETA EDITION',
                          style: TextStyle(
                            fontFamily: Palette.bodyFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 3,
                            color: Palette.bgTop,
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                      const SizedBox(height: 18),
                      _StatsBar(progress: progress),
                      const SizedBox(height: 22),
                      _VoiceTeaser(
                        onTap: () => Navigator.of(
                          context,
                        ).push(fadeRoute(const SoundboardScreen())),
                      ),
                      const SizedBox(height: 20),
                      GameButton(
                            label: saved != null
                                ? 'Continue · Level $resumeLevel'
                                : 'Play',
                            icon: Icons.play_arrow_rounded,
                            onPressed: () {
                              audio.react(VoiceEvent.levelStart);
                              Navigator.of(context).push(
                                fadeRoute(
                                  PlaySessionScreen(
                                    levelNumber: resumeLevel,
                                    resume: saved != null,
                                  ),
                                ),
                              );
                            },
                          )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .slideY(begin: 0.5, curve: Curves.easeOutBack),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MiniAction(
                            icon: Icons.grid_view_rounded,
                            label: 'Levels',
                            onTap: () => Navigator.of(
                              context,
                            ).push(fadeRoute(const LevelSelectionScreen())),
                          ),
                          const SizedBox(width: 10),
                          _MiniAction(
                            icon: Icons.mic_rounded,
                            label: 'Soundboard',
                            onTap: () => Navigator.of(
                              context,
                            ).push(fadeRoute(const SoundboardScreen())),
                          ),
                          const SizedBox(width: 10),
                          _MiniAction(
                            icon: Icons.help_outline_rounded,
                            label: 'How to play',
                            onTap: () => Navigator.of(
                              context,
                            ).push(fadeRoute(const TutorialScreen())),
                          ),
                        ],
                      ).animate().fadeIn(delay: 520.ms, duration: 400.ms),
                      const SizedBox(height: 26),
                      Text(
                        '🎵 ${audio.currentTrackTitle} · Kevin MacLeod (CC BY)',
                        style: const TextStyle(
                          fontFamily: Palette.bodyFont,
                          color: Palette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Meme voices belong to their original creators · fan parody',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: Palette.bodyFont,
                          color: Palette.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFE9A8), Color(0xFFFFB347), Color(0xFFFF7043)],
              ).createShader(r),
              child: const Text(
                'Color Pour',
                style: TextStyle(
                  fontFamily: Palette.displayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 54,
                  height: 1.0,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Color(0x88000000),
                      offset: Offset(0, 5),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: -0.5, curve: Curves.easeOutBack)
            .scaleXY(begin: 0.85, curve: Curves.easeOutBack),
        const SizedBox(height: 2),
        const Text(
          'sort the colours · neta style',
          style: TextStyle(
            fontFamily: Palette.bodyFont,
            fontSize: 12.5,
            letterSpacing: 1.4,
            color: Palette.textSecondary,
          ),
        ).animate().fadeIn(delay: 250.ms),
      ],
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.progress});
  final ProgressController progress;

  @override
  Widget build(BuildContext context) {
    Widget cell(IconData icon, String value, String label, Color c) => Expanded(
      child: Column(
        children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: Palette.displayFont,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: Palette.bodyFont,
              fontSize: 9.5,
              color: Palette.textMuted,
            ),
          ),
        ],
      ),
    );
    return GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          radius: 20,
          child: Row(
            children: [
              cell(
                Icons.emoji_events_rounded,
                '${progress.highScore}',
                'Best score',
                Palette.gold,
              ),
              cell(
                Icons.flag_rounded,
                '${progress.highestLevelReached}/$kLevelCount',
                'Levels',
                Palette.cyan,
              ),
              cell(
                Icons.star_rounded,
                '${progress.totalStars}',
                'Stars',
                Palette.pink,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 180.ms)
        .scaleXY(begin: 0.92, curve: Curves.easeOutBack);
  }
}

/// Rotating famous-line teaser, tapping opens the soundboard.
class _VoiceTeaser extends StatefulWidget {
  const _VoiceTeaser({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_VoiceTeaser> createState() => _VoiceTeaserState();
}

class _VoiceTeaserState extends State<_VoiceTeaser> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final line = NetaVoices.all[_i % NetaVoices.all.length];
    return GestureDetector(
      onTap: () {
        context.read<AudioController>().speakLine(line);
        widget.onTap();
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mic_rounded,
                size: 13,
                color: Palette.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                'NETA SOUNDBOARD · TAP TO OPEN',
                style: TextStyle(
                  fontFamily: Palette.bodyFont,
                  fontSize: 9,
                  letterSpacing: 1.6,
                  color: Palette.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Force a fresh bubble per line so the pop animation replays.
          NetaSpeechBubble(key: ValueKey(line.id), line: line, compact: true),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .then(delay: 4.seconds)
        .callback(
          callback: (_) {
            if (mounted) setState(() => _i++);
          },
        );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final audio = context.read<AudioController>();
        audio.ensureMusicStarted();
        audio.playSfx(Sfx.button);
        onTap();
      },
      child: Container(
        width: 94,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: Palette.bodyFont,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared fade+slide page transition.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 380),
  reverseTransitionDuration: const Duration(milliseconds: 260),
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) {
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
);

/// Small tube preview used in a few places (kept here to avoid cycles).
class MiniTubePreview extends StatelessWidget {
  const MiniTubePreview({
    super.key,
    required this.colors,
    this.width = 26,
    this.height = 74,
    this.capacity = 4,
  });
  final List<int> colors;
  final double width;
  final double height;
  final int capacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: TubePainter(
        bands: bandsOf(colors),
        capacity: capacity,
        seed: colors.length,
      ),
    );
  }
}
