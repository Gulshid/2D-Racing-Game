import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/race_records.dart';

/// Records the player's path during a lap so it can be replayed as a ghost.
class GhostRecorder {
  List<double> _samples = [];

  /// Start recording a new lap.
  void begin() => _samples = [];

  /// Call every frame with the time since the lap started.
  void sample(double lapTime, double x, double y, double heading) {
    final wanted = (lapTime * GameConfig.ghostRate).floor() + 1;
    while (_samples.length ~/ 3 < wanted) {
      _samples
        ..add(x)
        ..add(y)
        ..add(heading);
    }
  }

  /// Finishes the lap and returns the recording.
  GhostData finish(double lapTime) => GhostData(lapTime, List.of(_samples));
}
