import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/app/router.dart';
import 'package:racing/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.go(AppRoutes.menu);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: p.background,
      body: Center(
        child: AnimatedOpacity(
          opacity: _shown ? 1 : 0,
          duration: const Duration(milliseconds: 600),
          child: AnimatedScale(
            scale: _shown ? 1 : 0.9,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_motorsports, size: 72, color: p.accent),
                const SizedBox(height: 12),
                Text(
                  l10n.appName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
