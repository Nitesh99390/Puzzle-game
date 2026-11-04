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
    this.completedTube = false,
  });
  final TapResult result;
  final int? from;
  final int? to;
  final bool completedTube;
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
  Timer? _timer;

  /// Incremented whenever a tube is involved in a pour so the widget can
  /// replay its animation (keyed by this value).
  final Map<int, int> pourTicks = {};
  int lastIllegalTube = -1;
  int illegalTick = 0;

  Board get tubes => _tubes;
  int? get selected => _selected;
  int get moves => _moves;
  int get seconds => _seconds;
  bool get solved => _solved;
  bool get canUndo => _history.isNotEmpty && !_solved;
  int get capacity => level.capacity;

  int get score {
    final penalty = _moves * 12 + _seconds * 2;
    return max(100, level.baseScore + 1000 - penalty);
  }

  int get stars {
    final par = level.colors * 2 + 2;
    if (_moves <= par) return 3;
    if (_moves <= par * 1.6) return 2;
    return 1;
  }

  bool isTubeComplete(int i) => PuzzleRules.isTubeComplete(_tubes[i], capacity);

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_solved) return;
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
      // Allow switching selection to another pourable tube.
      if (_tubes[index].isNotEmpty && !isTubeComplete(index)) {
        lastIllegalTube = index;
        illegalTick++;
        _selected = index;
        notifyListeners();
        return TapOutcome(TapResult.illegal, from: index);
      }
      lastIllegalTube = index;
      illegalTick++;
      _selected = null;
      notifyListeners();
      return TapOutcome(TapResult.illegal, to: index);
    }

    _history.add(cloneBoard(_tubes));
    PuzzleRules.pour(_tubes, sel, index, capacity);
    _moves++;
    _selected = null;
    pourTicks[sel] = (pourTicks[sel] ?? 0) + 1;
    pourTicks[index] = (pourTicks[index] ?? 0) + 1;
    final completed = isTubeComplete(index);
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
      completedTube: completed,
    );
  }

  bool undo() {
    if (!canUndo) return false;
    _tubes = _history.removeLast();
    _selected = null;
    _moves++; // undo counts as a move to keep scoring fair
    _persist();
    notifyListeners();
    return true;
  }

  void restart() {
    _tubes = cloneBoard(_initial!);
    _history.clear();
    _selected = null;
    _moves = 0;
    _seconds = 0;
    _solved = false;
    pourTicks.clear();
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
