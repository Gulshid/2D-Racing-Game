import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racing/data/models/app_settings.dart';
import 'package:racing/data/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Replaced in main() with the loaded instance (see ProviderScope overrides).
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPrefsProvider in main()'),
);

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() =>
      SettingsRepository(ref.watch(sharedPrefsProvider)).load();

  /// Applies [change] at once so the UI updates, then saves in the background.
  void update(AppSettings Function(AppSettings current) change) {
    state = change(state);
    unawaited(SettingsRepository(ref.read(sharedPrefsProvider)).save(state));
  }
}
