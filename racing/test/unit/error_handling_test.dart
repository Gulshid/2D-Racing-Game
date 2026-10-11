import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racing/core/services/analytics.dart';
import 'package:racing/core/services/crash_reporter.dart';
import 'package:racing/core/services/error_handling.dart';

void main() {
  test('Flutter framework errors reach the crash reporter', () {
    final reporter = ConsoleCrashReporter();
    final original = FlutterError.onError;
    // The test framework's own handler would fail the test, so install on
    // top of a quiet one and put the original back afterwards.
    FlutterError.onError = (_) {};
    final restore = ErrorHandling.install(reporter);

    FlutterError.onError!(FlutterErrorDetails(exception: StateError('boom')));

    restore();
    FlutterError.onError = original;

    expect(reporter.errors, hasLength(1));
    expect(reporter.errors.single.error, isA<StateError>());
    expect(reporter.errors.single.fatal, isFalse);
  });

  test('crash reporter keeps only the most recent errors', () {
    final reporter = ConsoleCrashReporter(maxKept: 3);
    for (var i = 0; i < 5; i++) {
      reporter.recordError('e$i', null);
    }
    expect(reporter.errors.map((e) => e.error), ['e2', 'e3', 'e4']);
  });

  test('breadcrumbs are kept in order', () {
    final reporter = ConsoleCrashReporter()
      ..log('a')
      ..log('b');
    expect(reporter.breadcrumbs, ['a', 'b']);
  });

  test('analytics records events', () {
    final a = ConsoleAnalytics()
      ..logEvent(AnalyticsEvents.raceStart, {'track': 'x'});
    expect(a.events.single.name, 'race_start');
    expect(a.events.single.params['track'], 'x');
  });
}
