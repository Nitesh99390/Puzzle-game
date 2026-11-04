import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/progress_controller.dart';
import '../services/settings_controller.dart';
import '../style/palette.dart';
import '../widgets/game_button.dart';
import 'level_selection_screen.dart';
import 'play_session_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final settings = context.watch<SettingsController>();
    final saved = progress.storage.savedBoard;

    return Scaffold(
      backgroundColor: Palette.backgroundMain,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: RoundIconButton(
                icon: settings.muted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                tooltip: settings.muted ? 'Unmute' : 'Mute',
                onPressed: settings.toggleMuted,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Logo(),
                    const SizedBox(height: 12),
                    Text(
                      'Sort the colours!',
                      style: TextStyle(
                        fontFamily: Palette.displayFont,
                        fontSize: 22,
                        color: Palette.inkLight,
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                    const SizedBox(height: 28),
                    _StatsCard(
                      highScore: progress.highScore,
                      levels: progress.highestLevelReached,
                      stars: progress.totalStars,
                    ),
                    const SizedBox(height: 36),
                    ..._buttons(context, progress, saved?.level)
                        .animate(interval: 90.ms, delay: 350.ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(
                          begin: 0.6,
                          curve: Curves.easeOutBack,
                          duration: 450.ms,
                        ),
                    const SizedBox(height: 28),
                    const Text(
                      'Music by Mr Smith',
                      style: TextStyle(color: Palette.inkLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buttons(
    BuildContext context,
    ProgressController p,
    int? savedLevel,
  ) {
    final resumeLevel = savedLevel ?? p.nextLevelToPlay;
    return [
      GameButton(
        label: savedLevel != null ? 'Continue  $resumeLevel' : 'Play',
        icon: Icons.play_arrow_rounded,
        onPressed: () => Navigator.of(context).push(
          fadeRoute(
            PlaySessionScreen(
              levelNumber: resumeLevel,
              resume: savedLevel != null,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      GameButton(
        label: 'Levels',
        icon: Icons.grid_view_rounded,
        color: Palette.accentBlue,
        onPressed: () =>
            Navigator.of(context).push(fadeRoute(const LevelSelectionScreen())),
      ),
      const SizedBox(height: 16),
      GameButton(
        label: 'Settings',
        icon: Icons.settings_rounded,
        color: Palette.accentGreen,
        onPressed: () =>
            Navigator.of(context).push(fadeRoute(const SettingsScreen())),
      ),
    ];
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    const letters = 'Color Pour';
    final colors = Palette.liquids;
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < letters.length; i++)
          Text(
                letters[i],
                style: TextStyle(
                  fontFamily: Palette.displayFont,
                  fontSize: 60,
                  height: 1.1,
                  color: letters[i] == ' '
                      ? Colors.transparent
                      : colors[i % colors.length],
                  shadows: const [
                    Shadow(color: Palette.ink, offset: Offset(3, 3)),
                  ],
                ),
              )
              .animate(delay: (60 * i).ms)
              .slideY(begin: -1.5, duration: 700.ms, curve: Curves.bounceOut)
              .fadeIn(duration: 200.ms)
              .then(delay: 1.5.seconds)
              .animate(
                onPlay: (c) => c.repeat(reverse: true),
                delay: (120 * i).ms,
              )
              .moveY(
                begin: 0,
                end: -6,
                duration: 1200.ms,
                curve: Curves.easeInOut,
              ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.highScore,
    required this.levels,
    required this.stars,
  });
  final int highScore;
  final int levels;
  final int stars;

  @override
  Widget build(BuildContext context) {
    Widget stat(IconData icon, String label, String value, Color c) => Expanded(
      child: Column(
        children: [
          Icon(icon, color: c, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: Palette.displayFont,
              fontSize: 22,
              color: Palette.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Palette.inkLight),
          ),
        ],
      ),
    );
    return Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Palette.trueWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.ink, width: 3),
            boxShadow: const [
              BoxShadow(color: Palette.ink, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              stat(
                Icons.emoji_events_rounded,
                'High score',
                '$highScore',
                Palette.accentYellow,
              ),
              stat(Icons.flag_rounded, 'Levels', '$levels', Palette.accentBlue),
              stat(Icons.star_rounded, 'Stars', '$stars', Palette.accentPink),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 250.ms)
        .scaleXY(begin: 0.85, curve: Curves.easeOutBack);
  }
}

/// Shared fade+slide page transition.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 350),
  reverseTransitionDuration: const Duration(milliseconds: 250),
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) {
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
);
