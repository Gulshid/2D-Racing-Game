import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/router.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/ai_profile.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/data/models/track_data.dart';
import 'package:racing/data/tracks/track_library.dart';
import 'package:racing/game/components/track/track_map.dart';
import 'package:racing/game/overlays/minimap.dart';

/// Pick a track and a car, then start the race.
class RaceSetupScreen extends StatefulWidget {
  const RaceSetupScreen({super.key});

  @override
  State<RaceSetupScreen> createState() => _RaceSetupScreenState();
}

class _RaceSetupScreenState extends State<RaceSetupScreen> {
  int _track = 0;
  int _car = 0;
  AiDifficulty _difficulty = AiDifficulty.medium;
  int _opponents = GameConfig.aiDefaultOpponents;

  late final List<TrackMap> _maps =
      TrackLibrary.all.map(TrackMap.new).toList();

  static const _accent = Color(0xFFFF5A1F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.menu),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Text(
                    'RACE SETUP',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => context.go(
                      AppRoutes.raceUrl(
                        trackId: TrackLibrary.all[_track].id,
                        carIndex: _car,
                        difficulty: _difficulty,
                        aiCount: _opponents,
                      ),
                    ),
                    icon: const Icon(Icons.flag),
                    label: const Text('START RACE'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const _Label('TRACK'),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: TrackLibrary.all.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _TrackCard(
                    data: TrackLibrary.all[i],
                    map: _maps[i],
                    selected: i == _track,
                    onTap: () => setState(() => _track = i),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _Label('CAR'),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: CarPresets.all.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _CarCard(
                    stats: CarPresets.all[i],
                    selected: i == _car,
                    onTap: () => setState(() => _car = i),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _Label('OPPONENTS'),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SegmentedButton<AiDifficulty>(
                    showSelectedIcon: false,
                    segments: [
                      for (final d in AiDifficulty.values)
                        ButtonSegment(value: d, label: Text(d.label)),
                    ],
                    selected: {_difficulty},
                    onSelectionChanged: (v) =>
                        setState(() => _difficulty = v.first),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        onPressed: _opponents > 0
                            ? () => setState(() => _opponents--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 96,
                        child: Text(
                          _opponents == 1 ? '1 AI car' : '$_opponents AI cars',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _opponents < GameConfig.aiMaxOpponents
                            ? () => setState(() => _opponents++)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: Color(0xFFC9D3E3),
          ),
        ),
      );
}

BoxDecoration _cardDecoration({required bool selected}) => BoxDecoration(
      color: const Color(0xFF13294A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: selected ? _RaceSetupScreenState._accent : Colors.transparent,
        width: 2,
      ),
    );

class _TrackCard extends StatelessWidget {
  const _TrackCard({
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
    const difficulty = ['', 'Easy', 'Medium', 'Hard'];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(8),
        decoration: _cardDecoration(selected: selected),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 96,
              child: CustomPaint(painter: MinimapPainter(map: map)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.laps} laps  -  ${difficulty[data.difficulty]}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    'Par ${data.parTimeSeconds}s',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    '${(map.length / 1000).toStringAsFixed(1)} km road',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  const _CarCard({
    required this.stats,
    required this.selected,
    required this.onTap,
  });

  final CarStats stats;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(10),
        decoration: _cardDecoration(selected: selected),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 12,
                  decoration: BoxDecoration(
                    color: stats.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  stats.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StatBar('Speed', stats.maxSpeed / 700),
            _StatBar('Accel', stats.acceleration / 280),
            _StatBar('Handling', stats.steering / 3.2),
            _StatBar('Grip', stats.grip / 12),
          ],
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar(this.label, this.value);

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(label, style: const TextStyle(fontSize: 10)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value.clamp(0.05, 1.0).toDouble(),
              minHeight: 4,
              backgroundColor: Colors.white12,
              color: const Color(0xFFFF5A1F),
            ),
          ),
        ],
      ),
    );
  }
}
