import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../game/game_logic.dart';
import '../game/level_state.dart';
import '../services/audio_controller.dart';
import '../services/progress_controller.dart';
import '../services/settings_controller.dart';
import '../style/palette.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/game_button.dart';
import '../widgets/tube_widget.dart';

class PlaySessionScreen extends StatefulWidget {
  const PlaySessionScreen({
    super.key,
    required this.levelNumber,
    this.resume = false,
  });

  final int levelNumber;
  final bool resume;

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  late LevelState _state;
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  bool _showWin = false;
  bool _newHighScore = false;
  int _finalScore = 0;
  int _finalStars = 0;

  @override
  void initState() {
    super.initState();
    _load(widget.levelNumber, resume: widget.resume);
  }

  void _load(int number, {bool resume = false}) {
    final progress = context.read<ProgressController>();
    final storage = progress.storage;
    final saved = storage.savedBoard;
    if (!resume && saved != null && saved.level != number) {
      // Starting a different level discards the old in-progress board.
      storage.setSavedBoard(null);
    }
    _state = LevelState(
      level: gameLevels[number - 1],
      storage: storage,
      resume: resume || saved?.level == number ? saved : null,
    );
    progress.setCurrentLevel(number);
  }

  @override
  void dispose() {
    _state.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _onTubeTap(int index) {
    final audio = context.read<AudioController>()..ensureMusicStarted();
    final outcome = _state.tapTube(index);
    switch (outcome.result) {
      case TapResult.selected:
        audio.playSfx(Sfx.select);
      case TapResult.poured:
        audio.playSfx(outcome.completedTube ? Sfx.tubeComplete : Sfx.pour);
        if (_state.solved) _onSolved();
      case TapResult.illegal:
        audio.playSfx(Sfx.illegal);
      case TapResult.deselected:
      case TapResult.ignored:
        break;
    }
    setState(() {});
  }

  Future<void> _onSolved() async {
    final audio = context.read<AudioController>();
    final progress = context.read<ProgressController>();
    _finalScore = _state.score;
    _finalStars = _state.stars;
    _newHighScore = progress.recordWin(
      level: _state.level.number,
      score: _finalScore,
      stars: _finalStars,
    );
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    audio.playSfx(Sfx.solved);
    _confetti.play();
    setState(() => _showWin = true);
  }

  void _restart() {
    _confetti.stop();
    setState(() {
      _showWin = false;
      _state.restart();
    });
  }

  void _nextLevel() {
    final next = _state.level.number + 1;
    if (next > kLevelCount) {
      Navigator.of(context).pop();
      return;
    }
    _confetti.stop();
    setState(() {
      _showWin = false;
      _state.dispose();
      _load(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LevelState>.value(
      value: _state,
      child: Scaffold(
        backgroundColor: Palette.backgroundPlaySession,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _TopBar(onRestart: _restart),
                  const _Hud(),
                  Expanded(child: _Board(onTap: _onTubeTap)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (_showWin)
              _WinPanel(
                level: _state.level.number,
                score: _finalScore,
                stars: _finalStars,
                moves: _state.moves,
                seconds: _state.seconds,
                newHighScore: _newHighScore,
                isLast: _state.level.number >= kLevelCount,
                onNext: _nextLevel,
                onReplay: _restart,
                onMenu: () => Navigator.of(context).pop(),
              ),
            // Confetti sits above everything for a full-screen celebration.
            Positioned.fill(child: CelebrationOverlay(controller: _confetti)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onRestart});
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LevelState>();
    final settings = context.watch<SettingsController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child:
                Text(
                      'Level ${state.level.number}',
                      key: ValueKey(state.level.number),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: Palette.displayFont,
                        fontSize: 30,
                        color: Palette.ink,
                      ),
                    )
                    .animate(key: ValueKey('title-${state.level.number}'))
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.6, curve: Curves.easeOutBack),
          ),
          RoundIconButton(
            icon: settings.muted
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            tooltip: settings.muted ? 'Unmute' : 'Mute',
            onPressed: settings.toggleMuted,
          ),
          const SizedBox(width: 8),
          RoundIconButton(
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            onPressed: state.canUndo
                ? () {
                    if (state.undo()) {
                      context.read<AudioController>().playSfx(Sfx.undo);
                    }
                  }
                : null,
          ),
          const SizedBox(width: 8),
          RoundIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Restart',
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LevelState>();
    final best = context.select<ProgressController, int>((p) => p.highScore);
    final mm = (s.seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (s.seconds % 60).toString().padLeft(2, '0');

    Widget chip(IconData icon, String text, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.trueWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.ink, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Palette.ink,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          chip(
            Icons.swap_vert_rounded,
            'Moves: ${s.moves}',
            Palette.accentBlue,
          ),
          chip(Icons.timer_outlined, 'Time: $mm:$ss', Palette.accentPink),
          chip(Icons.bolt_rounded, 'Score: ${s.score}', Palette.accentGreen),
          chip(Icons.emoji_events_rounded, 'Best: $best', Palette.accentYellow),
        ].animate(interval: 60.ms).fadeIn().slideY(begin: -0.4),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.onTap});
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LevelState>();
    final n = s.tubes.length;
    return LayoutBuilder(
      builder: (context, c) {
        // Two rows when there are many tubes.
        final perRow = n <= 6 ? n : (n / 2).ceil();
        final rows = (n / perRow).ceil();
        final tubeW = min(64.0, (c.maxWidth - 24) / perRow - 14);
        final tubeH = min(tubeW * 3.6, (c.maxHeight / rows) - 52);

        Widget tube(int i) =>
            TubeWidget(
                  key: ValueKey('tube-${s.level.number}-$i'),
                  colors: s.tubes[i],
                  capacity: s.capacity,
                  selected: s.selected == i,
                  complete: s.isTubeComplete(i),
                  pourTick: s.pourTicks[i] ?? 0,
                  shakeTick: s.lastIllegalTube == i ? s.illegalTick : 0,
                  onTap: () => onTap(i),
                  width: tubeW,
                  height: max(tubeH, 120),
                )
                // Entrance: tubes drop in one after another with a bounce.
                .animate(
                  key: ValueKey('enter-${s.level.number}-$i'),
                  delay: (70 * i).ms,
                )
                .slideY(begin: -1.2, duration: 600.ms, curve: Curves.bounceOut)
                .fadeIn(duration: 200.ms);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < rows; r++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = r * perRow; i < min(n, (r + 1) * perRow); i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: tube(i),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WinPanel extends StatelessWidget {
  const _WinPanel({
    required this.level,
    required this.score,
    required this.stars,
    required this.moves,
    required this.seconds,
    required this.newHighScore,
    required this.isLast,
    required this.onNext,
    required this.onReplay,
    required this.onMenu,
  });

  final int level, score, stars, moves, seconds;
  final bool newHighScore, isLast;
  final VoidCallback onNext, onReplay, onMenu;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Palette.ink.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child:
            Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  constraints: const BoxConstraints(maxWidth: 380),
                  decoration: BoxDecoration(
                    color: Palette.backgroundMain,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Palette.ink, width: 4),
                    boxShadow: const [
                      BoxShadow(color: Palette.ink, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? 'You beat the game!' : 'Level $level solved!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: Palette.displayFont,
                          fontSize: 30,
                          color: Palette.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Icon(
                                  Icons.star_rounded,
                                  size: i == 1 ? 72 : 56,
                                  color: i < stars
                                      ? Palette.accentYellow
                                      : Colors.black12,
                                  shadows: i < stars
                                      ? const [
                                          Shadow(
                                            color: Palette.ink,
                                            offset: Offset(2, 3),
                                          ),
                                        ]
                                      : null,
                                )
                                .animate(delay: (400 + 250 * i).ms)
                                .scaleXY(
                                  begin: 0,
                                  duration: 600.ms,
                                  curve: Curves.elasticOut,
                                )
                                .rotate(
                                  begin: -0.25,
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                            '$score',
                            style: const TextStyle(
                              fontFamily: Palette.displayFont,
                              fontSize: 48,
                              color: Palette.accentPink,
                            ),
                          )
                          .animate(delay: 900.ms)
                          .fadeIn()
                          .scaleXY(begin: 1.6, curve: Curves.easeOutBack),
                      Text(
                        '$moves moves · ${seconds}s',
                        style: const TextStyle(
                          color: Palette.inkLight,
                          fontSize: 15,
                        ),
                      ),
                      if (newHighScore) ...[
                        const SizedBox(height: 10),
                        Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Palette.accentYellow,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Palette.ink,
                                  width: 2,
                                ),
                              ),
                              child: const Text(
                                'NEW HIGH SCORE!',
                                style: TextStyle(
                                  fontFamily: Palette.displayFont,
                                  fontSize: 18,
                                  color: Palette.ink,
                                ),
                              ),
                            )
                            .animate(
                              delay: 1200.ms,
                              onPlay: (c) => c.repeat(reverse: true),
                            )
                            .scaleXY(
                              end: 1.08,
                              duration: 600.ms,
                              curve: Curves.easeInOut,
                            )
                            .shimmer(duration: 1200.ms),
                      ],
                      const SizedBox(height: 22),
                      ...[
                            GameButton(
                              label: isLast ? 'Menu' : 'Next Level',
                              icon: isLast
                                  ? Icons.home_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Palette.accentGreen,
                              onPressed: isLast ? onMenu : onNext,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GameButton(
                                  label: 'Replay',
                                  compact: true,
                                  width: 130,
                                  color: Palette.accentBlue,
                                  onPressed: onReplay,
                                ),
                                const SizedBox(width: 12),
                                GameButton(
                                  label: 'Menu',
                                  compact: true,
                                  width: 130,
                                  color: Palette.accentPink,
                                  onPressed: onMenu,
                                ),
                              ],
                            ),
                          ]
                          .animate(interval: 100.ms, delay: 1000.ms)
                          .fadeIn()
                          .slideY(begin: 0.5, curve: Curves.easeOutBack),
                    ],
                  ),
                )
                .animate()
                .scaleXY(begin: 0.6, duration: 500.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 200.ms),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}
