import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// Sound settings (mute / music / sfx) persisted via [StorageService].
class SettingsController extends ChangeNotifier {
  SettingsController(this._storage)
    : _muted = _storage.muted,
      _musicOn = _storage.musicOn,
      _sfxOn = _storage.sfxOn;

  final StorageService _storage;
  bool _muted;
  bool _musicOn;
  bool _sfxOn;

  bool get muted => _muted;
  bool get musicOn => _musicOn;
  bool get sfxOn => _sfxOn;

  bool get musicAudible => !_muted && _musicOn;
  bool get sfxAudible => !_muted && _sfxOn;

  void toggleMuted() {
    _muted = !_muted;
    _storage.setMuted(_muted);
    notifyListeners();
  }

  void toggleMusic() {
    _musicOn = !_musicOn;
    _storage.setMusicOn(_musicOn);
    notifyListeners();
  }

  void toggleSfx() {
    _sfxOn = !_sfxOn;
    _storage.setSfxOn(_sfxOn);
    notifyListeners();
  }
}
