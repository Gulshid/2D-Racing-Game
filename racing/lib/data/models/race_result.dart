import 'package:racing/data/models/progression_config.dart';

/// One line of the final standings.
class StandingEntry {
  const StandingEntry({
    required this.name,
    required this.isPlayer,
    required this.position,
    required this.time,
  });

  final String name;
  final bool isPlayer;
  final int position;

  /// Finish time in seconds, or null if the car was still racing.
  final double? time;
}

/// Everything the results screen and the progression system need after a race.
class RaceResult {
  const RaceResult({
    required this.trackName,
    required this.laps,
    required this.position,
    required this.carCount,
    required this.totalTime,
    required this.bestLap,
    required this.lapTimes,
    required this.coins,
    required this.reward,
    required this.newBestLap,
    required this.newBestTotal,
    this.standings = const [],
    this.trackId = '',
    this.drifts = 0,
    this.cleanLaps = 0,
  });

  final String trackName;
  final String trackId;
  final int laps;
  final int position;
  final int carCount;
  final double totalTime;
  final double? bestLap;
  final List<double> lapTimes;
  final int coins;

  /// Total coins for the race (see [RaceReward]).
  final int reward;
  final bool newBestLap;
  final bool newBestTotal;

  /// Drift starts during the race.
  final int drifts;

  /// Laps finished without hitting a wall or another car.
  final int cleanLaps;

  /// All cars in finishing order (player included).
  final List<StandingEntry> standings;

  /// Kept so older callers still compile; the economy now lives in
  /// [RaceReward].
  static int rewardFor(int position, int coins) => RaceReward.of(
        position: position,
        coins: coins,
        cleanLaps: 0,
        drifts: 0,
      ).total;
}
