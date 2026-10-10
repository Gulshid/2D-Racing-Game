import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/features/providers/settings_provider.dart';

/// One-shot sound effects. [file] is relative to assets/audio/sfx/.
enum Sfx {
  countdownBeep('beep_count.wav'),
  goBeep('beep_go.wav'),
  uiClick('ui_click.wav'),
  pickup('pickup_chime.wav'),
  impactWall('impact_wall.wav'),
  impactCar('impact_car.wav'),
  nitro('nitro_whoosh.wav');

  const Sfx(this.file);
  final String file;
}

/// Background tracks. [file] is relative to assets/audio/music/.
enum Music {
  menu('menu_loop.wav'),
  race('race_loop.wav');

  const Music(this.file);
  final String file;
}

/// Volume and speed of one looping engine voice.
class EngineMix {
  const EngineMix(this.volume, this.rate);

  /// 0..1 before the sound-effects setting is applied.
  final double volume;

  /// Playback speed; higher sounds higher-pitched and busier.
  final double rate;
}

/// Plays all game sound.
///
/// Sounds are played through a fixed pool of players (no new players while
/// racing). Looping voices (engines, tyre squeal) keep running and only get
/// their volume and speed changed, which is cheap. Every platform call is
/// wrapped so a missing or broken sound file cannot crash the game.
class AudioService with WidgetsBindingObserver {
  AudioService() {
    WidgetsBinding.instance.addObserver(this);
  }

  static const _engineAsset = 'audio/sfx/engine_loop.wav';
  static const _screechAsset = 'audio/sfx/tire_screech_loop.wav';
  static const _poolSize = 8;
  static const _engineCount = 3; // player + two nearest AI cars

  final List<AudioPlayer> _shots = [
    for (var i = 0; i < _poolSize; i++) AudioPlayer(),
  ];
  int _nextShot = 0;

  final AudioPlayer _musicPlayer = AudioPlayer();
  Music? _music;
  double _musicNow = 0;
  Timer? _fade;

  final List<AudioPlayer> _engines = [
    for (var i = 0; i < _engineCount; i++) AudioPlayer(),
  ];
  final List<double> _engineVol = List.filled(_engineCount, -1);
  final List<double> _engineRate = List.filled(_engineCount, -1);

  final AudioPlayer _screech = AudioPlayer();
  double _screechVol = -1;

  final math.Random _rnd = math.Random();

  double _musicVolume = 0.7;
  double _sfxVolume = 0.9;
  bool _raceAudio = false;
  bool _gamePaused = false;
  bool _suspended = false;
  bool _disposed = false;

  // ---- Settings ------------------------------------------------------------

  void applySettings(double musicVolume, double sfxVolume) {
    _musicVolume = musicVolume;
    _sfxVolume = sfxVolume;
    if (_music != null) _rampMusic(_musicTarget, ms: 150);
  }

  /// Music is turned down while the game is paused.
  double get _musicTarget => _gamePaused ? _musicVolume * 0.35 : _musicVolume;

  // ---- Music ---------------------------------------------------------------

  /// Starts [m] with a short fade-in. Asking for the track already playing
  /// does nothing, so screens can request their music freely.
  void playMusic(Music m) {
    if (_music == m) return;
    _music = m;
    unawaited(_guard(() async {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setPlaybackRate(1);
      await _musicPlayer.setVolume(0);
      _musicNow = 0;
      await _musicPlayer.play(AssetSource('audio/music/${m.file}'));
      _rampMusic(_musicTarget, ms: 800);
    }));
  }

  /// Speeds up or slows down the current track (used for the final lap).
  void setMusicRate(double rate) {
    unawaited(_guard(() => _musicPlayer.setPlaybackRate(clampD(rate, 0.5, 2))));
  }

  void _rampMusic(double target, {required int ms}) {
    _fade?.cancel();
    final from = _musicNow;
    const steps = 12;
    var i = 0;
    _fade = Timer.periodic(
      Duration(milliseconds: math.max(1, ms ~/ steps)),
      (timer) {
        i++;
        final v = clampD(from + (target - from) * i / steps, 0, 1);
        _musicNow = v;
        unawaited(_guard(() => _musicPlayer.setVolume(v)));
        if (i >= steps) timer.cancel();
      },
    );
  }

  // ---- One-shot sounds -----------------------------------------------------

  /// Plays [sfx] once. [volume] and [rate] are relative (1 = normal).
  void playSfx(Sfx sfx, {double volume = 1, double rate = 1}) {
    final v = clampD(volume * _sfxVolume, 0, 1);
    if (_disposed || _suspended || v <= 0.001) return;
    final player = _shots[_nextShot];
    _nextShot = (_nextShot + 1) % _poolSize;
    unawaited(_guard(() async {
      await player.setVolume(v);
      await player.setPlaybackRate(clampD(rate, 0.5, 2));
      await player.play(AssetSource('audio/sfx/${sfx.file}'));
    }));
  }

  /// A small random pitch change, so repeated sounds do not sound identical.
  double jitter([double amount = 0.06]) =>
      1 + (_rnd.nextDouble() * 2 - 1) * amount;

  // ---- Race loops (engines and tyre squeal) --------------------------------

  /// Starts the engine and tyre loops silently. Call when a race begins;
  /// [updateEngines] then sets their volume and speed every frame.
  void startRaceAudio() {
    if (_disposed) return;
    _raceAudio = true;
    unawaited(_guard(() async {
      for (var i = 0; i < _engines.length; i++) {
        _engineVol[i] = -1;
        _engineRate[i] = -1;
        await _engines[i].setReleaseMode(ReleaseMode.loop);
        await _engines[i].setVolume(0);
        await _engines[i].play(AssetSource(_engineAsset));
      }
      _screechVol = -1;
      await _screech.setReleaseMode(ReleaseMode.loop);
      await _screech.setVolume(0);
      await _screech.play(AssetSource(_screechAsset));
    }));
  }

  /// Sets the engines. [player] is the player's car, [others] up to two
  /// nearby AI cars (already attenuated by distance by the caller).
  void updateEngines(EngineMix player, List<EngineMix> others) {
    if (!_raceAudio || _disposed) return;
    final mixes = [player, ...others];
    for (var i = 0; i < _engines.length; i++) {
      final m = i < mixes.length ? mixes[i] : const EngineMix(0, 1);
      final vol = (_gamePaused || _suspended)
          ? 0.0
          : clampD(m.volume * _sfxVolume, 0, 1);
      final rate = clampD(m.rate, 0.6, 1.8);
      if ((vol - _engineVol[i]).abs() < 0.02 &&
          (rate - _engineRate[i]).abs() < 0.02) {
        continue;
      }
      _engineVol[i] = vol;
      _engineRate[i] = rate;
      final p = _engines[i];
      unawaited(_guard(() async {
        await p.setVolume(vol);
        await p.setPlaybackRate(rate);
      }));
    }
  }

  /// Tyre squeal volume, 0..1 (0 = silent).
  void updateScreech(double volume) {
    if (!_raceAudio || _disposed) return;
    final vol = (_gamePaused || _suspended)
        ? 0.0
        : clampD(volume * _sfxVolume, 0, 1);
    if ((vol - _screechVol).abs() < 0.03) return;
    _screechVol = vol;
    unawaited(_guard(() => _screech.setVolume(vol)));
  }

  /// Stops the engine and tyre loops (race ended or left).
  void stopRaceAudio() {
    if (!_raceAudio) return;
    _raceAudio = false;
    for (final p in [..._engines, _screech]) {
      unawaited(_guard(() => p.stop()));
    }
  }

  // ---- Pause ---------------------------------------------------------------

  /// Called when the race is paused or resumed. Pausing silences the engines
  /// at once and turns the music down.
  void setGamePaused(bool paused) {
    if (_gamePaused == paused) return;
    _gamePaused = paused;
    if (paused) _silenceLoops();
    _rampMusic(_musicTarget, ms: 300);
  }

  void _silenceLoops() {
    for (var i = 0; i < _engines.length; i++) {
      _engineVol[i] = 0;
      final p = _engines[i];
      unawaited(_guard(() => p.setVolume(0)));
    }
    _screechVol = 0;
    unawaited(_guard(() => _screech.setVolume(0)));
  }

  // ---- App lifecycle -------------------------------------------------------

  /// Pauses all sound when the app goes to the background, and resumes the
  /// music when it comes back. The race itself is paused by the race screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_suspended) return;
      _suspended = false;
      unawaited(_guard(() async {
        if (_music != null) await _musicPlayer.resume();
      }));
      if (_raceAudio) {
        for (final p in [..._engines, _screech]) {
          unawaited(_guard(() => p.resume()));
        }
      }
    } else {
      if (_suspended) return;
      _suspended = true;
      _silenceLoops();
      for (final p in [_musicPlayer, ..._engines, _screech]) {
        unawaited(_guard(() => p.pause()));
      }
    }
  }

  // ---- Plumbing ------------------------------------------------------------

  Future<void> _guard(Future<void> Function() action) async {
    if (_disposed) return;
    try {
      await action();
    } catch (e) {
      debugPrint('AudioService: $e');
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _fade?.cancel();
    for (final p in [..._shots, _musicPlayer, ..._engines, _screech]) {
      unawaited(p.dispose());
    }
  }
}

/// App-wide audio. Volumes follow the settings screen automatically.
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  final settings = ref.read(settingsProvider);
  service.applySettings(settings.musicVolume, settings.sfxVolume);
  ref.listen(settingsProvider, (_, next) {
    service.applySettings(next.musicVolume, next.sfxVolume);
  });
  ref.onDispose(service.dispose);
  return service;
});
