import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../game/game_logic.dart';
import '../services/audio_controller.dart';
import '../services/progress_controller.dart';
import '../style/palette.dart';
import '../widgets/game_button.dart';
import 'main_menu_screen.dart';
import 'play_session_screen.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    return Scaffold(
      backgroundColor: Palette.backgroundLevelSelection,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Select level',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: Palette.displayFont,
                        fontSize: 32,
                        color: Palette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Text(
              '★ ${progress.totalStars} / ${kLevelCount * 3}',
              style: const TextStyle(
                fontFamily: Palette.displayFont,
                fontSize: 18,
                color: Palette.ink,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 96,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: gameLevels.length,
                itemBuilder: (context, i) {
                  final level = gameLevels[i];
                  return _LevelTile(
                        number: level.number,
                        unlocked: progress.isUnlocked(level.number),
                        stars: progress.starsFor(level.number),
                        color: Palette.liquids[i % Palette.liquids.length],
                      )
                      .animate(delay: (25 * i).ms)
                      .fadeIn(duration: 250.ms)
                      .scaleXY(
                        begin: 0.5,
                        curve: Curves.easeOutBack,
                        duration: 400.ms,
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.number,
    required this.unlocked,
    required this.stars,
    required this.color,
  });

  final int number;
  final bool unlocked;
  final int stars;
  final Color color;

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
          color: unlocked ? color : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Palette.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: Palette.ink, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            unlocked
                ? Text(
                    '$number',
                    style: const TextStyle(
                      fontFamily: Palette.displayFont,
                      fontSize: 28,
                      color: Palette.trueWhite,
                      shadows: [
                        Shadow(color: Palette.ink, offset: Offset(1.5, 1.5)),
                      ],
                    ),
                  )
                : const Icon(Icons.lock_rounded, color: Palette.ink, size: 28),
            if (unlocked)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var s = 0; s < 3; s++)
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: s < stars ? Palette.accentYellow : Colors.white54,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
