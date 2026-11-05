import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../game/game_logic.dart';
import '../game/level_state.dart';
import '../services/audio_controller.dart';
import '../services/neta_voices.dart';
import '../services/progress_controller.dart';
import '../services/settings_controller.dart';
import '../style/palette.dart';
import '../widgets/animated_background.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/game_board.dart';
import '../widgets/game_button.dart';
import '../widgets/neta_speech_bubble.dart';

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
    duration: const Duration(seconds: 4),
  );
  bool _showWin = false;
  bool _newHighScore = false;
  int _finalScore = 0;
  int _finalStars = 0;

  @override
  void initState() {
    super.initState();
    _load(widget.levelNumber, resume: widget.resume);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AudioController>().react(VoiceEvent.levelStart);
    });
  }

  void _load(int number, {bool resume = false}) {
    final progress = context.read<ProgressController>();
    final storage = progress.storage;
    final saved = storage.savedBoard;
    if (!resume && saved != null && saved.level != number) {
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

  AudioController get _audio => context.read<AudioController>();

  void _onOutcome(TapOutcome outcome) {
    _audio.ensureMusicStarted();
    switch (outcome.result) {
      case TapResult.selected:
        _audio.playSfx(Sfx.select);
      case TapResult.poured:
        _audio.playSfx(Sfx.pour);
        if (outcome.illegalStreak == 0 && _state.isStuck) {
          // Soft nudge: player may restart or use a hint.
          setState(() {});
        }
      case TapResult.illegal:
        _audio.playSfx(Sfx.illegal);
        HapticFeedback.heavyImpact();
        _audio.react(
          outcome.illegalStreak >= 3
              ? VoiceEvent.illegalStreak
              : VoiceEvent.illegalMove,
        );
      case TapResult.deselected:
      case TapResult.ignored:
        break;
    }
    setState(() {});
  }

  void _onPourLanded(TapOutcome outcome) {
    if (outcome.completedTube) {
      if (outcome.comboCount >= 2) {
        _audio.playSfx(Sfx.tubeComplete);
        _audio.react(VoiceEvent.comboTubes, force: true);
      } else {
        _audio.playSfx(Sfx.tubeComplete);
        _audio.react(VoiceEvent.tubeComplete);
      }
      HapticFeedback.mediumImpact();
    }
    if (_state.solved) _onSolved();
  }

  Future<void> _onSolved() async {
    final progress = context.read<ProgressController>();
    _finalScore = _state.score;
    _finalStars = _state.stars;
    _newHighScore = progress.recordWin(
      level: _state.level.number,
      score: _finalScore,
      stars: _finalStars,
    );
    final isLast = _state.level.number >= kLevelCount;
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    _audio.playSfx(Sfx.solved);
    if (_finalStars == 3) {
      _audio.react(VoiceEvent.perfectWin, force: true);
    } else if (_newHighScore) {
      _audio.react(VoiceEvent.newHighScore, force: true);
    } else {
      _audio.react(VoiceEvent.win, force: true);
    }
    if (isLast) _audio.react(VoiceEvent.gameFinished, force: true);
    _confetti.play();
    setState(() => _showWin = true);
  }

  void _restart() {
    _confetti.stop();
    _audio.react(VoiceEvent.restart);
    setState(() {
      _showWin = false;
      _state.restart();
    });
  }

  void _undo() {
    if (_state.undo()) {
      _audio.playSfx(Sfx.undo);
      _audio.react(VoiceEvent.undo);
      setState(() {});
    }
  }

  void _hint() {
    if (_state.hintsLeft <= 0) {
      _audio.playSfx(Sfx.illegal);
      return;
    }
    if (_state.useHint()) {
      _audio.playSfx(Sfx.star);
      _audio.react(VoiceEvent.hint, force: true);
      setState(() {});
    }
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
    _audio.react(VoiceEvent.levelStart);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LevelState>.value(
      value: _state,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: AnimatedBackground(
            colors: const [
              Palette.bgTop,
              Color(0xFF1B1048),
              Color(0xFF2E1465),
            ],
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _TopBar(onRestart: _restart, onUndo: _undo),
                      _Hud(state: _state),
                      Expanded(
                        child: GameBoard(
                          key: ValueKey('board-${_state.level.number}'),
                          state: _state,
                          onOutcome: _onOutcome,
                          onPourLanded: _onPourLanded,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                        child: _BottomBar(
                          state: _state,
                          onHint: _hint,
                          onRestart: _restart,
                        ),
                      ),
                    ],
                  ),
                  // Neta reaction bubble.
                  Positioned(
                    top: 104,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: ValueListenableBuilder<VoiceLine?>(
                        valueListenable: _audio.speaking,
                        builder: (_, line, __) => NetaSpeechBubble(line: line),
                      ),
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
                  Positioned.fill(
                    child: CelebrationOverlay(controller: _confetti),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onRestart, required this.onUndo});

  final VoidCallback onRestart;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LevelState>();
    final settings = context.watch<SettingsController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'LEVEL ${state.level.number}',
                  style: const TextStyle(
                    fontFamily: Palette.bodyFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 3.4,
                    color: Palette.textMuted,
                  ),
                ),
                Text(
                      '${state.level.colors} Colors',
                      key: ValueKey(state.level.number),
                      style: const TextStyle(
                        fontFamily: Palette.displayFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    )
                    .animate(key: ValueKey('t-${state.level.number}'))
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.4, curve: Curves.easeOutBack),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            onPressed: state.canUndo ? onUndo : null,
          ),
          const SizedBox(width: 8),
          RoundIconButton(
            icon: settings.muted
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            tooltip: settings.muted ? 'Unmute' : 'Mute',
            onPressed: settings.toggleMuted,
          ),
        ],
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.state});
  final LevelState state;

  @override
  Widget build(BuildContext context) {
    final best = context.select<ProgressController, int>((p) => p.highScore);
    final mm = (state.seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (state.seconds % 60).toString().padLeft(2, '0');

    Widget pill(IconData icon, String value, String label, Color c) => Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: c),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: Palette.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: Palette.bodyFont,
                fontSize: 8.5,
                letterSpacing: 1,
                color: Palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Row(
        children: [
          pill(
            Icons.swap_vert_rounded,
            '${state.moves}',
            'MOVES',
            Palette.cyan,
          ),
          pill(Icons.timer_outlined, '$mm:$ss', 'TIME', Palette.pink),
          pill(
            Icons.bolt_rounded,
            '${state.score}',
            'SCORE',
            Palette.indiaGreen,
          ),
          pill(Icons.emoji_events_rounded, '$best', 'BEST', Palette.gold),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state,
    required this.onHint,
    required this.onRestart,
  });

  final LevelState state;
  final VoidCallback onHint;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GameButton(
          label: 'Hint',
          icon: Icons.lightbulb_rounded,
          compact: true,
          width: 132,
          gradient: Palette.blueButton,
          subtitle: '${state.hintsLeft} left',
          onPressed: state.hintsLeft > 0 ? onHint : null,
        ),
        const SizedBox(width: 10),
        GameButton(
          label: 'Restart',
          icon: Icons.refresh_rounded,
          compact: true,
          width: 140,
          gradient: Palette.pinkButton,
          onPressed: onRestart,
        ),
      ],
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
      child: ColoredBox(
        color: Palette.bgTop.withValues(alpha: 0.72),
        child: Center(
          child: SingleChildScrollView(
            child: GlassCard(
                  margin: const EdgeInsets.all(22),
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  radius: 28,
                  glow: Palette.gold,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? 'Bharat Jeet Gaya!' : 'Level $level Cleared!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: Palette.displayFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Icon(
                                  Icons.star_rounded,
                                  size: i == 1 ? 62 : 48,
                                  color: i < stars
                                      ? Palette.gold
                                      : Colors.white24,
                                  shadows: i < stars
                                      ? const [
                                          Shadow(
                                            color: Color(0xAA000000),
                                            offset: Offset(0, 3),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                )
                                .animate(delay: (320 + 180 * i).ms)
                                .scaleXY(
                                  begin: 0,
                                  duration: 600.ms,
                                  curve: Curves.elasticOut,
                                ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: score),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Text(
                          '$v',
                          style: const TextStyle(
                            fontFamily: Palette.displayFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 46,
                            color: Palette.gold,
                          ),
                        ),
                      ),
                      Text(
                        '$moves moves · ${seconds}s · ${max(0, score)} pts',
                        style: const TextStyle(
                          fontFamily: Palette.bodyFont,
                          color: Palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (newHighScore) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: Palette.goldButton,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'NEW HIGH SCORE!',
                            style: TextStyle(
                              fontFamily: Palette.bodyFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 1.4,
                              color: Palette.bgTop,
                            ),
                          ),
                        ).animate().shimmer(duration: 1400.ms),
                      ],
                      const SizedBox(height: 18),
                      GameButton(
                        label: isLast ? 'Main Menu' : 'Next Level',
                        icon: isLast
                            ? Icons.home_rounded
                            : Icons.arrow_forward_rounded,
                        gradient: Palette.greenButton,
                        width: 250,
                        onPressed: isLast ? onMenu : onNext,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GameButton(
                            label: 'Replay',
                            compact: true,
                            width: 118,
                            gradient: Palette.blueButton,
                            onPressed: onReplay,
                          ),
                          const SizedBox(width: 10),
                          GameButton(
                            label: 'Menu',
                            compact: true,
                            width: 118,
                            gradient: Palette.pinkButton,
                            onPressed: onMenu,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                .animate()
                .scaleXY(begin: 0.7, duration: 520.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 220.ms),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 260.ms);
  }
}
