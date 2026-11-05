import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../game/game_logic.dart';
import '../services/audio_controller.dart';
import '../services/progress_controller.dart';
import '../style/palette.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_button.dart';
import 'main_menu_screen.dart';
import 'play_session_screen.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    return Scaffold(
      body: AnimatedBackground(
        colors: const [
          Palette.bgTop,
          Color(0xFF1A2A5E),
          Color(0xFF123A4A),
        ],
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Select Level',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: Palette.displayFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 46),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '★ ${progress.totalStars} / ${kLevelCount * 3}   ·   ${progress.highestLevelReached}/$kLevelCount cleared',
                  style: const TextStyle(
                    fontFamily: Palette.bodyFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    color: Palette.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 84,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.86,
                      ),
                  itemCount: gameLevels.length,
                  itemBuilder: (context, i) {
                    final level = gameLevels[i];
                    return _LevelTile(
                          number: level.number,
                          colors: level.colors,
                          unlocked: progress.isUnlocked(level.number),
                          cleared: progress.starsFor(level.number) > 0,
                          stars: progress.starsFor(level.number),
                          accent: Palette.liquids[i % Palette.liquids.length],
                        )
                        .animate(delay: (18 * i).ms)
                        .fadeIn(duration: 240.ms)
                        .scaleXY(
                          begin: 0.7,
                          curve: Curves.easeOutBack,
                          duration: 380.ms,
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.number,
    required this.colors,
    required this.unlocked,
    required this.cleared,
    required this.stars,
    required this.accent,
  });

  final int number;
  final int colors;
  final bool unlocked;
  final bool cleared;
  final int stars;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final audio = context.read<AudioController>();
        audio.ensureMusicStarted();
        if (!unlocked) {
          audio.playSfx(Sfx.illegal);
          return;
        }
        audio.playSfx(Sfx.button);
        Navigator.of(
          context,
        ).push(fadeRoute(PlaySessionScreen(levelNumber: number)));
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: unlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(accent, Colors.white, 0.18)!,
                    Color.lerp(accent, Colors.black, 0.28)!,
                  ],
                )
              : const LinearGradient(
                  colors: [Color(0xFF35304A), Color(0xFF232036)],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: unlocked ? 0.35 : 0.1),
            width: 1.2,
          ),
          boxShadow: [
            if (unlocked)
              BoxShadow(
                color: accent.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (unlocked)
              Text(
                '$number',
                style: const TextStyle(
                  fontFamily: Palette.displayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Color(0x88000000), offset: Offset(0, 2)),
                  ],
                ),
              )
            else
              const Icon(Icons.lock_rounded, color: Colors.white38, size: 24),
            if (unlocked) ...[
              Text(
                '$colors colors',
                style: TextStyle(
                  fontFamily: Palette.bodyFont,
                  fontSize: 8.5,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var s = 0; s < 3; s++)
                    Icon(
                      Icons.star_rounded,
                      size: 11,
                      color: s < stars ? Palette.gold : Colors.white24,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
