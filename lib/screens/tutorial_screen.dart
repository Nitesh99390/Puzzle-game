import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../style/palette.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_button.dart';

/// Three illustrated steps explaining the colour-sorting rules.
class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        Icons.touch_app_rounded,
        'Tap a tube',
        'Tap any tube to pick it up. It lifts and glows so you always know what is selected.',
      ),
      (
        Icons.water_drop_rounded,
        'Pour the top colour',
        'Tap another tube to pour. Liquid only moves onto the same colour, or into an empty tube.',
      ),
      (
        Icons.star_rounded,
        'Fill it to finish',
        'Fill a tube with one colour to seal it with a golden cap. Sort every tube to clear the level!',
      ),
    ];

    return Scaffold(
      body: AnimatedBackground(
        colors: const [Palette.bgTop, Color(0xFF14294F), Color(0xFF1C4A44)],
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
                        'How to play',
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      GlassCard(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Palette.liquids[i * 3],
                                        Palette.liquids[i * 3 + 1],
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    steps[i].$1,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${i + 1}. ${steps[i].$2}',
                                        style: const TextStyle(
                                          fontFamily: Palette.displayFont,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        steps[i].$3,
                                        style: const TextStyle(
                                          fontFamily: Palette.bodyFont,
                                          fontSize: 12.5,
                                          height: 1.35,
                                          color: Palette.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate(delay: (110 * i).ms)
                          .fadeIn(duration: 320.ms)
                          .slideY(begin: 0.15, curve: Curves.easeOutCubic),
                    GlassCard(
                      glow: Palette.gold,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mic_rounded,
                            color: Palette.gold,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Bonus: complete tubes in quick succession to trigger combo reactions from your favourite netas!',
                              style: TextStyle(
                                fontFamily: Palette.bodyFont,
                                fontSize: 12.5,
                                height: 1.35,
                                color: Palette.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 380.ms).fadeIn(duration: 320.ms),
                    const SizedBox(height: 18),
                    Center(
                      child: GameButton(
                        label: 'Got it!',
                        icon: Icons.check_rounded,
                        width: 220,
                        compact: true,
                        gradient: Palette.greenButton,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
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
