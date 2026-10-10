import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racing/app/router.dart';
import 'package:racing/app/theme.dart';
import 'package:racing/data/models/app_settings.dart';
import 'package:racing/features/providers/settings_provider.dart';
import 'package:racing/l10n/app_localizations.dart';

class RacingApp extends ConsumerWidget {
  const RacingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'Racing Game',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(settings),
      routerConfig: appRouter,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Text size preset is applied to every screen, including the game HUD.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(settings.textSize.scale),
          ),
          child: child!,
        );
      },
    );
  }
}
