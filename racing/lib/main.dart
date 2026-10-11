import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racing/app/app.dart';
import 'package:racing/core/services/analytics.dart';
import 'package:racing/core/services/crash_reporter.dart';
import 'package:racing/core/services/error_handling.dart';
import 'package:racing/features/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Swap these for real implementations (Sentry, Firebase...) when ready.
  final crashReporter = ConsoleCrashReporter();
  final analytics = ConsoleAnalytics();

  // Everything runs in one guarded zone so uncaught errors are reported.
  ErrorHandling.runGuarded(crashReporter, () async {
    WidgetsFlutterBinding.ensureInitialized();
    ErrorHandling.install(crashReporter);

    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Settings are read once here so the first frame already uses them.
    final prefs = await SharedPreferences.getInstance();
    runApp(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          crashReporterProvider.overrideWithValue(crashReporter),
          analyticsProvider.overrideWithValue(analytics),
        ],
        child: const RacingApp(),
      ),
    );
  });
}
