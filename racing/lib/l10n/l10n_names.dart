import 'package:racing/data/models/ai_profile.dart';
import 'package:racing/data/models/app_settings.dart';
import 'package:racing/l10n/app_localizations.dart';

/// Localized labels for enums and track difficulty numbers.
String aiDifficultyName(AppLocalizations l, AiDifficulty d) => switch (d) {
      AiDifficulty.easy => l.difficultyEasy,
      AiDifficulty.medium => l.difficultyMedium,
      AiDifficulty.hard => l.difficultyHard,
    };

/// Track difficulty is stored as 1 (easy) to 3 (hard).
String trackDifficultyName(AppLocalizations l, int d) => switch (d) {
      1 => l.difficultyEasy,
      3 => l.difficultyHard,
      _ => l.difficultyMedium,
    };

String controlSchemeName(AppLocalizations l, ControlScheme s) => switch (s) {
      ControlScheme.buttons => l.schemeButtons,
      ControlScheme.wheel => l.schemeWheel,
      ControlScheme.tilt => l.schemeTilt,
    };

String graphicsQualityName(AppLocalizations l, GraphicsQuality q) =>
    switch (q) {
      GraphicsQuality.low => l.qualityLow,
      GraphicsQuality.medium => l.qualityMedium,
      GraphicsQuality.high => l.qualityHigh,
    };

String textSizeName(AppLocalizations l, TextSize t) => switch (t) {
      TextSize.normal => l.textNormal,
      TextSize.large => l.textLarge,
      TextSize.extraLarge => l.textExtraLarge,
    };

/// Localized achievement title and description, by achievement id.
String achievementTitle(AppLocalizations l, String id) => switch (id) {
      'first_win' => l.achFirstWin,
      'podium' => l.achPodium,
      'drifter' => l.achDrifter,
      'perfect_lap' => l.achPerfectLap,
      'racer_10' => l.achRacer10,
      'champion' => l.achChampion,
      _ => id,
    };

String achievementDescription(AppLocalizations l, String id) => switch (id) {
      'first_win' => l.achFirstWinDesc,
      'podium' => l.achPodiumDesc,
      'drifter' => l.achDrifterDesc,
      'perfect_lap' => l.achPerfectLapDesc,
      'racer_10' => l.achRacer10Desc,
      'champion' => l.achChampionDesc,
      _ => '',
    };
