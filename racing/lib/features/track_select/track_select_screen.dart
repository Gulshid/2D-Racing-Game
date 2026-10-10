import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/app/router.dart';
import 'package:racing/core/utils/time_format.dart';
import 'package:racing/data/models/race_records.dart';
import 'package:racing/data/models/track_data.dart';
import 'package:racing/data/tracks/track_library.dart';
import 'package:racing/features/providers/race_setup_provider.dart';
import 'package:racing/game/components/track/track_map.dart';
import 'package:racing/game/overlays/minimap.dart';
import 'package:racing/l10n/app_localizations.dart';
import 'package:racing/l10n/l10n_names.dart';

/// Pick a track: list on the left, preview and best time on the right.
class TrackSelectScreen extends ConsumerStatefulWidget {
  const TrackSelectScreen({super.key});

  @override
  ConsumerState<TrackSelectScreen> createState() => _TrackSelectScreenState();
}

class _TrackSelectScreenState extends ConsumerState<TrackSelectScreen> {
  late final List<TrackMap> _maps =
      TrackLibrary.all.map(TrackMap.new).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final index = ref.watch(raceSetupProvider.select((s) => s.trackIndex));
    final track = TrackLibrary.all[index];
    final record = RaceRecords.of(track.id);

    return ScreenFrame(
      title: l10n.chooseTrack,
      onBack: () => context.go(AppRoutes.menu),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 340,
            child: ListView.separated(
              itemCount: TrackLibrary.all.length,
              separatorBuilder: (context, i) =>
                  const SizedBox(height: AppSpace.s),
              itemBuilder: (context, i) => _TrackTile(
                data: TrackLibrary.all[i],
                map: _maps[i],
                selected: i == index,
                onTap: () => ref.read(raceSetupProvider.notifier).selectTrack(i),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.l),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: AppCard(
                    semanticLabel: track.name,
                    child: SizedBox.expand(
                      child: CustomPaint(
                        painter: MinimapPainter(map: _maps[index]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.m),
                _Details(track: track, map: _maps[index], bestLap: record.bestLap),
                const SizedBox(height: AppSpace.m),
                AppButton(
                  label: l10n.next,
                  icon: Icons.arrow_forward,
                  onPressed: () => context.go(AppRoutes.cars),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.data,
    required this.map,
    required this.selected,
    required this.onTap,
  });

  final TrackData data;
  final TrackMap map;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      selected: selected,
      onTap: onTap,
      semanticLabel: data.name,
      padding: const EdgeInsets.all(AppSpace.s),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 64,
            child: CustomPaint(painter: MinimapPainter(map: map)),
          ),
          const SizedBox(width: AppSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.laps(data.laps)}  -  '
                  '${trackDifficultyName(l10n, data.difficulty)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.track,
    required this.map,
    required this.bestLap,
  });

  final TrackData track;
  final TrackMap map;
  final double? bestLap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppPalette.of(context);
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpace.l,
              runSpacing: AppSpace.xs,
              children: [
                Text(track.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    )),
                Text(l10n.laps(track.laps)),
                Text(l10n.parTime(track.parTimeSeconds)),
                Text(l10n.roadLength(
                  (map.length / 1000).toStringAsFixed(1),
                )),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.bestLap.toUpperCase(),
                style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: p.textMuted),
              ),
              Text(
                bestLap == null
                    ? l10n.bestLapNone
                    : formatTime(bestLap!),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: bestLap == null ? p.textMuted : p.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
