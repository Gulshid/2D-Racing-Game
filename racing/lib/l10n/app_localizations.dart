import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Racing Game'**
  String get appName;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @cars.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get cars;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @startRace.
  ///
  /// In en, this message translates to:
  /// **'Start race'**
  String get startRace;

  /// No description provided for @chooseTrack.
  ///
  /// In en, this message translates to:
  /// **'Choose a track'**
  String get chooseTrack;

  /// No description provided for @chooseCar.
  ///
  /// In en, this message translates to:
  /// **'Choose your car'**
  String get chooseCar;

  /// No description provided for @laps.
  ///
  /// In en, this message translates to:
  /// **'{count} laps'**
  String laps(int count);

  /// No description provided for @parTime.
  ///
  /// In en, this message translates to:
  /// **'Par {seconds}s'**
  String parTime(int seconds);

  /// No description provided for @roadLength.
  ///
  /// In en, this message translates to:
  /// **'{km} km of road'**
  String roadLength(String km);

  /// No description provided for @bestLap.
  ///
  /// In en, this message translates to:
  /// **'Best lap'**
  String get bestLap;

  /// No description provided for @bestLapNone.
  ///
  /// In en, this message translates to:
  /// **'No record yet'**
  String get bestLapNone;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @opponents.
  ///
  /// In en, this message translates to:
  /// **'Opponents'**
  String get opponents;

  /// No description provided for @aiCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 AI car'**
  String get aiCountOne;

  /// No description provided for @aiCountMany.
  ///
  /// In en, this message translates to:
  /// **'{count} AI cars'**
  String aiCountMany(int count);

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @quitToMenu.
  ///
  /// In en, this message translates to:
  /// **'Quit to menu'**
  String get quitToMenu;

  /// No description provided for @raceAgain.
  ///
  /// In en, this message translates to:
  /// **'Race again'**
  String get raceAgain;

  /// No description provided for @changeTrackCar.
  ///
  /// In en, this message translates to:
  /// **'Track / car'**
  String get changeTrackCar;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @placeResult.
  ///
  /// In en, this message translates to:
  /// **'{ordinal} place'**
  String placeResult(String ordinal);

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get totalTime;

  /// No description provided for @newRecord.
  ///
  /// In en, this message translates to:
  /// **'New record'**
  String get newRecord;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'{count} collected'**
  String collected(int count);

  /// No description provided for @lapNumber.
  ///
  /// In en, this message translates to:
  /// **'Lap {number}  {time}'**
  String lapNumber(int number, String time);

  /// No description provided for @racing.
  ///
  /// In en, this message translates to:
  /// **'racing'**
  String get racing;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get you;

  /// No description provided for @hudLap.
  ///
  /// In en, this message translates to:
  /// **'LAP {current}/{total}'**
  String hudLap(int current, int total);

  /// No description provided for @hudPos.
  ///
  /// In en, this message translates to:
  /// **'POS {position}/{count}'**
  String hudPos(int position, int count);

  /// No description provided for @hudCoins.
  ///
  /// In en, this message translates to:
  /// **'COINS {count}'**
  String hudCoins(int count);

  /// No description provided for @hudLapTime.
  ///
  /// In en, this message translates to:
  /// **'LAP {time}'**
  String hudLapTime(String time);

  /// No description provided for @hudBest.
  ///
  /// In en, this message translates to:
  /// **'BEST {time}'**
  String hudBest(String time);

  /// No description provided for @wrongWay.
  ///
  /// In en, this message translates to:
  /// **'Wrong way'**
  String get wrongWay;

  /// No description provided for @drift.
  ///
  /// In en, this message translates to:
  /// **'DRIFT'**
  String get drift;

  /// No description provided for @nitro.
  ///
  /// In en, this message translates to:
  /// **'NITRO'**
  String get nitro;

  /// No description provided for @speedUnit.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get speedUnit;

  /// No description provided for @backOnRoad.
  ///
  /// In en, this message translates to:
  /// **'Back on road'**
  String get backOnRoad;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @aiDebugTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI debug view (B)'**
  String get aiDebugTooltip;

  /// No description provided for @statSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get statSpeed;

  /// No description provided for @statAcceleration.
  ///
  /// In en, this message translates to:
  /// **'Accel'**
  String get statAcceleration;

  /// No description provided for @statHandling.
  ///
  /// In en, this message translates to:
  /// **'Handling'**
  String get statHandling;

  /// No description provided for @statGrip.
  ///
  /// In en, this message translates to:
  /// **'Grip'**
  String get statGrip;

  /// No description provided for @statBraking.
  ///
  /// In en, this message translates to:
  /// **'Braking'**
  String get statBraking;

  /// No description provided for @statNitro.
  ///
  /// In en, this message translates to:
  /// **'Nitro'**
  String get statNitro;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get sectionAudio;

  /// No description provided for @musicVolume.
  ///
  /// In en, this message translates to:
  /// **'Music volume'**
  String get musicVolume;

  /// No description provided for @sfxVolume.
  ///
  /// In en, this message translates to:
  /// **'Sound effects volume'**
  String get sfxVolume;

  /// No description provided for @sectionControls.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get sectionControls;

  /// No description provided for @controlScheme.
  ///
  /// In en, this message translates to:
  /// **'Control scheme'**
  String get controlScheme;

  /// No description provided for @schemeButtons.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get schemeButtons;

  /// No description provided for @schemeWheel.
  ///
  /// In en, this message translates to:
  /// **'Wheel'**
  String get schemeWheel;

  /// No description provided for @schemeTilt.
  ///
  /// In en, this message translates to:
  /// **'Tilt'**
  String get schemeTilt;

  /// No description provided for @steeringSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Steering sensitivity'**
  String get steeringSensitivity;

  /// No description provided for @sectionGraphics.
  ///
  /// In en, this message translates to:
  /// **'Graphics'**
  String get sectionGraphics;

  /// No description provided for @graphicsQuality.
  ///
  /// In en, this message translates to:
  /// **'Graphics quality'**
  String get graphicsQuality;

  /// No description provided for @qualityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get qualityLow;

  /// No description provided for @qualityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get qualityMedium;

  /// No description provided for @qualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get qualityHigh;

  /// No description provided for @sectionFeel.
  ///
  /// In en, this message translates to:
  /// **'Feel'**
  String get sectionFeel;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get haptics;

  /// No description provided for @sectionAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get sectionAccessibility;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textNormal;

  /// No description provided for @textLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textLarge;

  /// No description provided for @textExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textExtraLarge;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @colorblindIndicators.
  ///
  /// In en, this message translates to:
  /// **'Extra shape and icon cues'**
  String get colorblindIndicators;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @garage.
  ///
  /// In en, this message translates to:
  /// **'Garage'**
  String get garage;

  /// No description provided for @championship.
  ///
  /// In en, this message translates to:
  /// **'Championship'**
  String get championship;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @carLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked · {cost} coins'**
  String carLocked(int cost);

  /// No description provided for @unlockFor.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {cost}'**
  String unlockFor(int cost);

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @lockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedLabel;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @upgradeEngine.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get upgradeEngine;

  /// No description provided for @upgradeEngineDesc.
  ///
  /// In en, this message translates to:
  /// **'Top speed and acceleration'**
  String get upgradeEngineDesc;

  /// No description provided for @upgradeTires.
  ///
  /// In en, this message translates to:
  /// **'Tires'**
  String get upgradeTires;

  /// No description provided for @upgradeTiresDesc.
  ///
  /// In en, this message translates to:
  /// **'Grip and steering'**
  String get upgradeTiresDesc;

  /// No description provided for @upgradeBrakes.
  ///
  /// In en, this message translates to:
  /// **'Brakes'**
  String get upgradeBrakes;

  /// No description provided for @upgradeBrakesDesc.
  ///
  /// In en, this message translates to:
  /// **'Braking power'**
  String get upgradeBrakesDesc;

  /// No description provided for @upgradeNitro.
  ///
  /// In en, this message translates to:
  /// **'Nitro'**
  String get upgradeNitro;

  /// No description provided for @upgradeNitroDesc.
  ///
  /// In en, this message translates to:
  /// **'Longer and stronger boost'**
  String get upgradeNitroDesc;

  /// No description provided for @buyFor.
  ///
  /// In en, this message translates to:
  /// **'Buy for {cost}'**
  String buyFor(int cost);

  /// No description provided for @maxLevel.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get maxLevel;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String level(int level);

  /// No description provided for @roundLabel.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String roundLabel(int number);

  /// No description provided for @roundDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get roundDone;

  /// No description provided for @roundNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get roundNext;

  /// No description provided for @roundUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get roundUpcoming;

  /// No description provided for @standings.
  ///
  /// In en, this message translates to:
  /// **'Standings'**
  String get standings;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String points(int points);

  /// No description provided for @noStandings.
  ///
  /// In en, this message translates to:
  /// **'Points appear after the first round.'**
  String get noStandings;

  /// No description provided for @championshipLocked.
  ///
  /// In en, this message translates to:
  /// **'Unlock every championship track to start the season.'**
  String get championshipLocked;

  /// No description provided for @raceRound.
  ///
  /// In en, this message translates to:
  /// **'Race round {number}'**
  String raceRound(int number);

  /// No description provided for @newSeason.
  ///
  /// In en, this message translates to:
  /// **'Start new season'**
  String get newSeason;

  /// No description provided for @seasonComplete.
  ///
  /// In en, this message translates to:
  /// **'Season complete'**
  String get seasonComplete;

  /// No description provided for @seasonChampion.
  ///
  /// In en, this message translates to:
  /// **'Champion!'**
  String get seasonChampion;

  /// No description provided for @dailyReward.
  ///
  /// In en, this message translates to:
  /// **'Daily reward'**
  String get dailyReward;

  /// No description provided for @dailyRewardReady.
  ///
  /// In en, this message translates to:
  /// **'Claim your login reward'**
  String get dailyRewardReady;

  /// No description provided for @dailyRewardDone.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow for more'**
  String get dailyRewardDone;

  /// No description provided for @dailyStreak.
  ///
  /// In en, this message translates to:
  /// **'Day {streak} streak'**
  String dailyStreak(int streak);

  /// No description provided for @claim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claim;

  /// No description provided for @claimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get claimed;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge'**
  String get dailyChallenge;

  /// No description provided for @challengeDrifts.
  ///
  /// In en, this message translates to:
  /// **'Drift {target} times today'**
  String challengeDrifts(int target);

  /// No description provided for @challengeCleanLaps.
  ///
  /// In en, this message translates to:
  /// **'Drive {target} clean laps today'**
  String challengeCleanLaps(int target);

  /// No description provided for @challengeFinishes.
  ///
  /// In en, this message translates to:
  /// **'Finish {target} races today'**
  String challengeFinishes(int target);

  /// No description provided for @progressOf.
  ///
  /// In en, this message translates to:
  /// **'{value} / {target}'**
  String progressOf(int value, int target);

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @achFirstWin.
  ///
  /// In en, this message translates to:
  /// **'First win'**
  String get achFirstWin;

  /// No description provided for @achFirstWinDesc.
  ///
  /// In en, this message translates to:
  /// **'Win a race'**
  String get achFirstWinDesc;

  /// No description provided for @achPodium.
  ///
  /// In en, this message translates to:
  /// **'Podium'**
  String get achPodium;

  /// No description provided for @achPodiumDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish in the top three'**
  String get achPodiumDesc;

  /// No description provided for @achDrifter.
  ///
  /// In en, this message translates to:
  /// **'Drift king'**
  String get achDrifter;

  /// No description provided for @achDrifterDesc.
  ///
  /// In en, this message translates to:
  /// **'Drift 10 times in one race'**
  String get achDrifterDesc;

  /// No description provided for @achPerfectLap.
  ///
  /// In en, this message translates to:
  /// **'Perfect lap'**
  String get achPerfectLap;

  /// No description provided for @achPerfectLapDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish a lap without hitting anything'**
  String get achPerfectLapDesc;

  /// No description provided for @achRacer10.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get achRacer10;

  /// No description provided for @achRacer10Desc.
  ///
  /// In en, this message translates to:
  /// **'Race 10 times'**
  String get achRacer10Desc;

  /// No description provided for @achChampion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get achChampion;

  /// No description provided for @achChampionDesc.
  ///
  /// In en, this message translates to:
  /// **'Win a championship season'**
  String get achChampionDesc;

  /// No description provided for @statsRaces.
  ///
  /// In en, this message translates to:
  /// **'Races'**
  String get statsRaces;

  /// No description provided for @statsWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get statsWins;

  /// No description provided for @statsPodiums.
  ///
  /// In en, this message translates to:
  /// **'Podiums'**
  String get statsPodiums;

  /// No description provided for @statsDrifts.
  ///
  /// In en, this message translates to:
  /// **'Drifts'**
  String get statsDrifts;

  /// No description provided for @statsCleanLaps.
  ///
  /// In en, this message translates to:
  /// **'Clean laps'**
  String get statsCleanLaps;

  /// No description provided for @statsCoinsEarned.
  ///
  /// In en, this message translates to:
  /// **'Coins earned'**
  String get statsCoinsEarned;

  /// No description provided for @rewardPosition.
  ///
  /// In en, this message translates to:
  /// **'Position +{amount}'**
  String rewardPosition(int amount);

  /// No description provided for @rewardCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins +{amount}'**
  String rewardCoins(int amount);

  /// No description provided for @rewardCleanLaps.
  ///
  /// In en, this message translates to:
  /// **'Clean laps +{amount}'**
  String rewardCleanLaps(int amount);

  /// No description provided for @rewardDrifts.
  ///
  /// In en, this message translates to:
  /// **'Drifts +{amount}'**
  String rewardDrifts(int amount);

  /// No description provided for @rewardAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements +{amount}'**
  String rewardAchievements(int amount);

  /// No description provided for @rewardSeason.
  ///
  /// In en, this message translates to:
  /// **'Season bonus +{amount}'**
  String rewardSeason(int amount);

  /// No description provided for @rewardTotal.
  ///
  /// In en, this message translates to:
  /// **'Total +{amount}'**
  String rewardTotal(int amount);

  /// No description provided for @champPoints.
  ///
  /// In en, this message translates to:
  /// **'Championship +{points} pts'**
  String champPoints(int points);

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked'**
  String get achievementUnlocked;

  /// No description provided for @dailyChallengeDone.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge complete!'**
  String get dailyChallengeDone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
