import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Event names in one place so they stay consistent across the app.
abstract final class AnalyticsEvents {
  static const raceStart = 'race_start';
  static const raceFinish = 'race_finish';
  static const upgradeBought = 'upgrade_bought';
  static const unlock = 'unlock';
}

/// Product analytics. The default does nothing in release builds; swap
/// [analyticsProvider] for Firebase Analytics, Amplitude, etc. in main().
abstract interface class AnalyticsService {
  void logEvent(String name, [Map<String, Object> params = const {}]);
}

/// Prints events in debug builds and keeps them in [events] for tests.
class ConsoleAnalytics implements AnalyticsService {
  final List<({String name, Map<String, Object> params})> events = [];

  @override
  void logEvent(String name, [Map<String, Object> params = const {}]) {
    events.add((name: name, params: params));
    if (kDebugMode) debugPrint('ANALYTICS $name $params');
  }
}

final analyticsProvider = Provider<AnalyticsService>(
  (ref) => ConsoleAnalytics(),
);
