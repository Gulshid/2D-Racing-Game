import 'package:racing/data/models/progression_config.dart';

/// Championship state. Points are keyed by 'player' or the AI driver's name.
class ChampionshipSave {
  const ChampionshipSave({this.round = 0, this.points = const {}});

  factory ChampionshipSave.fromJson(Map<String, dynamic> j) => ChampionshipSave(
        round: _int(j['round'], 0),
        points: {
          for (final e in _map(j['points']).entries)
            e.key: _int(e.value, 0),
        },
      );

  final int round;
  final Map<String, int> points;

  bool get finished => round >= Economy.seasonCalendar.length;

  ChampionshipSave copyWith({int? round, Map<String, int>? points}) =>
      ChampionshipSave(
        round: round ?? this.round,
        points: points ?? this.points,
      );

  Map<String, dynamic> toJson() => {'round': round, 'points': points};
}

/// Today's login streak and challenge progress.
class DailySave {
  const DailySave({
    this.lastLoginDay = '',
    this.streak = 0,
    this.challengeDay = '',
    this.challengeProgress = 0,
    this.challengeClaimed = false,
  });

  factory DailySave.fromJson(Map<String, dynamic> j) => DailySave(
        lastLoginDay: _str(j['lastLoginDay']),
        streak: _int(j['streak'], 0),
        challengeDay: _str(j['challengeDay']),
        challengeProgress: _int(j['challengeProgress'], 0),
        challengeClaimed: j['challengeClaimed'] == true,
      );

  final String lastLoginDay;
  final int streak;
  final String challengeDay;
  final int challengeProgress;
  final bool challengeClaimed;

  DailySave copyWith({
    String? lastLoginDay,
    int? streak,
    String? challengeDay,
    int? challengeProgress,
    bool? challengeClaimed,
  }) =>
      DailySave(
        lastLoginDay: lastLoginDay ?? this.lastLoginDay,
        streak: streak ?? this.streak,
        challengeDay: challengeDay ?? this.challengeDay,
        challengeProgress: challengeProgress ?? this.challengeProgress,
        challengeClaimed: challengeClaimed ?? this.challengeClaimed,
      );

  Map<String, dynamic> toJson() => {
        'lastLoginDay': lastLoginDay,
        'streak': streak,
        'challengeDay': challengeDay,
        'challengeProgress': challengeProgress,
        'challengeClaimed': challengeClaimed,
      };
}

/// Lifetime totals shown on the rewards screen.
class StatsSave {
  const StatsSave({
    this.racesPlayed = 0,
    this.wins = 0,
    this.podiums = 0,
    this.drifts = 0,
    this.cleanLaps = 0,
    this.coinsEarned = 0,
  });

  factory StatsSave.fromJson(Map<String, dynamic> j) => StatsSave(
        racesPlayed: _int(j['racesPlayed'], 0),
        wins: _int(j['wins'], 0),
        podiums: _int(j['podiums'], 0),
        drifts: _int(j['drifts'], 0),
        cleanLaps: _int(j['cleanLaps'], 0),
        coinsEarned: _int(j['coinsEarned'], 0),
      );

  final int racesPlayed;
  final int wins;
  final int podiums;
  final int drifts;
  final int cleanLaps;
  final int coinsEarned;

  StatsSave copyWith({
    int? racesPlayed,
    int? wins,
    int? podiums,
    int? drifts,
    int? cleanLaps,
    int? coinsEarned,
  }) =>
      StatsSave(
        racesPlayed: racesPlayed ?? this.racesPlayed,
        wins: wins ?? this.wins,
        podiums: podiums ?? this.podiums,
        drifts: drifts ?? this.drifts,
        cleanLaps: cleanLaps ?? this.cleanLaps,
        coinsEarned: coinsEarned ?? this.coinsEarned,
      );

  Map<String, dynamic> toJson() => {
        'racesPlayed': racesPlayed,
        'wins': wins,
        'podiums': podiums,
        'drifts': drifts,
        'cleanLaps': cleanLaps,
        'coinsEarned': coinsEarned,
      };
}

/// Everything that is kept between app launches.
///
/// Settings are stored separately (SettingsRepository) so that a broken
/// progress save never resets the user's preferences.
class SaveData {
  /// Bump this when the format changes, and add a step to
  /// SaveRepository._migrations.
  static const int currentVersion = 1;

  SaveData({
    this.version = currentVersion,
    this.coins = Economy.startingCoins,
    Set<int>? unlockedCars,
    Set<String>? unlockedTracks,
    this.upgradeLevels = const {},
    this.bestLaps = const {},
    this.bestTotals = const {},
    this.stats = const StatsSave(),
    Set<String>? achievements,
    this.championship = const ChampionshipSave(),
    this.daily = const DailySave(),
  })  : unlockedCars = unlockedCars ?? {0},
        unlockedTracks = unlockedTracks ?? {Economy.seasonCalendar.first},
        achievements = achievements ?? {};

  factory SaveData.fromJson(Map<String, dynamic> j) => SaveData(
        version: _int(j['version'], currentVersion),
        coins: _int(j['coins'], Economy.startingCoins),
        unlockedCars: {
          for (final v in _list(j['unlockedCars'])) _int(v, -1),
        }..remove(-1),
        unlockedTracks: {
          for (final v in _list(j['unlockedTracks'])) v.toString(),
        },
        upgradeLevels: {
          for (final e in _map(j['upgradeLevels']).entries)
            e.key: _int(e.value, 0),
        },
        bestLaps: {
          for (final e in _map(j['bestLaps']).entries)
            if (e.value is num) e.key: (e.value as num).toDouble(),
        },
        bestTotals: {
          for (final e in _map(j['bestTotals']).entries)
            if (e.value is num) e.key: (e.value as num).toDouble(),
        },
        stats: StatsSave.fromJson(_map(j['stats'])),
        achievements: {for (final v in _list(j['achievements'])) v.toString()},
        championship: ChampionshipSave.fromJson(_map(j['championship'])),
        daily: DailySave.fromJson(_map(j['daily'])),
      );

  static SaveData initial() => SaveData();

  final int version;
  final int coins;
  final Set<int> unlockedCars;
  final Set<String> unlockedTracks;

  /// Key: "carIndex:upgradeName", value: level 0..5.
  final Map<String, int> upgradeLevels;

  /// Best lap and best total per track id, in seconds.
  final Map<String, double> bestLaps;
  final Map<String, double> bestTotals;
  final StatsSave stats;
  final Set<String> achievements;
  final ChampionshipSave championship;
  final DailySave daily;

  SaveData copyWith({
    int? coins,
    Set<int>? unlockedCars,
    Set<String>? unlockedTracks,
    Map<String, int>? upgradeLevels,
    Map<String, double>? bestLaps,
    Map<String, double>? bestTotals,
    StatsSave? stats,
    Set<String>? achievements,
    ChampionshipSave? championship,
    DailySave? daily,
  }) =>
      SaveData(
        version: version,
        coins: coins ?? this.coins,
        unlockedCars: unlockedCars ?? this.unlockedCars,
        unlockedTracks: unlockedTracks ?? this.unlockedTracks,
        upgradeLevels: upgradeLevels ?? this.upgradeLevels,
        bestLaps: bestLaps ?? this.bestLaps,
        bestTotals: bestTotals ?? this.bestTotals,
        stats: stats ?? this.stats,
        achievements: achievements ?? this.achievements,
        championship: championship ?? this.championship,
        daily: daily ?? this.daily,
      );

  Map<String, dynamic> toJson() => {
        'version': currentVersion,
        'coins': coins,
        'unlockedCars': unlockedCars.toList(),
        'unlockedTracks': unlockedTracks.toList(),
        'upgradeLevels': upgradeLevels,
        'bestLaps': bestLaps,
        'bestTotals': bestTotals,
        'stats': stats.toJson(),
        'achievements': achievements.toList(),
        'championship': championship.toJson(),
        'daily': daily.toJson(),
      };
}

// ---- Defensive JSON helpers: a wrong type falls back to a default. ----------

int _int(Object? v, int fallback) => v is num ? v.toInt() : fallback;

String _str(Object? v) => v is String ? v : '';

List<Object?> _list(Object? v) => v is List ? v.cast<Object?>() : const [];

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
