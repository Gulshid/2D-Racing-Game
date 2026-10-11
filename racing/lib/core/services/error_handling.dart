import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:racing/core/services/crash_reporter.dart';

/// Routes every kind of uncaught error to a [CrashReporter].
abstract final class ErrorHandling {
  /// Hooks Flutter framework errors and platform (async) errors.
  /// Call once, early in main(). Returns a function that restores the
  /// previous handlers (used by tests).
  static void Function() install(CrashReporter reporter) {
    final previousFlutter = FlutterError.onError;
    final previousPlatform = PlatformDispatcher.instance.onError;

    FlutterError.onError = (details) {
      reporter.recordError(
        details.exception,
        details.stack,
        fatal: false,
        reason: details.context?.toString(),
      );
      previousFlutter?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      reporter.recordError(error, stack, fatal: true, reason: 'platform');
      return true; // handled, do not crash the app
    };

    // In release builds a broken widget shows a calm message, not a red
    // error box or a blank screen.
    final previousBuilder = ErrorWidget.builder;
    if (!_isDebug) {
      ErrorWidget.builder = (details) => const _FriendlyError();
    }

    return () {
      FlutterError.onError = previousFlutter;
      PlatformDispatcher.instance.onError = previousPlatform;
      ErrorWidget.builder = previousBuilder;
    };
  }

  /// Runs [body] in a zone that reports uncaught async errors.
  static void runGuarded(CrashReporter reporter, Future<void> Function() body) {
    runZonedGuarded(
      body,
      (error, stack) =>
          reporter.recordError(error, stack, fatal: true, reason: 'zone'),
    );
  }

  static bool get _isDebug {
    var debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug;
  }
}

class _FriendlyError extends StatelessWidget {
  const _FriendlyError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF14181F),
      child: Center(
        child: Text(
          'Something went wrong.\nPlease go back and try again.',
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: TextStyle(color: Color(0xFFE6EAF0), fontSize: 16),
        ),
      ),
    );
  }
}
