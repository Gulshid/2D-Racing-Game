import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where uncaught errors go. Replace [crashReporterProvider] with an
/// implementation for Sentry, Firebase Crashlytics, etc. in main().
abstract interface class CrashReporter {
  /// Records an error. [fatal] is true for errors that escaped every handler.
  void recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  });

  /// Adds a breadcrumb that is attached to later error reports.
  void log(String message);
}

/// Prints to the console in debug builds and keeps the most recent errors
/// in memory (handy in tests and for a debug screen). Does nothing else.
class ConsoleCrashReporter implements CrashReporter {
  ConsoleCrashReporter({this.maxKept = 20});

  final int maxKept;
  final List<String> breadcrumbs = [];
  final List<RecordedError> errors = [];

  @override
  void recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) {
    errors.add(RecordedError(error, stack, fatal: fatal, reason: reason));
    if (errors.length > maxKept) errors.removeAt(0);
    if (kDebugMode) {
      debugPrint('CRASH${fatal ? ' (fatal)' : ''}: $error'
          '${reason == null ? '' : ' [$reason]'}');
    }
  }

  @override
  void log(String message) {
    breadcrumbs.add(message);
    if (breadcrumbs.length > 50) breadcrumbs.removeAt(0);
  }
}

class RecordedError {
  const RecordedError(this.error, this.stack, {this.fatal = false, this.reason});

  final Object error;
  final StackTrace? stack;
  final bool fatal;
  final String? reason;
}

final crashReporterProvider = Provider<CrashReporter>(
  (ref) => ConsoleCrashReporter(),
);
