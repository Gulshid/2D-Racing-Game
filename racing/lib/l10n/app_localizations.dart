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
