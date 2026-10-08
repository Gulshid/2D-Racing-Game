import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racing_game/app/app.dart';

void main() {
  testWidgets('splash leads to main menu', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RacingApp()));
    expect(find.text('RACING GAME'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('MAIN MENU'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'PLAY'), findsOneWidget);
  });
}
