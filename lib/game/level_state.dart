import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';
import 'game_logic.dart';

enum TapResult { selected, deselected, poured, illegal, ignored }

/// Result of one tap, used by the UI to trigger sounds / animations.
class TapOutcome {
  const TapOutcome(
    this.result, {
    this.from,
    this.to,
    this.color,
    this.amount = 0,
    this.completedTube = false,
    this.comboCount = 0,
    this.illegalStreak = 0,
  });
  final TapResult result;
  final int? from;
  final int? to;
  final int? color;
  final int amount;
  final bool completedTube;

  /// How many tubes have been completed within a short window (>=2 = combo).
  final int comboCount;
  final int illegalStreak;
}

/// Mutable state of a single play session.
class LevelState extends ChangeNotifier {
  LevelState({required this.level, required this.storage, SavedBoard? resume}) {
    if (resume != null && resume.level == level.number) {
      _tubes = cloneBoard(resume.tubes);
      _moves = resume.moves;
      _seconds = resume.seconds;
    } else {
      _initial = LevelGenerator.generate(level);
      _tubes = cloneBoard(_initial!);
    }
    _initial ??= LevelGenerator.generate(level);
    _hints = storage.hints;
    _startTimer();
  }

  final LevelDef level;
  final StorageService storage;

  Board? _initial;
  late Board _tubes;
  final List<Board> _history = [];
  int? _selected;
  int _moves = 0;
  int _seconds = 0;
  bool _solved = false;
  bool _paused = false;
  Timer? _timer;
  int _hints = 3;
  int _illegalStreak = 0;
  final List<DateTime> _recentCompletes = [];
  Move? _hint;

  int lastIllegalTube = -1;
  int illegalTick = 0;

  /// Incremented on undo / restart so the UI can cancel running animations.
  int resetTick = 0;

  Board get tubes => _tubes;
  int? get selected => _selected;
  int get moves => _moves;
  int get seconds => _seconds;
  bool get solved => _solved;
  bool get canUndo => _history.isNotEmpty && !_solved;
  int get capacity => level.capacity;
  int get hintsLeft => _hints;
  Move? get activeHint => _hint;
  bool get isStuck =>
      !_solved && !PuzzleRules.hasUsefulMove(_tubes, capacity);

  set paused(bool v) => _paused = v;

  int get score {
    final penalty = _moves * 12 + _seconds * 2;
    return max(100, level.baseScore + 1000 - penalty);
  }

  int get par => level.colors * 2 + 2;

  int get stars {
    if (_moves <= par) return 3;
    if (_moves <= par * 1.6) return 2;
    return 1;
  }

  bool isTubeComplete(int i) => PuzzleRules.isTubeComplete(_tubes[i], capacity);

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_solved || _paused) return;
      _seconds++;
      notifyListeners();
    });
  }

  TapOutcome tapTube(int index) {
    if (_solved) return const TapOutcome(TapResult.ignored);
    final sel = _selected;
    if (sel == null) {
      if (_tubes[index].isEmpty || isTubeComplete(index)) {
        return const TapOutcome(TapResult.ignored);
      }
      _selected = index;
      notifyListeners();
      return TapOutcome(TapResult.selected, from: index);
    }
    if (sel == index) {
      _selected = null;
      notifyListeners();
      return const TapOutcome(TapResult.deselected);
    }
    if (!PuzzleRules.canPour(_tubes, sel, index, capacity)) {
      _illegalStreak++;
      lastIllegalTube = index;
      illegalTick++;
      // Allow switching selection to another pourable tube.
      if (_tubes[index].isNotEmpty && !isTubeComplete(index)) {
        _selected = index;
      } else {
        _selected = null;
      }
      notifyListeners();
      return TapOutcome(
        TapResult.illegal,
        from: _selected,
        to: index,
        illegalStreak: _illegalStreak,
      );
    }

    _illegalStreak = 0;
    _hint = null;
    _history.add(cloneBoard(_tubes));
    final color = _tubes[sel].last;
    final amount = PuzzleRules.pour(_tubes, sel, index, capacity);
    _moves++;
    _selected = null;
    final completed = isTubeComplete(index);
    var combo = 0;
    if (completed) {
      final now = DateTime.now();
      _recentCompletes
        ..add(now)
        ..removeWhere((t) => now.difference(t).inSeconds > 6);
      combo = _recentCompletes.length;
    }
    _solved = PuzzleRules.isSolved(_tubes, capacity);
    if (_solved) {
      _timer?.cancel();
      storage.setSavedBoard(null);
    } else {
      _persist();
    }
    notifyListeners();
    return TapOutcome(
      TapResult.poured,
      from: sel,
      to: index,
      color: color,
      amount: amount,
      completedTube: completed,
      comboCount: combo,
    );
  }

  void clearSelection() {
    if (_selected == null) return;
    _selected = null;
    notifyListeners();
  }

  bool undo() {
    if (!canUndo) return false;
    _tubes = _history.removeLast();
    _selected = null;
    _hint = null;
    _moves++; // undo counts as a move to keep scoring fair
    resetTick++;
    _persist();
    notifyListeners();
    return true;
  }

  /// Computes and shows a hint. Returns false if no hints left / no move.
  bool useHint() {
    if (_solved || _hints <= 0) return false;
    final m = PuzzleSolver.hint(_tubes, capacity);
    if (m == null) return false;
    _hints--;
    storage.setHints(_hints);
    _hint = m;
    _selected = null;
    notifyListeners();
    return true;
  }

  void grantHint() {
    _hints = min(_hints + 1, 9);
    storage.setHints(_hints);
  }

  void restart() {
    _tubes = cloneBoard(_initial!);
    _history.clear();
    _selected = null;
    _hint = null;
    _moves = 0;
    _seconds = 0;
    _solved = false;
    _illegalStreak = 0;
    _recentCompletes.clear();
    resetTick++;
    _startTimer();
    _persist();
    notifyListeners();
  }

  void _persist() {
    storage.setSavedBoard(
      SavedBoard(
        level: level.number,
        tubes: _tubes,
        moves: _moves,
        seconds: _seconds,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_solved) _persist();
    super.dispose();
  }
}
