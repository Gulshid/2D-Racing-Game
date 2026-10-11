import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racing/app/app.dart';
import 'package:racing/features/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('splash leads to main menu', (tester) async {
    // The app reads settings from SharedPreferences, so it must be provided
    // exactly like main() does.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const RacingApp(),
      ),
    );
    expect(find.text('RACING GAME'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('MAIN MENU'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'PLAY'), findsOneWidget);
  });
}
