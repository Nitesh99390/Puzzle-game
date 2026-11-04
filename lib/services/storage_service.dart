import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] holding everything the game
/// needs to survive an app restart: high scores, level progress and
/// audio settings.
class StorageService {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;

  static const _kHighScore = 'high_score';
  static const _kHighestLevel = 'highest_level_reached';
  static const _kCurrentLevel = 'current_level';
  static const _kMusicOn = 'music_on';
  static const _kSfxOn = 'sfx_on';
  static const _kMuted = 'muted';
  static const _kLevelScores = 'level_best_scores';
  static const _kLevelStars = 'level_stars';
  static const _kSavedBoard = 'saved_board';

  static Future<StorageService> create() async =>
      StorageService._(await SharedPreferences.getInstance());

  // ---------- Scores ----------
  int get highScore => _prefs.getInt(_kHighScore) ?? 0;
  Future<void> setHighScore(int v) => _prefs.setInt(_kHighScore, v);

  Map<int, int> get levelScores => _readIntMap(_kLevelScores);
  Future<void> setLevelScores(Map<int, int> m) =>
      _writeIntMap(_kLevelScores, m);

  Map<int, int> get levelStars => _readIntMap(_kLevelStars);
  Future<void> setLevelStars(Map<int, int> m) => _writeIntMap(_kLevelStars, m);

  // ---------- Progress ----------
  int get highestLevelReached => _prefs.getInt(_kHighestLevel) ?? 0;
  Future<void> setHighestLevelReached(int v) =>
      _prefs.setInt(_kHighestLevel, v);

  int get currentLevel => _prefs.getInt(_kCurrentLevel) ?? 1;
  Future<void> setCurrentLevel(int v) => _prefs.setInt(_kCurrentLevel, v);

  /// In-progress board so a half-played level can be resumed.
  SavedBoard? get savedBoard {
    final raw = _prefs.getString(_kSavedBoard);
    if (raw == null) return null;
    try {
      return SavedBoard.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setSavedBoard(SavedBoard? b) => b == null
      ? _prefs.remove(_kSavedBoard)
      : _prefs.setString(_kSavedBoard, jsonEncode(b.toJson()));

  // ---------- Sound settings ----------
  bool get muted => _prefs.getBool(_kMuted) ?? false;
  Future<void> setMuted(bool v) => _prefs.setBool(_kMuted, v);

  bool get musicOn => _prefs.getBool(_kMusicOn) ?? true;
  Future<void> setMusicOn(bool v) => _prefs.setBool(_kMusicOn, v);

  bool get sfxOn => _prefs.getBool(_kSfxOn) ?? true;
  Future<void> setSfxOn(bool v) => _prefs.setBool(_kSfxOn, v);

  Future<void> resetProgress() async {
    for (final k in [
      _kHighScore,
      _kHighestLevel,
      _kCurrentLevel,
      _kLevelScores,
      _kLevelStars,
      _kSavedBoard,
    ]) {
      await _prefs.remove(k);
    }
  }

  // ---------- helpers ----------
  Map<int, int> _readIntMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeIntMap(String key, Map<int, int> m) => _prefs.setString(
    key,
    jsonEncode(m.map((k, v) => MapEntry(k.toString(), v))),
  );
}

class SavedBoard {
  SavedBoard({
    required this.level,
    required this.tubes,
    required this.moves,
    required this.seconds,
  });

  final int level;
  final List<List<int>> tubes;
  final int moves;
  final int seconds;

  Map<String, dynamic> toJson() => {
    'level': level,
    'tubes': tubes,
    'moves': moves,
    'seconds': seconds,
  };

  factory SavedBoard.fromJson(Map<String, dynamic> j) => SavedBoard(
    level: (j['level'] as num).toInt(),
    tubes: [
      for (final t in j['tubes'] as List)
        [for (final c in t as List) (c as num).toInt()],
    ],
    moves: (j['moves'] as num).toInt(),
    seconds: (j['seconds'] as num).toInt(),
  );
}
