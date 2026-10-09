import 'package:racing/game/systems/race_manager.dart';

/// Values that change rarely: laps, position, countdown text, warnings.
class RaceHudState {
  const RaceHudState({
    this.label = '',
    this.lap = 1,
    this.totalLaps = 3,
    this.position = 1,
    this.carCount = 1,
    this.wrongWay = false,
    this.coins = 0,
    this.state = RaceState.idle,
  });

  final String label;
  final int lap;
  final int totalLaps;
  final int position;
  final int carCount;
  final bool wrongWay;
  final int coins;
  final RaceState state;

  @override
  bool operator ==(Object other) =>
      other is RaceHudState &&
      other.label == label &&
      other.lap == lap &&
      other.totalLaps == totalLaps &&
      other.position == position &&
      other.carCount == carCount &&
      other.wrongWay == wrongWay &&
      other.coins == coins &&
      other.state == state;

  @override
  int get hashCode => Object.hash(
        label,
        lap,
        totalLaps,
        position,
        carCount,
        wrongWay,
        coins,
        state,
      );
}

/// Timer values; these change every frame.
class RaceTiming {
  const RaceTiming({this.lapTime = 0, this.bestLap, this.totalTime = 0});

  final double lapTime;
  final double? bestLap;
  final double totalTime;

  @override
  bool operator ==(Object other) =>
      other is RaceTiming &&
      other.lapTime == lapTime &&
      other.bestLap == bestLap &&
      other.totalTime == totalTime;

  @override
  int get hashCode => Object.hash(lapTime, bestLap, totalTime);
}
