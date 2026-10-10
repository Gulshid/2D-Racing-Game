import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/game/audio/audio_service.dart';

/// Page frame: safe area, back button, title, and content centred and
/// capped in width so it stays readable on large screens.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    required this.title,
    required this.onBack,
    required this.child,
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.m,
            AppSpace.s,
            AppSpace.m,
            AppSpace.m,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: AppSpace.s),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: child,
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

/// Main action button. Primary = filled accent, otherwise outlined.
class AppButton extends ConsumerWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final VoidCallback? handler = onPressed == null
        ? null
        : () {
            ref.read(audioServiceProvider).playSfx(Sfx.uiClick);
            onPressed!();
          };
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpace.s),
        ],
        Flexible(
          child: Text(
            label.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
    return SizedBox(
      height: AppSpace.touch,
      child: primary
          ? FilledButton(onPressed: handler, child: content)
          : OutlinedButton(onPressed: handler, child: content),
    );
  }
}

/// Rounded panel that can be selected and tapped.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.selected = false,
    this.onTap,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(AppSpace.m),
    super.key,
  });

  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: selected ? p.cardSelected : p.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.radius),
          side: BorderSide(
            color: selected ? p.accent : p.border,
            width: selected ? 3 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Translucent panel used over the race view (HUD).
class HudPanel extends StatelessWidget {
  const HudPanel({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }
}

/// Small uppercase heading above a group of controls.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, AppSpace.m, 4, AppSpace.s),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
          color: p.textMuted,
        ),
      ),
    );
  }
}

/// Labelled horizontal bar, used for car stats.
class StatBar extends StatelessWidget {
  const StatBar({required this.label, required this.value, super.key});

  final String label;

  /// 0..1
  final double value;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final v = clampD(value, 0, 1);
    return Semantics(
      label: '$label ${(v * 100).round()} percent',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: p.textMuted),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: p.border,
                  color: p.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Number that counts smoothly to its new value.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    required this.value,
    required this.style,
    this.decimals = 0,
    super.key,
  });

  final double value;
  final TextStyle style;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text(v.toStringAsFixed(decimals), style: style),
    );
  }
}

/// Page transition: short fade with a small slide. Skipped when the system
/// asks for reduced motion.
CustomTransitionPage<void> slideFadePage({
  required LocalKey key,
  required Widget child,
}) =>
    CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondary, page) {
        if (MediaQuery.of(context).disableAnimations) return page;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: page,
          ),
        );
      },
    );
