import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/app/router.dart';
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.appName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  AppButton(
                    label: l10n.play,
                    icon: Icons.play_arrow,
                    onPressed: () => context.go(AppRoutes.tracks),
                  ),
                  const SizedBox(height: AppSpace.m),
                  AppButton(
                    label: l10n.cars,
                    icon: Icons.directions_car,
                    primary: false,
                    onPressed: () => context.go(AppRoutes.cars),
                  ),
                  const SizedBox(height: AppSpace.m),
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
        ),
      ),
    );
  }
}
