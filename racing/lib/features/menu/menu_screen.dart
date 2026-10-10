import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/app/router.dart';
import 'package:racing/features/progress/coins_badge.dart';
import 'package:racing/l10n/app_localizations.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.l),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: AppSpace.m),
                    const CoinsBadge(),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton(
                        label: l10n.play,
                        icon: Icons.play_arrow,
                        onPressed: () => context.go(AppRoutes.tracks),
                      ),
                      const SizedBox(height: AppSpace.s),
                      AppButton(
                        label: l10n.championship,
                        icon: Icons.emoji_events,
                        primary: false,
                        onPressed: () => context.go(AppRoutes.championship),
                      ),
                      const SizedBox(height: AppSpace.s),
                      AppButton(
                        label: l10n.garage,
                        icon: Icons.build,
                        primary: false,
                        onPressed: () => context.go(AppRoutes.garage),
                      ),
                      const SizedBox(height: AppSpace.s),
                      AppButton(
                        label: l10n.rewards,
                        icon: Icons.card_giftcard,
                        primary: false,
                        onPressed: () => context.go(AppRoutes.rewards),
                      ),
                      const SizedBox(height: AppSpace.s),
                      AppButton(
                        label: l10n.settings,
                        icon: Icons.settings,
                        primary: false,
                        onPressed: () => context.go(AppRoutes.settings),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
