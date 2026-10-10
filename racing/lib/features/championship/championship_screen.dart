import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/app/router.dart';
import 'package:racing/data/models/progression_config.dart';
import 'package:racing/data/tracks/track_library.dart';
import 'package:racing/features/progress/coins_badge.dart';
import 'package:racing/features/providers/progress_provider.dart';
import 'package:racing/features/providers/race_setup_provider.dart';
import 'package:racing/l10n/app_localizations.dart';

/// Season view: the three rounds, the points table, and the button to race
/// the next round. Rounds are played as normal races with the chosen car.
class ChampionshipScreen extends ConsumerWidget {
  const ChampionshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppPalette.of(context);
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);
    final setup = ref.watch(raceSetupProvider);
    final champ = progress.save.championship;
    final calendar = Economy.seasonCalendar;
    final unlocked = notifier.seasonUnlocked;

    final table = champ.points.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Widget action;
    if (!unlocked) {
      action = Text(
        l10n.championshipLocked,
        textAlign: TextAlign.center,
        style: TextStyle(color: p.textMuted),
      );
    } else if (champ.finished) {
      action = AppButton(
        label: l10n.newSeason,
        icon: Icons.restart_alt,
        onPressed: notifier.startNewSeason,
      );
    } else {
      action = AppButton(
        label: l10n.raceRound(champ.round + 1),
        icon: Icons.flag,
        onPressed: () => context.go(
          AppRoutes.raceUrl(
            trackId: calendar[champ.round],
            carIndex: setup.carIndex,
            difficulty: setup.difficulty,
            aiCount: setup.opponents,
            championship: true,
          ),
        ),
      );
    }

    return ScreenFrame(
      title: l10n.championship,
      onBack: () => context.go(AppRoutes.menu),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 300,
            child: Column(
              children: [
                const Align(alignment: Alignment.centerRight, child: CoinsBadge()),
                const SizedBox(height: AppSpace.s),
                for (var i = 0; i < calendar.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s),
                    child: AppCard(
                      selected: !champ.finished && i == champ.round,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${l10n.roundLabel(i + 1)}  ·  '
                              '${TrackLibrary.byId(calendar[i]).name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            i < champ.round
                                ? l10n.roundDone
                                : (i == champ.round
                                    ? l10n.roundNext
                                    : l10n.roundUpcoming),
                            style: TextStyle(
                              fontSize: 12,
                              color: i < champ.round ? p.gold : p.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(width: double.infinity, child: action),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.l),
          Expanded(
            child: AppCard(
              child: table.isEmpty
                  ? Center(child: Text(l10n.noStandings))
                  : ListView(
                      children: [
                        SectionLabel(l10n.standings),
                        for (var i = 0; i < table.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${i + 1}.',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    table[i].key == 'player'
                                        ? l10n.you
                                        : table[i].key,
                                    style: TextStyle(
                                      fontWeight: table[i].key == 'player'
                                          ? FontWeight.w900
                                          : FontWeight.w500,
                                      color: table[i].key == 'player'
                                          ? p.gold
                                          : p.text,
                                    ),
                                  ),
                                ),
                                Text(l10n.points(table[i].value)),
                              ],
                            ),
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
