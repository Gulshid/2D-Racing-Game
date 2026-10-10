import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/data/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads and saves [AppSettings] with shared_preferences.
/// Missing or broken values fall back to defaults, so a damaged save can
/// never stop the app from starting.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _music = 'settings.music';
  static const _sfx = 'settings.sfx';
  static const _scheme = 'settings.controlScheme';
  static const _sensitivity = 'settings.steeringSensitivity';
  static const _quality = 'settings.graphicsQuality';
  static const _haptics = 'settings.haptics';
  static const _textSize = 'settings.textSize';
  static const _contrast = 'settings.highContrast';
  static const _cues = 'settings.colorblindCues';

  AppSettings load() {
    const d = AppSettings();
    return AppSettings(
      musicVolume: clampD(_prefs.getDouble(_music) ?? d.musicVolume, 0, 1),
      sfxVolume: clampD(_prefs.getDouble(_sfx) ?? d.sfxVolume, 0, 1),
      controlScheme: _enumAt(
        ControlScheme.values,
        _prefs.getInt(_scheme),
        d.controlScheme,
      ),
      steeringSensitivity: clampD(
        _prefs.getDouble(_sensitivity) ?? d.steeringSensitivity,
        0.5,
        1.5,
      ),
      graphicsQuality: _enumAt(
        GraphicsQuality.values,
        _prefs.getInt(_quality),
        d.graphicsQuality,
      ),
      haptics: _prefs.getBool(_haptics) ?? d.haptics,
      textSize: _enumAt(TextSize.values, _prefs.getInt(_textSize), d.textSize),
      highContrast: _prefs.getBool(_contrast) ?? d.highContrast,
      colorblindIndicators: _prefs.getBool(_cues) ?? d.colorblindIndicators,
    );
  }

  Future<void> save(AppSettings s) async {
    await _prefs.setDouble(_music, s.musicVolume);
    await _prefs.setDouble(_sfx, s.sfxVolume);
    await _prefs.setInt(_scheme, s.controlScheme.index);
    await _prefs.setDouble(_sensitivity, s.steeringSensitivity);
    await _prefs.setInt(_quality, s.graphicsQuality.index);
    await _prefs.setBool(_haptics, s.haptics);
    await _prefs.setInt(_textSize, s.textSize.index);
    await _prefs.setBool(_contrast, s.highContrast);
    await _prefs.setBool(_cues, s.colorblindIndicators);
  }

  static T _enumAt<T>(List<T> values, int? index, T fallback) =>
      (index == null || index < 0 || index >= values.length)
          ? fallback
          : values[index];
}
