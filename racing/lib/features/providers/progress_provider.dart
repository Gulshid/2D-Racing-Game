import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/data/models/progression_config.dart';
import 'package:racing/data/models/race_records.dart';
import 'package:racing/data/models/race_result.dart';
import 'package:racing/data/models/save_data.dart';
import 'package:racing/data/repositories/save_repository.dart';
import 'package:racing/features/providers/settings_provider.dart';

/// What a finished race added to the player's progress. Shown on the
/// results screen.
class RaceSummary {
  const RaceSummary({
    required this.result,
    required this.reward,
    required this.achievements,
    required this.isChampionship,
    this.championshipPoints = 0,
    this.seasonBonus = 0,
    this.seasonChampion = false,
    this.dailyChallengeDone = false,
  });

  final RaceResult result;
  final RaceReward reward;
  final List<AchievementDef> achievements;
  final bool isChampionship;
  final int championshipPoints;
  final int seasonBonus;
  final bool seasonChampion;
  final bool dailyChallengeDone;

  int get achievementCoins =>
      achievements.fold(0, (sum, a) => sum + a.reward);
}

class ProgressState {
  const ProgressState({required this.save, this.summary});

  final SaveData save;

  /// Summary of the most recent race (null before the first race).
  final RaceSummary? summary;
}

final progressProvider = NotifierProvider<ProgressNotifier, ProgressState>(
  ProgressNotifier.new,
);

/// Owns all progression: coins, upgrades, unlocks, records, championship,
/// achievements and daily rewards. Every change is saved straight away.
class ProgressNotifier extends Notifier<ProgressState> {
  @override
  ProgressState build() {
    final save = SaveRepository(ref.watch(sharedPrefsProvider)).load();
    final trackIds = {...save.bestLaps.keys, ...save.bestTotals.keys};
    for (final id in trackIds) {
      RaceRecords.restore(
        id,
        bestLap: save.bestLaps[id],
        bestTotal: save.bestTotals[id],
      );
    }
    return ProgressState(save: save);
  }

  SaveData get _save => state.save;

  void _write(SaveData s, {RaceSummary? summary}) {
    state = ProgressState(save: s, summary: summary ?? state.summary);
    unawaited(SaveRepository(ref.read(sharedPrefsProvider)).save(s));
  }

  // ---- Queries -------------------------------------------------------------

  int get coins => _save.coins;

  bool isCarUnlocked(int car) => _save.unlockedCars.contains(car);

  bool isTrackUnlocked(String id) => _save.unlockedTracks.contains(id);

  bool get seasonUnlocked =>
      Economy.seasonCalendar.every(isTrackUnlocked);

  int upgradeLevel(int car, UpgradeType t) =>
      _save.upgradeLevels[CarUpgrades.key(car, t)] ?? 0;

  /// Car stats with all upgrades applied. This is what the race uses.
  CarStats statsFor(int car) => CarUpgrades.apply(
        CarPresets.byIndex(car),
        (t) => upgradeLevel(car, t),
      );

  // ---- Spending ------------------------------------------------------------

  bool unlockCar(int car) {
    if (isCarUnlocked(car)) return false;
    final cost = Economy.carCostFor(car);
    if (_save.coins < cost) return false;
    _write(_save.copyWith(
      coins: _save.coins - cost,
      unlockedCars: {..._save.unlockedCars, car},
    ));
    return true;
  }

  bool unlockTrack(String id) {
    if (isTrackUnlocked(id)) return false;
    final cost = Economy.trackCostFor(id);
    if (_save.coins < cost) return false;
    _write(_save.copyWith(
      coins: _save.coins - cost,
      unlockedTracks: {..._save.unlockedTracks, id},
    ));
    return true;
  }

  bool buyUpgrade(int car, UpgradeType t) {
    if (!isCarUnlocked(car)) return false;
    final level = upgradeLevel(car, t);
    if (level >= Economy.maxUpgradeLevel) return false;
    final cost = Economy.upgradeCost(level);
    if (_save.coins < cost) return false;
    final levels = Map<String, int>.of(_save.upgradeLevels)
      ..[CarUpgrades.key(car, t)] = level + 1;
    _write(_save.copyWith(
      coins: _save.coins - cost,
      upgradeLevels: levels,
    ));
    return true;
  }

  // ---- Daily rewards -------------------------------------------------------

  /// True when today's login reward has not been taken yet.
  bool canClaimLogin(DateTime now) => _save.daily.lastLoginDay != dayKey(now);

  /// Takes today's login reward. Returns the coins given (0 if taken).
  int claimLoginReward(DateTime now) {
    final today = dayKey(now);
    final d = _save.daily;
    if (d.lastLoginDay == today) return 0;
    final yesterday = dayKey(now.subtract(const Duration(days: 1)));
    final streak = d.lastLoginDay == yesterday ? d.streak + 1 : 1;
    final reward = Economy.dailyLoginBase +
        Economy.dailyLoginStep *
            (math.min(streak, Economy.dailyStreakCap) - 1);
    _write(_save.copyWith(
      coins: _save.coins + reward,
      daily: d.copyWith(lastLoginDay: today, streak: streak),
    ));
    return reward;
  }

  /// Today's challenge progress (resets at midnight).
  int challengeProgress(DateTime now) {
    final d = _save.daily;
    return d.challengeDay == dayKey(now) ? d.challengeProgress : 0;
  }

  bool isChallengeClaimed(DateTime now) {
    final d = _save.daily;
    return d.challengeDay == dayKey(now) && d.challengeClaimed;
  }

  /// Pays out a completed daily challenge once. Returns the coins given.
  int claimChallenge(DateTime now) {
    final kind = DailyKind.today(now);
    if (isChallengeClaimed(now)) return 0;
    if (challengeProgress(now) < kind.target) return 0;
    _write(_save.copyWith(
      coins: _save.coins + Economy.dailyChallengeReward,
      daily: _save.daily.copyWith(challengeClaimed: true),
    ));
    return Economy.dailyChallengeReward;
  }

  // ---- Championship --------------------------------------------------------

  /// Starts a new season: points and round reset. Unlocks, upgrades and
  /// coins are kept.
  void startNewSeason() {
    _write(_save.copyWith(championship: const ChampionshipSave()));
  }

  // ---- Race results --------------------------------------------------------

  /// Adds one finished race to the player's progress. Called once per race
  /// by the race screen when the result appears.
  void recordRace(
    RaceResult r, {
    required bool championship,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = dayKey(clock);
    final s = _save;
    final reward = RaceReward.of(
      position: r.position,
      coins: r.coins,
      cleanLaps: r.cleanLaps,
      drifts: r.drifts,
    );

    // Stats.
    final stats = s.stats.copyWith(
      racesPlayed: s.stats.racesPlayed + 1,
      wins: s.stats.wins + (r.position == 1 ? 1 : 0),
      podiums: s.stats.podiums + (r.position <= 3 ? 1 : 0),
      drifts: s.stats.drifts + r.drifts,
      cleanLaps: s.stats.cleanLaps + r.cleanLaps,
    );

    var coins = s.coins + reward.total;

    // Best times.
    final bestLaps = Map<String, double>.of(s.bestLaps);
    final bestTotals = Map<String, double>.of(s.bestTotals);
    if (r.newBestLap && r.bestLap != null) {
      bestLaps[r.trackId] = r.bestLap!;
    }
    if (r.newBestTotal) bestTotals[r.trackId] = r.totalTime;

    // Daily challenge progress (resets when the day changes).
    final kind = DailyKind.today(clock);
    final sameDay = s.daily.challengeDay == today;
    final before = sameDay ? s.daily.challengeProgress : 0;
    final added = switch (kind) {
      DailyKind.drifts => r.drifts,
      DailyKind.cleanLaps => r.cleanLaps,
      DailyKind.finishes => 1,
    };
    final progress = before + added;
    final dailyDone = before < kind.target && progress >= kind.target;
    final daily = s.daily.copyWith(
      challengeDay: today,
      challengeProgress: progress,
      challengeClaimed: sameDay && s.daily.challengeClaimed,
    );

    // Achievements.
    final achievements = Set<String>.of(s.achievements);
    final earned = <AchievementDef>[];
    void grant(AchievementDef a, bool condition) {
      if (!condition || achievements.contains(a.id)) return;
      achievements.add(a.id);
      earned.add(a);
      coins += a.reward;
    }

    grant(Achievements.firstWin, stats.wins >= 1);
    grant(Achievements.podium, stats.podiums >= 1);
    grant(Achievements.drifter, r.drifts >= 10);
    grant(Achievements.perfectLap, r.cleanLaps >= 1);
    grant(Achievements.racer10, stats.racesPlayed >= 10);

    // Championship: add points, then pay the season bonus at the end.
    var champ = s.championship;
    var champPoints = 0;
    var seasonBonus = 0;
    var seasonChampion = false;
    if (championship && !champ.finished && seasonUnlocked) {
      final pts = Map<String, int>.of(champ.points);
      for (final e in r.standings) {
        final key = e.isPlayer ? 'player' : e.name;
        if (e.position >= 1 && e.position <= Economy.seasonPoints.length) {
          final p = Economy.seasonPoints[e.position - 1];
          pts[key] = (pts[key] ?? 0) + p;
          if (e.isPlayer) champPoints = p;
        }
      }
      champ = champ.copyWith(round: champ.round + 1, points: pts);
      if (champ.finished) {
        final ranking = pts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final rank = ranking.indexWhere((e) => e.key == 'player');
        if (rank >= 0 && rank < Economy.seasonBonus.length) {
          seasonBonus = Economy.seasonBonus[rank];
          coins += seasonBonus;
        }
        seasonChampion = rank == 0;
        grant(Achievements.champion, seasonChampion);
      }
    }

    final newSave = s.copyWith(
      coins: coins,
      bestLaps: bestLaps,
      bestTotals: bestTotals,
      stats: stats.copyWith(coinsEarned: s.stats.coinsEarned + (coins - s.coins)),
      achievements: achievements,
      championship: champ,
      daily: daily,
    );

    _write(
      newSave,
      summary: RaceSummary(
        result: r,
        reward: reward,
        achievements: earned,
        isChampionship: championship,
        championshipPoints: champPoints,
        seasonBonus: seasonBonus,
        seasonChampion: seasonChampion,
        dailyChallengeDone: dailyDone,
      ),
    );
  }
}
