import 'package:racing/core/constants/game_config.dart';

/// Recorded best lap: x, y, heading triples, [GameConfig.ghostRate] per second.
class GhostData {
  const GhostData(this.lapTime, this.samples);

  final double lapTime;
  final List<double> samples;

  int get sampleCount => samples.length ~/ 3;
  double get duration => lapTime;
  double get rate => GameConfig.ghostRate.toDouble();
}

/// Best times for one track. Times are saved (see ProgressNotifier); the
/// ghost is kept for this session only.
class RaceRecord {
  double? bestLap;
  double? bestTotal;
  GhostData? ghost;
}

/// Best times for every track, in memory. ProgressNotifier loads the saved
/// values into here on start and writes them back after each race.
abstract final class RaceRecords {
  static final Map<String, RaceRecord> _records = {};

  static RaceRecord of(String trackId) =>
      _records.putIfAbsent(trackId, RaceRecord.new);

  /// Loads saved best times for a track (used at app start).
  static void restore(
    String trackId, {
    double? bestLap,
    double? bestTotal,
  }) {
    final r = of(trackId);
    r.bestLap = bestLap ?? r.bestLap;
    r.bestTotal = bestTotal ?? r.bestTotal;
  }
}
