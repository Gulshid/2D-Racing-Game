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

/// Best times for one track.
class RaceRecord {
  double? bestLap;
  double? bestTotal;
  GhostData? ghost;
}

/// In-memory records for this app session.
/// Phase 10 replaces the storage with a saved file.
abstract final class RaceRecords {
  static final Map<String, RaceRecord> _records = {};

  static RaceRecord of(String trackId) =>
      _records.putIfAbsent(trackId, RaceRecord.new);
}
