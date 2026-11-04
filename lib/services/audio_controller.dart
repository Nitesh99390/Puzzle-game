import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'settings_controller.dart';

/// Sound effects available in the game.
enum Sfx { pour, select, tubeComplete, solved, illegal, button, undo }

const Map<Sfx, List<String>> _sfxFiles = {
  Sfx.pour: ['sfx/spsh1.mp3', 'sfx/swishswish1.mp3', 'sfx/wssh1.mp3'],
  Sfx.select: ['sfx/p1.mp3', 'sfx/p2.mp3'],
  Sfx.tubeComplete: ['sfx/wehee1.mp3', 'sfx/ehehee1.mp3'],
  Sfx.solved: ['sfx/yay1.mp3'],
  Sfx.illegal: ['sfx/dsht1.mp3'],
  Sfx.button: ['sfx/k1.mp3', 'sfx/k2.mp3'],
  Sfx.undo: ['sfx/fwfwfwfw1.mp3'],
};

const String _musicTrack = 'music/Mr_Smith-Sunday_Solitude.mp3';

/// Plays the looping background track and short sound effects.
///
/// Reacts to [SettingsController] (mute / music / sfx) and to the app
/// lifecycle (music pauses when the app goes to background).
class AudioController with WidgetsBindingObserver {
  AudioController(this._settings, {int polyphony = 4})
    : _sfxPlayers = List.generate(
        polyphony,
        (i) => AudioPlayer(playerId: 'sfx#$i'),
      ),
      _musicPlayer = AudioPlayer(playerId: 'music');

  final SettingsController _settings;
  final AudioPlayer _musicPlayer;
  final List<AudioPlayer> _sfxPlayers;
  final _random = Random();
  int _nextSfx = 0;
  bool _musicStarted = false;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_onSettingsChanged);

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(0.45);
    for (final p in _sfxPlayers) {
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setPlayerMode(PlayerMode.lowLatency);
    }
    // Pre-cache the effect files (no-op on platforms without caching).
    try {
      await AudioCache.instance.loadAll(
        _sfxFiles.values.expand((e) => e).toList(),
      );
    } catch (e) {
      debugPrint('SFX preload failed: $e');
    }
    // On mobile music can begin right away. On web browsers block autoplay,
    // so we also call [ensureMusicStarted] on the first user tap.
    if (!kIsWeb) await ensureMusicStarted();
  }

  /// Starts the background loop if allowed by settings. Safe to call often.
  Future<void> ensureMusicStarted() async {
    if (!_settings.musicAudible || _musicStarted) return;
    _musicStarted = true;
    try {
      await _musicPlayer.play(AssetSource(_musicTrack));
    } catch (e) {
      _musicStarted = false;
      debugPrint('Music start failed: $e');
    }
  }

  Future<void> playSfx(Sfx type) async {
    if (!_settings.sfxAudible) return;
    final files = _sfxFiles[type]!;
    final file = files[_random.nextInt(files.length)];
    final player = _sfxPlayers[_nextSfx];
    _nextSfx = (_nextSfx + 1) % _sfxPlayers.length;
    try {
      await player.stop();
      await player.play(AssetSource(file), volume: 0.9);
    } catch (e) {
      debugPrint('SFX failed: $e');
    }
  }

  void _onSettingsChanged() {
    if (_settings.musicAudible) {
      if (_musicStarted) {
        _musicPlayer.resume();
      } else {
        ensureMusicStarted();
      }
    } else {
      _musicPlayer.pause();
    }
    if (!_settings.sfxAudible) {
      for (final p in _sfxPlayers) {
        p.stop();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _musicPlayer.pause();
      case AppLifecycleState.resumed:
        if (_settings.musicAudible && _musicStarted) _musicPlayer.resume();
      case AppLifecycleState.inactive:
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_onSettingsChanged);
    _musicPlayer.dispose();
    for (final p in _sfxPlayers) {
      p.dispose();
    }
  }
}
