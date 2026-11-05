import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// Sound settings (mute / music / sfx / neta voices / track) persisted via
/// [StorageService].
class SettingsController extends ChangeNotifier {
  SettingsController(this._storage)
    : _muted = _storage.muted,
      _musicOn = _storage.musicOn,
      _sfxOn = _storage.sfxOn,
      _voicesOn = _storage.voicesOn,
      _musicTrack = _storage.musicTrack;

  final StorageService _storage;
  bool _muted;
  bool _musicOn;
  bool _sfxOn;
  bool _voicesOn;
  int _musicTrack;

  bool get muted => _muted;
  bool get musicOn => _musicOn;
  bool get sfxOn => _sfxOn;
  bool get voicesOn => _voicesOn;
  int get musicTrack => _musicTrack;

  bool get musicAudible => !_muted && _musicOn;
  bool get sfxAudible => !_muted && _sfxOn;
  bool get voicesAudible => !_muted && _voicesOn;

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

  void toggleVoices() {
    _voicesOn = !_voicesOn;
    _storage.setVoicesOn(_voicesOn);
    notifyListeners();
  }

  void setMusicTrack(int i) {
    if (i == _musicTrack) return;
    _musicTrack = i;
    _storage.setMusicTrack(i);
    notifyListeners();
  }
}
