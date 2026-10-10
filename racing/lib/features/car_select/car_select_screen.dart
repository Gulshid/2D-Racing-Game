import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/app/router.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/ai_profile.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/data/models/progression_config.dart';
import 'package:racing/data/tracks/track_library.dart';
import 'package:racing/features/progress/car_stat_bars.dart';
import 'package:racing/features/providers/progress_provider.dart';
import 'package:racing/features/providers/race_setup_provider.dart';
import 'package:racing/l10n/app_localizations.dart';
import 'package:racing/l10n/l10n_names.dart';

/// Pick a car and the opponents, then start the race. Locked cars are bought
/// in the garage.
class CarSelectScreen extends ConsumerWidget {
  const CarSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final setup = ref.watch(raceSetupProvider);
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(raceSetupProvider.notifier);
    final progressNotifier = ref.read(progressProvider.notifier);
    final carUnlocked = progressNotifier.isCarUnlocked(setup.carIndex);

    return ScreenFrame(
      title: l10n.chooseCar,
      onBack: () => context.go(AppRoutes.tracks),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ListView.separated(
              itemCount: CarPresets.all.length,
              separatorBuilder: (context, i) =>
                  const SizedBox(height: AppSpace.s),
              itemBuilder: (context, i) {
                final unlocked = progressNotifier.isCarUnlocked(i);
                return _CarTile(
                  stats: progressNotifier.statsFor(i),
                  selected: i == setup.carIndex,
                  locked: !unlocked,
                  lockCost: Economy.carCostFor(i),
                  onTap: unlocked ? () => notifier.selectCar(i) : null,
                );
              },
            ),
          ),
          const SizedBox(width: AppSpace.l),
          SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: _OpponentsPanel(
                      difficulty: setup.difficulty,
                      count: setup.opponents,
                      onDifficulty: notifier.selectDifficulty,
                      onCount: notifier.setOpponents,
                    ),
                  ),
                  const SizedBox(height: AppSpace.l),
                  AppButton(
                    label: l10n.startRace,
                    icon: Icons.flag,
                    onPressed: carUnlocked && progress.save.unlockedTracks.contains(
                            TrackLibrary.all[setup.trackIndex].id)
                        ? () => context.go(
                              AppRoutes.raceUrl(
                                trackId: TrackLibrary.all[setup.trackIndex].id,
                                carIndex: setup.carIndex,
                                difficulty: setup.difficulty,
                                aiCount: setup.opponents,
                              ),
                            )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarTile extends StatelessWidget {
  const _CarTile({
    required this.stats,
    required this.selected,
    required this.locked,
    required this.lockCost,
    required this.onTap,
  });

  final CarStats stats;
  final bool selected;
  final bool locked;
  final int lockCost;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppPalette.of(context);
    final bars = carStatBars(l10n, stats);
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: AppCard(
        selected: selected,
        onTap: onTap,
        semanticLabel: stats.name,
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: stats.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpace.m),
            SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  if (locked)
                    Row(
                      children: [
                        const Icon(Icons.lock, size: 13),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.carLocked(lockCost),
                            style: TextStyle(fontSize: 11, color: p.textMuted),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(child: Column(children: bars.sublist(0, 3))),
            const SizedBox(width: AppSpace.m),
            Expanded(child: Column(children: bars.sublist(3))),
          ],
        ),
      ),
    );
  }
}

class _OpponentsPanel extends StatelessWidget {
  const _OpponentsPanel({
    required this.difficulty,
    required this.count,
    required this.onDifficulty,
    required this.onCount,
  });

  final AiDifficulty difficulty;
  final int count;
  final ValueChanged<AiDifficulty> onDifficulty;
  final ValueChanged<int> onCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.opponents.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            color: p.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.s),
        Wrap(
          spacing: AppSpace.s,
          children: [
            for (final d in AiDifficulty.values)
              ChoiceChip(
                label: Text(aiDifficultyName(l10n, d)),
                selected: d == difficulty,
                onSelected: (_) => onDifficulty(d),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.m),
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: '-',
              onPressed: count > 0 ? () => onCount(count - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Text(
                count == 1 ? l10n.aiCountOne : l10n.aiCountMany(count),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton.filledTonal(
              tooltip: '+',
              onPressed: count < GameConfig.aiMaxOpponents
                  ? () => onCount(count + 1)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
