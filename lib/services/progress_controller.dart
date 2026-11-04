import 'package:flutter/foundation.dart';

import '../game/game_logic.dart';
import 'storage_service.dart';

/// Player progress: unlocked levels, best score per level, stars and the
/// overall high score. Everything is persisted through [StorageService].
class ProgressController extends ChangeNotifier {
  ProgressController(this.storage)
    : _highestLevelReached = storage.highestLevelReached,
      _highScore = storage.highScore,
      _levelScores = storage.levelScores,
      _levelStars = storage.levelStars,
      _currentLevel = storage.currentLevel;

  final StorageService storage;

  int _highestLevelReached;
  int _highScore;
  int _currentLevel;
  Map<int, int> _levelScores;
  Map<int, int> _levelStars;

  int get highestLevelReached => _highestLevelReached;
  int get highScore => _highScore;
  int get currentLevel => _currentLevel;
  int bestScoreFor(int level) => _levelScores[level] ?? 0;
  int starsFor(int level) => _levelStars[level] ?? 0;
  int get totalStars => _levelStars.values.fold(0, (a, b) => a + b);

  bool isUnlocked(int level) => level <= _highestLevelReached + 1;

  /// The level the "Play" button should open.
  int get nextLevelToPlay =>
      (_highestLevelReached + 1).clamp(1, kLevelCount).toInt();

  void setCurrentLevel(int level) {
    _currentLevel = level;
    storage.setCurrentLevel(level);
  }

  /// Records a win. Returns true when this sets a new overall high score.
  bool recordWin({required int level, required int score, required int stars}) {
    if (level > _highestLevelReached) {
      _highestLevelReached = level;
      storage.setHighestLevelReached(level);
    }
    if (score > (_levelScores[level] ?? 0)) {
      _levelScores = {..._levelScores, level: score};
      storage.setLevelScores(_levelScores);
    }
    if (stars > (_levelStars[level] ?? 0)) {
      _levelStars = {..._levelStars, level: stars};
      storage.setLevelStars(_levelStars);
    }
    var newHigh = false;
    if (score > _highScore) {
      _highScore = score;
      storage.setHighScore(score);
      newHigh = true;
    }
    notifyListeners();
    return newHigh;
  }

  Future<void> reset() async {
    await storage.resetProgress();
    _highestLevelReached = 0;
    _highScore = 0;
    _currentLevel = 1;
    _levelScores = {};
    _levelStars = {};
    notifyListeners();
  }
}
