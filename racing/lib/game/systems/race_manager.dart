import 'dart:math' as math;

import 'package:racing/core/constants/game_config.dart';
import 'package:racing/game/components/track/track_map.dart';

enum RaceState { idle, countdown, racing, finished, paused }

/// Race progress of one car.
///
/// Progress is a continuous number: 0.5 = halfway round lap one, 1.5 =
/// halfway round lap two. It only counts forward movement along the road,
/// so shortcuts, reversing over the line and teleports cannot add laps.
class RaceCarState {
  RaceCarState({required this.id, required this.name, this.isPlayer = false});

  final String id;
  final String name;
  final bool isPlayer;

  /// Current progress (can go down if the car reverses).
  double totalProgress = 0;

  /// Furthest progress ever reached; laps and checkpoints use this.
  double furthest = 0;

  int lapsCompleted = 0;

  /// Checkpoints passed since the start (negative before the start line).
  int checkpointsPassed = 0;

  /// Race time when the current lap started. Null before the start line.
  double? lapStart;
  double currentLapTime = 0;
  double? bestLap;
  final List<double> lapTimes = [];

  bool finished = false;
  double finishTime = 0;
  int finishOrder = 0;
  int position = 1;

  double wrongWayTimer = 0;
  bool wrongWay = false;
  int coins = 0;

  double _last = 0;
  bool _initialized = false;

  void reset() {
    totalProgress = 0;
    furthest = 0;
    lapsCompleted = 0;
    checkpointsPassed = 0;
    lapStart = null;
    currentLapTime = 0;
    bestLap = null;
    lapTimes.clear();
    finished = false;
    finishTime = 0;
    finishOrder = 0;
    position = 1;
    wrongWayTimer = 0;
    wrongWay = false;
    coins = 0;
    _last = 0;
    _initialized = false;
  }
}

/// Race rules: countdown, laps, checkpoints, positions, wrong-way, timing.
/// Pure Dart. The game feeds it car positions with [observe].
class RaceManager {
  RaceManager({
    required this.track,
    required this.totalLaps,
    required this.cars,
  }) : checkpointCount = math.max(
          4,
          (track.length / GameConfig.checkpointSpacing).round(),
        );

  final TrackMap track;
  final int totalLaps;
  final List<RaceCarState> cars;

  /// Checkpoints per lap. Checkpoint 0 is the start/finish line.
  final int checkpointCount;

  RaceState state = RaceState.idle;
  RaceState _stateBeforePause = RaceState.idle;

  double raceTime = 0;
  double _countdown = 0;
  double _goTimer = 0;
  int _finishedCount = 0;

  void Function(RaceCarState car)? onLapStart;
  void Function(RaceCarState car, double lapTime, int lap)? onLapComplete;
  void Function(RaceCarState car)? onFinish;

  /// Controls are locked during the countdown.
  bool get canDrive =>
      state == RaceState.racing || state == RaceState.finished;

  String get countdownLabel {
    if (state == RaceState.countdown) {
      return '${math.max(1, _countdown.ceil())}';
    }
    if (state == RaceState.racing && _goTimer > 0) return 'GO!';
    return '';
  }

  void reset() {
    for (final c in cars) {
      c.reset();
    }
    raceTime = 0;
    _countdown = 0;
    _goTimer = 0;
    _finishedCount = 0;
    state = RaceState.idle;
  }

  void startCountdown() {
    reset();
    state = RaceState.countdown;
    _countdown = GameConfig.countdownSeconds.toDouble();
  }

  void pause() {
    if (state == RaceState.racing || state == RaceState.countdown) {
      _stateBeforePause = state;
      state = RaceState.paused;
    }
  }

  void resume() {
    if (state == RaceState.paused) state = _stateBeforePause;
  }

  /// Advances the clocks. Call once per fixed step.
  void update(double dt) {
    if (_goTimer > 0) _goTimer -= dt;
    switch (state) {
      case RaceState.countdown:
        _countdown -= dt;
        if (_countdown <= 0) {
          state = RaceState.racing;
          raceTime = 0;
          _goTimer = GameConfig.goDisplaySeconds;
        }
      case RaceState.racing:
        raceTime += dt;
        for (final c in cars) {
          final start = c.lapStart;
          if (!c.finished && start != null) {
            c.currentLapTime = raceTime - start;
          }
        }
      case RaceState.idle:
      case RaceState.finished:
      case RaceState.paused:
        break;
    }
  }

  /// Tells the manager where a car is. [q] is the track query for the car.
  void observe(
    RaceCarState s,
    TrackQuery q,
    double vx,
    double vy,
    double dt,
  ) {
    if (state == RaceState.idle) return;
    final p = q.progress;

    if (!s._initialized) {
      s._initialized = true;
      s._last = p;
      s.totalProgress = p > 0.5 ? p - 1 : p;
      s.furthest = s.totalProgress;
      s.checkpointsPassed = (s.furthest * checkpointCount).floor();
      _updatePositions();
      return;
    }

    var d = p - s._last;
    if (d > 0.5) {
      d -= 1;
    } else if (d < -0.5) {
      d += 1;
    }
    s._last = p;

    if (d.abs() <= GameConfig.progressJumpLimit) {
      s.totalProgress += d;
      if (s.totalProgress > s.furthest) {
        final old = s.furthest;
        s.furthest = s.totalProgress;
        if (state == RaceState.racing && !s.finished) {
          _crossings(s, old, s.furthest);
        }
        s.checkpointsPassed = (s.furthest * checkpointCount).floor();
      }
    }

    final t = track.tangents[q.index];
    final along = vx * t.x + vy * t.y;
    if (state == RaceState.racing &&
        !s.finished &&
        along < -GameConfig.wrongWayMinSpeed) {
      s.wrongWayTimer += dt;
    } else {
      s.wrongWayTimer = math.max(0, s.wrongWayTimer - dt * 2);
    }
    s.wrongWay = s.wrongWayTimer > GameConfig.wrongWaySeconds;

    _updatePositions();
  }

  void _crossings(RaceCarState s, double from, double to) {
    final first = from.floor() + 1;
    final last = to.floor();
    for (var k = first; k <= last; k++) {
      if (k == 0) {
        s.lapStart = raceTime;
        s.currentLapTime = 0;
        onLapStart?.call(s);
      } else if (k >= 1) {
        final lapTime = raceTime - (s.lapStart ?? 0);
        s.lapsCompleted = k;
        s.lapTimes.add(lapTime);
        final best = s.bestLap;
        if (best == null || lapTime < best) s.bestLap = lapTime;
        s.currentLapTime = lapTime;
        onLapComplete?.call(s, lapTime, k);
        if (k >= totalLaps) {
          s.finished = true;
          s.finishTime = raceTime;
          _finishedCount++;
          s.finishOrder = _finishedCount;
          _updatePositions();
          if (s.isPlayer && state == RaceState.racing) {
            state = RaceState.finished;
          }
          onFinish?.call(s);
          return;
        }
        s.lapStart = raceTime;
        s.currentLapTime = 0;
        onLapStart?.call(s);
      }
    }
  }

  bool _ahead(RaceCarState a, RaceCarState b) {
    if (a.finished && !b.finished) return true;
    if (!a.finished && b.finished) return false;
    if (a.finished && b.finished) return a.finishOrder < b.finishOrder;
    return a.totalProgress > b.totalProgress;
  }

  void _updatePositions() {
    for (final car in cars) {
      var pos = 1;
      for (final other in cars) {
        if (!identical(other, car) && _ahead(other, car)) pos++;
      }
      car.position = pos;
    }
  }

  /// Progress (0..1) of the last checkpoint the car passed. Also makes the
  /// car's progress consistent for a respawn there.
  double respawnProgress(RaceCarState s) {
    final frac = ((s.furthest % 1.0) + 1.0) % 1.0;
    final cp = (frac * checkpointCount).floor();
    final progress = cp / checkpointCount;
    s.totalProgress = s.furthest.floor() + progress;
    s._last = progress;
    return progress;
  }

  /// Lap number to display (1-based, capped at the total).
  int displayLap(RaceCarState s) {
    final lap = s.lapsCompleted + 1;
    return lap > totalLaps ? totalLaps : lap;
  }
}
