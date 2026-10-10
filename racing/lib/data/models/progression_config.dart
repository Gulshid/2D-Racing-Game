import 'dart:math' as math;

import 'package:racing/data/models/car_stats.dart';

/// Every number that controls money and unlocks. Balance the game here.
abstract final class Economy {
  static const int startingCoins = 500;

  // Upgrades: cost of the next level = base * (current level + 1).
  // A first upgrade (300) takes about two good races to afford.
  static const int maxUpgradeLevel = 5;
  static const int upgradeBaseCost = 300;

  // Unlock costs, by CarPresets index and by track id.
  static const List<int> carCost = [0, 600, 1000, 800];
  static const Map<String, int> trackCost = {
    'city_oval': 0,
    'forest_circuit': 800,
    'desert_run': 1500,
  };

  // Race rewards.
  static const List<int> positionBonus = [260, 200, 160, 120, 90, 70, 50];
  static const int lastPlaceBonus = 30;
  static const int coinValue = 6;
  static const int cleanLapBonus = 40;
  static const int driftBonusEach = 2;
  static const int driftBonusCap = 60;

  // Championship: three rounds, points for the top ten.
  static const List<String> seasonCalendar = [
    'city_oval',
    'forest_circuit',
    'desert_run',
  ];
  static const List<int> seasonPoints = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
  static const List<int> seasonBonus = [800, 500, 300];

  // Daily login reward: grows each day of a streak, up to the cap.
  static const int dailyLoginBase = 100;
  static const int dailyLoginStep = 50;
  static const int dailyStreakCap = 7;
  static const int dailyChallengeReward = 250;

  static int upgradeCost(int currentLevel) =>
      upgradeBaseCost * (currentLevel + 1);

  static int carCostFor(int index) =>
      (index >= 0 && index < carCost.length) ? carCost[index] : 0;

  static int trackCostFor(String id) => trackCost[id] ?? 0;
}

/// The four upgradable parts.
enum UpgradeType { engine, tires, brakes, nitro }

/// Turns upgrade levels into car stats. Each level is a small, visible step
/// (at level 5 the engine gives +20% top speed).
abstract final class CarUpgrades {
  static String key(int carIndex, UpgradeType t) => '$carIndex:${t.name}';

  static CarStats apply(CarStats base, int Function(UpgradeType) levelOf) {
    final engine = levelOf(UpgradeType.engine);
    final tires = levelOf(UpgradeType.tires);
    final brakes = levelOf(UpgradeType.brakes);
    final nitro = levelOf(UpgradeType.nitro);
    return base.copyWith(
      maxSpeed: base.maxSpeed * (1 + 0.04 * engine),
      acceleration: base.acceleration * (1 + 0.06 * engine),
      grip: base.grip * (1 + 0.07 * tires),
      steering: base.steering * (1 + 0.03 * tires),
      braking: base.braking * (1 + 0.08 * brakes),
      nitroCapacity: base.nitroCapacity * (1 + 0.10 * nitro),
      nitroPower: base.nitroPower * (1 + 0.05 * nitro),
    );
  }
}

/// Money from one race, split into parts so the results screen can show them.
class RaceReward {
  const RaceReward({
    required this.position,
    required this.coins,
    required this.cleanLaps,
    required this.drifts,
  });

  factory RaceReward.of({
    required int position,
    required int coins,
    required int cleanLaps,
    required int drifts,
  }) =>
      RaceReward(
        position: position,
        coins: coins,
        cleanLaps: cleanLaps,
        drifts: drifts,
      );

  final int position;
  final int coins;
  final int cleanLaps;
  final int drifts;

  int get positionBonus {
    final i = position - 1;
    return (i >= 0 && i < Economy.positionBonus.length)
        ? Economy.positionBonus[i]
        : Economy.lastPlaceBonus;
  }

  int get coinBonus => coins * Economy.coinValue;
  int get cleanLapBonus => cleanLaps * Economy.cleanLapBonus;
  int get driftBonus =>
      math.min(Economy.driftBonusCap, drifts * Economy.driftBonusEach);

  int get total => positionBonus + coinBonus + cleanLapBonus + driftBonus;
}

/// Calendar day as "2026-10-10" in local time.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Whole days since 2024-01-01, used to pick the daily challenge.
int dayNumber(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(2024))
        .inDays;

/// The daily challenge. One kind per day, rotating.
enum DailyKind {
  drifts(20),
  cleanLaps(3),
  finishes(2);

  const DailyKind(this.target);

  final int target;

  static DailyKind today(DateTime now) {
    final i = ((dayNumber(now) % 3) + 3) % 3;
    return DailyKind.values[i];
  }
}

/// Achievements. Titles and descriptions live in the localization file.
class AchievementDef {
  const AchievementDef(this.id, this.reward);

  final String id;
  final int reward;
}

abstract final class Achievements {
  static const firstWin = AchievementDef('first_win', 150);
  static const podium = AchievementDef('podium', 200);
  static const drifter = AchievementDef('drifter', 300);
  static const perfectLap = AchievementDef('perfect_lap', 250);
  static const racer10 = AchievementDef('racer_10', 400);
  static const champion = AchievementDef('champion', 800);

  static const List<AchievementDef> all = [
    firstWin,
    podium,
    drifter,
    perfectLap,
    racer10,
    champion,
  ];
}
