// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Racing Game';

  @override
  String get play => 'Play';

  @override
  String get cars => 'Cars';

  @override
  String get settings => 'Settings';

  @override
  String get next => 'Next';

  @override
  String get startRace => 'Start race';

  @override
  String get chooseTrack => 'Choose a track';

  @override
  String get chooseCar => 'Choose your car';

  @override
  String laps(int count) {
    return '$count laps';
  }

  @override
  String parTime(int seconds) {
    return 'Par ${seconds}s';
  }

  @override
  String roadLength(String km) {
    return '$km km of road';
  }

  @override
  String get bestLap => 'Best lap';

  @override
  String get bestLapNone => 'No record yet';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get opponents => 'Opponents';

  @override
  String get aiCountOne => '1 AI car';

  @override
  String aiCountMany(int count) {
    return '$count AI cars';
  }

  @override
  String get paused => 'Paused';

  @override
  String get resume => 'Resume';

  @override
  String get restart => 'Restart';

  @override
  String get quitToMenu => 'Quit to menu';

  @override
  String get raceAgain => 'Race again';

  @override
  String get changeTrackCar => 'Track / car';

  @override
  String get menu => 'Menu';

  @override
  String placeResult(String ordinal) {
    return '$ordinal place';
  }

  @override
  String get totalTime => 'Total time';

  @override
  String get newRecord => 'New record';

  @override
  String get coins => 'Coins';

  @override
  String collected(int count) {
    return '$count collected';
  }

  @override
  String lapNumber(int number, String time) {
    return 'Lap $number  $time';
  }

  @override
  String get racing => 'racing';

  @override
  String get you => 'YOU';

  @override
  String hudLap(int current, int total) {
    return 'LAP $current/$total';
  }

  @override
  String hudPos(int position, int count) {
    return 'POS $position/$count';
  }

  @override
  String hudCoins(int count) {
    return 'COINS $count';
  }

  @override
  String hudLapTime(String time) {
    return 'LAP $time';
  }

  @override
  String hudBest(String time) {
    return 'BEST $time';
  }

  @override
  String get wrongWay => 'Wrong way';

  @override
  String get drift => 'DRIFT';

  @override
  String get nitro => 'NITRO';

  @override
  String get speedUnit => 'km/h';

  @override
  String get backOnRoad => 'Back on road';

  @override
  String get pause => 'Pause';

  @override
  String get aiDebugTooltip => 'AI debug view (B)';

  @override
  String get statSpeed => 'Speed';

  @override
  String get statAcceleration => 'Accel';

  @override
  String get statHandling => 'Handling';

  @override
  String get statGrip => 'Grip';

  @override
  String get statBraking => 'Braking';

  @override
  String get statNitro => 'Nitro';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAudio => 'Audio';

  @override
  String get musicVolume => 'Music volume';

  @override
  String get sfxVolume => 'Sound effects volume';

  @override
  String get sectionControls => 'Controls';

  @override
  String get controlScheme => 'Control scheme';

  @override
  String get schemeButtons => 'Buttons';

  @override
  String get schemeWheel => 'Wheel';

  @override
  String get schemeTilt => 'Tilt';

  @override
  String get steeringSensitivity => 'Steering sensitivity';

  @override
  String get sectionGraphics => 'Graphics';

  @override
  String get graphicsQuality => 'Graphics quality';

  @override
  String get qualityLow => 'Low';

  @override
  String get qualityMedium => 'Medium';

  @override
  String get qualityHigh => 'High';

  @override
  String get sectionFeel => 'Feel';

  @override
  String get haptics => 'Haptic feedback';

  @override
  String get sectionAccessibility => 'Accessibility';

  @override
  String get textSize => 'Text size';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Large';

  @override
  String get textExtraLarge => 'Extra large';

  @override
  String get highContrast => 'High contrast';

  @override
  String get colorblindIndicators => 'Extra shape and icon cues';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get garage => 'Garage';

  @override
  String get championship => 'Championship';

  @override
  String get rewards => 'Rewards';

  @override
  String carLocked(int cost) {
    return 'Locked · $cost coins';
  }

  @override
  String unlockFor(int cost) {
    return 'Unlock for $cost';
  }

  @override
  String get selected => 'Selected';

  @override
  String get lockedLabel => 'Locked';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get upgradeEngine => 'Engine';

  @override
  String get upgradeEngineDesc => 'Top speed and acceleration';

  @override
  String get upgradeTires => 'Tires';

  @override
  String get upgradeTiresDesc => 'Grip and steering';

  @override
  String get upgradeBrakes => 'Brakes';

  @override
  String get upgradeBrakesDesc => 'Braking power';

  @override
  String get upgradeNitro => 'Nitro';

  @override
  String get upgradeNitroDesc => 'Longer and stronger boost';

  @override
  String buyFor(int cost) {
    return 'Buy for $cost';
  }

  @override
  String get maxLevel => 'MAX';

  @override
  String level(int level) {
    return 'Level $level';
  }

  @override
  String roundLabel(int number) {
    return 'Round $number';
  }

  @override
  String get roundDone => 'Done';

  @override
  String get roundNext => 'Next';

  @override
  String get roundUpcoming => 'Upcoming';

  @override
  String get standings => 'Standings';

  @override
  String points(int points) {
    return '$points pts';
  }

  @override
  String get noStandings => 'Points appear after the first round.';

  @override
  String get championshipLocked =>
      'Unlock every championship track to start the season.';

  @override
  String raceRound(int number) {
    return 'Race round $number';
  }

  @override
  String get newSeason => 'Start new season';

  @override
  String get seasonComplete => 'Season complete';

  @override
  String get seasonChampion => 'Champion!';

  @override
  String get dailyReward => 'Daily reward';

  @override
  String get dailyRewardReady => 'Claim your login reward';

  @override
  String get dailyRewardDone => 'Come back tomorrow for more';

  @override
  String dailyStreak(int streak) {
    return 'Day $streak streak';
  }

  @override
  String get claim => 'Claim';

  @override
  String get claimed => 'Claimed';

  @override
  String get dailyChallenge => 'Daily challenge';

  @override
  String challengeDrifts(int target) {
    return 'Drift $target times today';
  }

  @override
  String challengeCleanLaps(int target) {
    return 'Drive $target clean laps today';
  }

  @override
  String challengeFinishes(int target) {
    return 'Finish $target races today';
  }

  @override
  String progressOf(int value, int target) {
    return '$value / $target';
  }

  @override
  String get achievements => 'Achievements';

  @override
  String get achFirstWin => 'First win';

  @override
  String get achFirstWinDesc => 'Win a race';

  @override
  String get achPodium => 'Podium';

  @override
  String get achPodiumDesc => 'Finish in the top three';

  @override
  String get achDrifter => 'Drift king';

  @override
  String get achDrifterDesc => 'Drift 10 times in one race';

  @override
  String get achPerfectLap => 'Perfect lap';

  @override
  String get achPerfectLapDesc => 'Finish a lap without hitting anything';

  @override
  String get achRacer10 => 'Veteran';

  @override
  String get achRacer10Desc => 'Race 10 times';

  @override
  String get achChampion => 'Champion';

  @override
  String get achChampionDesc => 'Win a championship season';

  @override
  String get statsRaces => 'Races';

  @override
  String get statsWins => 'Wins';

  @override
  String get statsPodiums => 'Podiums';

  @override
  String get statsDrifts => 'Drifts';

  @override
  String get statsCleanLaps => 'Clean laps';

  @override
  String get statsCoinsEarned => 'Coins earned';

  @override
  String rewardPosition(int amount) {
    return 'Position +$amount';
  }

  @override
  String rewardCoins(int amount) {
    return 'Coins +$amount';
  }

  @override
  String rewardCleanLaps(int amount) {
    return 'Clean laps +$amount';
  }

  @override
  String rewardDrifts(int amount) {
    return 'Drifts +$amount';
  }

  @override
  String rewardAchievements(int amount) {
    return 'Achievements +$amount';
  }

  @override
  String rewardSeason(int amount) {
    return 'Season bonus +$amount';
  }

  @override
  String rewardTotal(int amount) {
    return 'Total +$amount';
  }

  @override
  String champPoints(int points) {
    return 'Championship +$points pts';
  }

  @override
  String get achievementUnlocked => 'Achievement unlocked';

  @override
  String get dailyChallengeDone => 'Daily challenge complete!';
}
