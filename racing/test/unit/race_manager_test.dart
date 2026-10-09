import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/tracks/track_library.dart';
import 'package:racing/game/components/track/track_map.dart';
import 'package:racing/game/systems/race_manager.dart';

void main() {
  final map = TrackMap(TrackLibrary.oval);

  RaceManager newRace({int laps = 3, List<RaceCarState>? cars}) => RaceManager(
        track: map,
        totalLaps: laps,
        cars: cars ?? [RaceCarState(id: 'p', name: 'P', isPlayer: true)],
      );

  /// Runs the countdown until the race starts.
  void startRace(RaceManager race) {
    race.startCountdown();
    for (var i = 0; i < 120 * 4; i++) {
      race.update(1 / 120);
    }
  }

  /// Puts a car at [progress] and tells the race about it.
  void place(RaceManager race, RaceCarState s, double progress,
      {double speed = 0}) {
    final f = map.frame(progress);
    final q = map.query(f.position);
    race.observe(s, q, f.tangent.x * speed, f.tangent.y * speed, 1 / 120);
  }

  /// Drives a car forward along the track from [from] to [to] progress.
  void drive(RaceManager race, RaceCarState s, double from, double to) {
    for (var p = from; p < to; p += 0.002) {
      place(race, s, p % 1.0, speed: 300);
      race.update(1 / 120);
    }
  }

  group('countdown', () {
    test('locks controls, then says GO and unlocks', () {
      final race = newRace();
      race.startCountdown();
      expect(race.canDrive, isFalse);
      expect(race.countdownLabel, '3');

      for (var i = 0; i < 130; i++) {
        race.update(1 / 120);
      }
      expect(race.countdownLabel, '2');

      for (var i = 0; i < 240 + 2; i++) {
        race.update(1 / 120);
      }
      expect(race.state, RaceState.racing);
      expect(race.canDrive, isTrue);
      expect(race.countdownLabel, 'GO!');
    });

    test('pause and resume keep the state', () {
      final race = newRace();
      race.startCountdown();
      race.pause();
      expect(race.state, RaceState.paused);
      race.resume();
      expect(race.state, RaceState.countdown);
    });
  });

  group('laps', () {
    test('a full 3-lap race finishes with 3 lap times', () {
      final s = RaceCarState(id: 'p', name: 'P', isPlayer: true);
      final race = newRace(cars: [s]);
      startRace(race);

      var finished = false;
      race.onFinish = (_) => finished = true;

      // The car starts just behind the line (progress 0.99 = -0.01), so
      // lap k is complete at progress k + 1.
      place(race, s, 0.99);
      drive(race, s, 0.99, 4.01);

      expect(finished, isTrue);
      expect(s.finished, isTrue);
      expect(s.lapsCompleted, 3);
      expect(s.lapTimes.length, 3);
      expect(s.lapTimes.every((t) => t > 0), isTrue);
      expect(s.bestLap, isNotNull);
      expect(race.state, RaceState.finished);
    });

    test('reversing over the line and going forward again adds no lap', () {
      final s = RaceCarState(id: 'p', name: 'P', isPlayer: true);
      final race = newRace(cars: [s]);
      startRace(race);
      place(race, s, 0.99);
      drive(race, s, 0.99, 2.05);
      expect(s.lapsCompleted, 1);

      // Back over the line, then forward again.
      for (var p = 2.05; p > 1.95; p -= 0.002) {
        place(race, s, p % 1.0);
        race.update(1 / 120);
      }
      drive(race, s, 1.95, 2.05);
      expect(s.lapsCompleted, 1);
    });

    test('a teleport across the track does not count as progress', () {
      final s = RaceCarState(id: 'p', name: 'P', isPlayer: true);
      final race = newRace(cars: [s]);
      startRace(race);
      place(race, s, 0.99);
      drive(race, s, 0.99, 2.1);
      final before = s.furthest;

      place(race, s, 0.6); // jump back
      place(race, s, 0.98); // jump forward past the line again
      expect(s.furthest, closeTo(before, 0.01));
      expect(s.lapsCompleted, 1);
    });

    test('lap timer starts at the start line, not at GO', () {
      final s = RaceCarState(id: 'p', name: 'P', isPlayer: true);
      final race = newRace(cars: [s]);
      startRace(race);
      place(race, s, 0.99);
      for (var i = 0; i < 120; i++) {
        race.update(1 / 120);
      }
      expect(s.lapStart, isNull);
      expect(s.currentLapTime, 0);

      drive(race, s, 0.99, 1.01);
      expect(s.lapStart, isNotNull);
    });
  });

  group('positions', () {
    test('the car further along the track is ahead', () {
      final a = RaceCarState(id: 'a', name: 'A', isPlayer: true);
      final b = RaceCarState(id: 'b', name: 'B');
      final c = RaceCarState(id: 'c', name: 'C');
      final race = newRace(cars: [a, b, c]);
      startRace(race);

      place(race, a, 0.99);
      place(race, b, 0.99);
      place(race, c, 0.99);
      for (final s in [a, b, c]) {
        drive(race, s, 0.99, 1.0);
      }
      drive(race, a, 1.0, 1.10);
      drive(race, b, 1.0, 1.30);
      drive(race, c, 1.0, 1.20);

      expect(b.position, 1);
      expect(c.position, 2);
      expect(a.position, 3);
    });

    test('finished cars rank by finish order', () {
      final a = RaceCarState(id: 'a', name: 'A', isPlayer: true);
      final b = RaceCarState(id: 'b', name: 'B');
      final race = newRace(laps: 1, cars: [a, b]);
      startRace(race);
      place(race, a, 0.99);
      place(race, b, 0.99);

      drive(race, b, 0.99, 2.01);
      expect(b.finished, isTrue);
      drive(race, a, 0.99, 2.01);
      expect(a.finished, isTrue);
      expect(b.position, 1);
      expect(a.position, 2);
    });
  });

  group('wrong way and respawn', () {
    test('driving backwards triggers the wrong-way warning', () {
      final s = RaceCarState(id: 'p', name: 'P', isPlayer: true);
      final race = newRace(cars: [s]);
      startRace(race);
      place(race, s, 0.5);
      for (var i = 0; i < 240; i++) {
        place(race, s, 0.5, speed: -200);
      }
      expect(s.wrongWay, isTrue);

      for (var i = 0; i < 480; i++) {
        place(race, s, 0.5, speed: 200);
      }
      expect(s.wrongWay, isFalse);
    });

    test('respawn goes to the last passed checkpoint', () {
      final s = RaceCarState(id: 'p', name: 'P', isPlayer: true);
      final race = newRace(cars: [s]);
      startRace(race);
      place(race, s, 0.99);
      drive(race, s, 0.99, 2.37);

      final progress = race.respawnProgress(s);
      final n = race.checkpointCount;
      expect(progress, lessThanOrEqualTo(0.37 + 1e-9));
      expect(progress, greaterThan(0.37 - 1.0 / n - 0.01));
      expect(progress * n, closeTo((progress * n).roundToDouble(), 1e-6));
    });
  });

  test('checkpoint count follows the track length', () {
    final race = newRace();
    expect(
      race.checkpointCount,
      (map.length / GameConfig.checkpointSpacing).round(),
    );
  });

  test('Vector2 import is used', () {
    expect(Vector2.zero().length, 0);
  });
}
