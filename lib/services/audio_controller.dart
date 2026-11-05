import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'neta_voices.dart';
import 'settings_controller.dart';

/// Sound effects available in the game.
enum Sfx { pour, select, tubeComplete, solved, illegal, button, undo, star }

const Map<Sfx, List<String>> _sfxFiles = {
  Sfx.pour: ['ui/pour_liquid.mp3'],
  Sfx.select: ['ui/glass_001.mp3', 'ui/glass_002.mp3'],
  Sfx.tubeComplete: ['ui/tube_complete.mp3'],
  Sfx.solved: ['ui/win_fanfare.mp3'],
  Sfx.illegal: ['ui/error_004.mp3'],
  Sfx.button: ['ui/click_001.mp3', 'ui/click_003.mp3'],
  Sfx.undo: ['ui/back_002.mp3'],
  Sfx.star: ['ui/confirmation_001.mp3'],
};

const Map<Sfx, double> _sfxVolume = {
  Sfx.pour: 0.75,
  Sfx.select: 0.55,
  Sfx.tubeComplete: 0.8,
  Sfx.solved: 0.85,
  Sfx.illegal: 0.6,
  Sfx.button: 0.45,
  Sfx.undo: 0.6,
  Sfx.star: 0.7,
};

/// Background music playlist (Kevin MacLeod – incompetech.com, CC BY 4.0).
class MusicTrack {
  const MusicTrack(this.file, this.title);
  final String file;
  final String title;
}

const List<MusicTrack> musicTracks = [
  MusicTrack('music/vadodara_chill.mp3', 'Vadodara (Chill Mix)'),
  MusicTrack('music/monkeys_spinning_monkeys.mp3', 'Monkeys Spinning Monkeys'),
  MusicTrack('music/carefree.mp3', 'Carefree'),
  MusicTrack('music/naraina.mp3', 'Naraina'),
  MusicTrack('music/fluffing_a_duck.mp3', 'Fluffing a Duck'),
];

/// Plays background music, short sound effects and neta voice reactions.
///
/// * Music: one looping track, ducked while a voice line is speaking.
/// * SFX:   small pool of low-latency players (polyphony).
/// * Voice: single dedicated player with cooldown + priority so meme lines
///          never overlap or spam.
class AudioController with WidgetsBindingObserver {
  AudioController(this._settings, {int polyphony = 5})
    : _sfxPlayers = List.generate(
        polyphony,
        (i) => AudioPlayer(playerId: 'sfx#$i'),
      ),
      _musicPlayer = AudioPlayer(playerId: 'music'),
      _voicePlayer = AudioPlayer(playerId: 'voice');

  final SettingsController _settings;
  final AudioPlayer _musicPlayer;
  final AudioPlayer _voicePlayer;
  final List<AudioPlayer> _sfxPlayers;
  final _random = Random();
  int _nextSfx = 0;
  bool _musicStarted = false;
  bool _initialized = false;
  int _currentTrack = -1;

  static const double _musicVolume = 0.42;
  static const double _duckedVolume = 0.12;

  /// The voice line currently speaking (drives the speech-bubble UI).
  final ValueNotifier<VoiceLine?> speaking = ValueNotifier(null);
  DateTime _lastVoiceAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _speakingPriority = 0;
  final Map<VoiceEvent, int> _cursor = {};
  Timer? _bubbleTimer;
  StreamSubscription<void>? _voiceDone;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_onSettingsChanged);

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(_musicVolume);
    await _voicePlayer.setReleaseMode(ReleaseMode.stop);
    for (final p in _sfxPlayers) {
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setPlayerMode(PlayerMode.lowLatency);
    }
    _voiceDone = _voicePlayer.onPlayerComplete.listen((_) => _endVoice());
    try {
      await AudioCache.instance.loadAll([
        ..._sfxFiles.values.expand((e) => e),
        ...NetaVoices.all.map((v) => v.asset),
      ]);
    } catch (e) {
      debugPrint('Audio preload failed: $e');
    }
    if (!kIsWeb) await ensureMusicStarted();
  }

  String get currentTrackTitle =>
      musicTracks[_trackIndex.clamp(0, musicTracks.length - 1)].title;

  int get _trackIndex =>
      _settings.musicTrack.clamp(0, musicTracks.length - 1).toInt();

  /// Starts the background loop if allowed by settings. Safe to call often.
  Future<void> ensureMusicStarted() async {
    if (!_settings.musicAudible) return;
    if (_musicStarted && _currentTrack == _trackIndex) return;
    _musicStarted = true;
    _currentTrack = _trackIndex;
    try {
      await _musicPlayer.stop();
      await _musicPlayer.play(
        AssetSource(musicTracks[_currentTrack].file),
        volume: _musicVolume,
      );
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
      await player.play(AssetSource(file), volume: _sfxVolume[type] ?? 0.8);
    } catch (e) {
      debugPrint('SFX failed: $e');
    }
  }

  /// Plays a fitting neta reaction for [event]. Returns the line or null if
  /// skipped (cooldown / chance / settings).
  VoiceLine? react(VoiceEvent event, {bool force = false}) {
    if (!_settings.voicesAudible) return null;
    final prio = NetaVoices.priority(event);
    final now = DateTime.now();
    final busy = speaking.value != null;
    if (!force) {
      if (busy && prio <= _speakingPriority) return null;
      if (!busy && prio < 2 && now.difference(_lastVoiceAt).inMilliseconds < 2600) {
        return null;
      }
      if (_random.nextDouble() > (NetaVoices.chance[event] ?? 1)) return null;
    }
    final options = NetaVoices.byEvent[event]!;
    // Rotate through options (shuffled start) so lines don't repeat back-to-back.
    final c = _cursor[event] ?? _random.nextInt(options.length);
    _cursor[event] = c + 1;
    final line = options[c % options.length];
    _speak(line, prio);
    return line;
  }

  /// Plays a specific line (used by the "Neta Soundboard").
  void speakLine(VoiceLine line) => _speak(line, 9);

  Future<void> _speak(VoiceLine line, int prio) async {
    _lastVoiceAt = DateTime.now();
    _speakingPriority = prio;
    speaking.value = line;
    _bubbleTimer?.cancel();
    // Safety net in case completion event never arrives.
    _bubbleTimer = Timer(const Duration(seconds: 8), _endVoice);
    if (_settings.musicAudible) _musicPlayer.setVolume(_duckedVolume);
    try {
      await _voicePlayer.stop();
      await _voicePlayer.play(AssetSource(line.asset), volume: 1);
    } catch (e) {
      debugPrint('Voice failed: $e');
      _endVoice();
    }
  }

  void _endVoice() {
    _bubbleTimer?.cancel();
    speaking.value = null;
    _speakingPriority = 0;
    if (_settings.musicAudible) _musicPlayer.setVolume(_musicVolume);
  }

  void stopVoice() {
    _voicePlayer.stop();
    _endVoice();
  }

  void _onSettingsChanged() {
    if (_settings.musicAudible) {
      if (_musicStarted && _currentTrack == _trackIndex) {
        _musicPlayer.resume();
      } else {
        _musicStarted = false;
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
    if (!_settings.voicesAudible) stopVoice();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _musicPlayer.pause();
        _voicePlayer.stop();
      case AppLifecycleState.resumed:
        if (_settings.musicAudible && _musicStarted) _musicPlayer.resume();
      case AppLifecycleState.inactive:
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_onSettingsChanged);
    _voiceDone?.cancel();
    _bubbleTimer?.cancel();
    _musicPlayer.dispose();
    _voicePlayer.dispose();
    for (final p in _sfxPlayers) {
      p.dispose();
    }
  }
}
