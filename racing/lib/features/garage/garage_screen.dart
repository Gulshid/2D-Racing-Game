import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/app/router.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/data/models/progression_config.dart';
import 'package:racing/features/progress/car_stat_bars.dart';
import 'package:racing/features/progress/coins_badge.dart';
import 'package:racing/features/providers/progress_provider.dart';
import 'package:racing/features/providers/race_setup_provider.dart';
import 'package:racing/l10n/app_localizations.dart';

/// Pick the car you race with, unlock cars, and buy upgrades. Stat bars
/// update straight away after each purchase.
class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final setup = ref.watch(raceSetupProvider);
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);
    final selected = setup.carIndex;

    return ScreenFrame(
      title: l10n.garage,
      onBack: () => context.go(AppRoutes.menu),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 260,
            child: ListView.separated(
              itemCount: CarPresets.all.length,
              separatorBuilder: (context, i) =>
                  const SizedBox(height: AppSpace.s),
              itemBuilder: (context, i) {
                final unlocked = notifier.isCarUnlocked(i);
                return AppCard(
                  selected: i == selected,
                  onTap: () {
                    if (unlocked) {
                      ref.read(raceSetupProvider.notifier).selectCar(i);
                    } else {
                      notifier.unlockCar(i);
                    }
                  },
                  semanticLabel: CarPresets.all[i].name,
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: CarPresets.all[i].color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpace.m),
                      Expanded(
                        child: Text(
                          CarPresets.all[i].name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (!unlocked)
                        Text(
                          l10n.carLocked(Economy.carCostFor(i)),
                          style: const TextStyle(fontSize: 11),
                        )
                      else if (i == selected)
                        Text(
                          l10n.selected,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppPalette.of(context).gold,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: AppSpace.l),
          Expanded(
            child: ListView(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        CarPresets.all[selected].name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const CoinsBadge(),
                  ],
                ),
                const SizedBox(height: AppSpace.s),
                AppCard(
                  child: Column(
                    children: carStatBars(
                      l10n,
                      notifier.statsFor(selected),
                    ),
                  ),
                ),
                SectionLabel(l10n.upgrade),
                for (final t in UpgradeType.values)
                  _UpgradeRow(
                    car: selected,
                    type: t,
                    level: notifier.upgradeLevel(selected, t),
                    enabled: notifier.isCarUnlocked(selected),
                    coins: progress.save.coins,
                    onBuy: () => notifier.buyUpgrade(selected, t),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeRow extends StatelessWidget {
  const _UpgradeRow({
    required this.car,
    required this.type,
    required this.level,
    required this.enabled,
    required this.coins,
    required this.onBuy,
  });

  final int car;
  final UpgradeType type;
  final int level;
  final bool enabled;
  final int coins;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppPalette.of(context);
    final maxed = level >= Economy.maxUpgradeLevel;
    final cost = Economy.upgradeCost(level);
    final canBuy = enabled && !maxed && coins >= cost;

    final (name, desc) = switch (type) {
      UpgradeType.engine => (l10n.upgradeEngine, l10n.upgradeEngineDesc),
      UpgradeType.tires => (l10n.upgradeTires, l10n.upgradeTiresDesc),
      UpgradeType.brakes => (l10n.upgradeBrakes, l10n.upgradeBrakesDesc),
      UpgradeType.nitro => (l10n.upgradeNitro, l10n.upgradeNitroDesc),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Text(desc, style: TextStyle(fontSize: 12, color: p.textMuted)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var i = 0; i < Economy.maxUpgradeLevel; i++)
                        Container(
                          width: 14,
                          height: 8,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: i < level ? p.accent : p.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.level(level),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.m),
            SizedBox(
              width: 170,
              child: AppButton(
                label: maxed ? l10n.maxLevel : l10n.buyFor(cost),
                icon: maxed ? Icons.check : Icons.upgrade,
                primary: canBuy,
                onPressed: canBuy ? onBuy : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
