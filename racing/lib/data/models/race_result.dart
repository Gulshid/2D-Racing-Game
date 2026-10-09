/// Everything the results screen needs after a race.
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
  });

  final String trackName;
  final int laps;
  final int position;
  final int carCount;
  final double totalTime;
  final double? bestLap;
  final List<double> lapTimes;
  final int coins;

  /// Coins earned: position bonus plus collected coins.
  final int reward;
  final bool newBestLap;
  final bool newBestTotal;

  static const List<int> positionRewards = [100, 60, 40, 25, 15, 10];
  static const int coinValue = 5;

  static int rewardFor(int position, int coins) {
    final index = position - 1;
    final base = (index >= 0 && index < positionRewards.length)
        ? positionRewards[index]
        : 5;
    return base + coins * coinValue;
  }
}
