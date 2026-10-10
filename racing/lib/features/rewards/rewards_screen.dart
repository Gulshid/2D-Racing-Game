import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/app/router.dart';
import 'package:racing/data/models/progression_config.dart';
import 'package:racing/features/progress/coins_badge.dart';
import 'package:racing/features/providers/progress_provider.dart';
import 'package:racing/l10n/app_localizations.dart';
import 'package:racing/l10n/l10n_names.dart';

/// Daily login reward, today's challenge, lifetime stats and achievements.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);
    final now = DateTime.now();
    final save = progress.save;
    final kind = DailyKind.today(now);
    final value = notifier.challengeProgress(now);
    final challengeDone = value >= kind.target;
    final claimed = notifier.isChallengeClaimed(now);

    return ScreenFrame(
      title: l10n.rewards,
      onBack: () => context.go(AppRoutes.menu),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: ListView(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    const CoinsBadge(),
                  ],
                ),
                const SizedBox(height: AppSpace.s),
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.dailyReward,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              notifier.canClaimLogin(now)
                                  ? l10n.dailyRewardReady
                                  : l10n.dailyRewardDone,
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (save.daily.streak > 0)
                              Text(
                                l10n.dailyStreak(save.daily.streak),
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        child: AppButton(
                          label: l10n.claim,
                          icon: Icons.card_giftcard,
                          onPressed: notifier.canClaimLogin(now)
                              ? () => notifier.claimLoginReward(now)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.m),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dailyChallenge,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(switch (kind) {
                        DailyKind.drifts => l10n.challengeDrifts(kind.target),
                        DailyKind.cleanLaps =>
                          l10n.challengeCleanLaps(kind.target),
                        DailyKind.finishes =>
                          l10n.challengeFinishes(kind.target),
                      }),
                      const SizedBox(height: AppSpace.s),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (value / kind.target).clamp(0.0, 1.0).toDouble(),
                          minHeight: 8,
                          backgroundColor: AppPalette.of(context).border,
                          color: AppPalette.of(context).accent,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.progressOf(
                                value.clamp(0, kind.target).toInt(),
                                kind.target,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: AppButton(
                              label: claimed ? l10n.claimed : l10n.claim,
                              icon: Icons.emoji_events,
                              onPressed: (challengeDone && !claimed)
                                  ? () => notifier.claimChallenge(now)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SectionLabel(l10n.statsRaces),
                AppCard(
                  child: Wrap(
                    spacing: AppSpace.xl,
                    runSpacing: AppSpace.s,
                    children: [
                      _Stat(l10n.statsRaces, '${save.stats.racesPlayed}'),
                      _Stat(l10n.statsWins, '${save.stats.wins}'),
                      _Stat(l10n.statsPodiums, '${save.stats.podiums}'),
                      _Stat(l10n.statsDrifts, '${save.stats.drifts}'),
                      _Stat(l10n.statsCleanLaps, '${save.stats.cleanLaps}'),
                      _Stat(l10n.statsCoinsEarned, '${save.stats.coinsEarned}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.l),
          Expanded(
            flex: 4,
            child: ListView(
              children: [
                SectionLabel(l10n.achievements),
                for (final a in Achievements.all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s),
                    child: AppCard(
                      selected: save.achievements.contains(a.id),
                      child: Row(
                        children: [
                          Icon(
                            save.achievements.contains(a.id)
                                ? Icons.emoji_events
                                : Icons.lock_outline,
                            color: save.achievements.contains(a.id)
                                ? AppPalette.of(context).gold
                                : AppPalette.of(context).textMuted,
                          ),
                          const SizedBox(width: AppSpace.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  achievementTitle(l10n, a.id),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  achievementDescription(l10n, a.id),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+${a.reward}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: p.textMuted)),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
