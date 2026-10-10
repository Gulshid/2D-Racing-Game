import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racing/app/design/app_palette.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/core/utils/math_utils.dart';
import 'package:racing/core/utils/time_format.dart';
import 'package:racing/features/providers/settings_provider.dart';
import 'package:racing/game/overlays/minimap.dart';
import 'package:racing/game/racing_game.dart';
import 'package:racing/game/systems/hud_state.dart';
import 'package:racing/game/systems/race_hud_state.dart';
import 'package:racing/l10n/app_localizations.dart';

/// In-race HUD. Everything sits in the top and bottom bands, so the middle
/// of the screen (where the car is) stays clear. Only the countdown and the
/// wrong-way warning appear in the centre, and they never take touch input.
class HudOverlay extends ConsumerWidget {
  const HudOverlay({required this.game, super.key});

  final RacingGame game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cues = ref.watch(settingsProvider).colorblindIndicators;
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 6,
            child: HudPanel(
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                width: 130,
                height: 86,
                child: CustomPaint(
                  painter: MinimapPainter(
                    map: game.track,
                    carPosition: () => game.car.physics.position,
                    markers: game.minimapMarkers,
                    repaint: game.minimapTick,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _RaceInfo(game: game),
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: _TopButtons(game: game),
          ),
          Align(
            alignment: const Alignment(0, -0.35),
            child: _CentreBanner(game: game),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _Speedometer(game: game, cues: cues),
            ),
          ),
        ],
      ),
    );
  }
}

List<Shadow>? _shadowFor(AppPalette p) =>
    p.highContrast ? null : const [Shadow(blurRadius: 6, color: Colors.black87)];

class _TopButtons extends StatelessWidget {
  const _TopButtons({required this.game});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (kDebugMode) ...[
          _AiCostChip(game: game),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            tooltip: l10n.aiDebugTooltip,
            onPressed: game.toggleAiDebug,
            icon: const Icon(Icons.smart_toy),
          ),
          IconButton.filledTonal(
            onPressed: game.toggleTuning,
            icon: const Icon(Icons.tune),
          ),
          const SizedBox(width: 6),
        ],
        IconButton.filledTonal(
          tooltip: l10n.backOnRoad,
          onPressed: game.respawnPlayer,
          icon: const Icon(Icons.my_location),
        ),
        const SizedBox(width: 6),
        IconButton.filled(
          tooltip: l10n.pause,
          onPressed: game.pauseGame,
          icon: const Icon(Icons.pause),
        ),
      ],
    );
  }
}

/// Position, lap, coins and the race clock (top centre).
class _RaceInfo extends StatelessWidget {
  const _RaceInfo({required this.game});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppPalette.of(context);
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<RaceHudState>(
            valueListenable: game.raceHud,
            builder: (context, s, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Chip(l10n.hudLap(s.lap, s.totalLaps)),
                const SizedBox(width: 6),
                _Chip(l10n.hudPos(s.position, s.carCount), emphasis: true),
                const SizedBox(width: 6),
                _Chip(l10n.hudCoins(s.coins)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<RaceTiming>(
            valueListenable: game.timing,
            builder: (context, t, _) {
              final best = t.bestLap;
              final lapLine = best == null
                  ? l10n.hudLapTime(formatTime(t.lapTime))
                  : '${l10n.hudLapTime(formatTime(t.lapTime))}   '
                      '${l10n.hudBest(formatTime(best))}';
              return HudPanel(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatTime(t.totalTime),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        shadows: _shadowFor(p),
                      ),
                    ),
                    Text(lapLine, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.emphasis = false});

  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return HudPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: emphasis ? p.gold : p.text,
        ),
      ),
    );
  }
}

/// Countdown numbers and the wrong-way warning. Warning uses an icon and
/// words, so it does not depend on colour alone.
class _CentreBanner extends StatelessWidget {
  const _CentreBanner({required this.game});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppPalette.of(context);
    return IgnorePointer(
      child: ValueListenableBuilder<RaceHudState>(
        valueListenable: game.raceHud,
        builder: (context, s, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (s.label.isNotEmpty)
              Text(
                s.label,
                style: TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  color: p.gold,
                  shadows: _shadowFor(p),
                ),
              ),
            if (s.wrongWay)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: p.danger,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      l10n.wrongWay.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
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

/// Debug only: how many milliseconds per frame the AI uses.
class _AiCostChip extends StatelessWidget {
  const _AiCostChip({required this.game});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: game.aiCostMs,
      builder: (context, ms, _) => HudPanel(
        child: Text(
          'AI ${ms.toStringAsFixed(2)} ms',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// Speed gauge, nitro bar and surface name (bottom centre).
class _Speedometer extends StatelessWidget {
  const _Speedometer({required this.game, required this.cues});

  final RacingGame game;

  /// Extra icon cues for colour-blind players.
  final bool cues;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = AppPalette.of(context);
    final topKmh = game.carStats.maxSpeed * GameConfig.kmhPerUnit;
    return ValueListenableBuilder<HudState>(
      valueListenable: game.hud,
      builder: (context, s, _) {
        final fraction = clampD(s.speedKmh / topKmh, 0, 1);
        return HudPanel(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 14,
                child: Text(
                  s.drifting ? l10n.drift : '',
                  style: TextStyle(
                    color: p.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                height: 84,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CustomPaint(
                      size: const Size(170, 84),
                      painter: _GaugePainter(
                        fraction: fraction,
                        track: p.border,
                        fill: p.accent,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${s.speedKmh}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            shadows: _shadowFor(p),
                          ),
                        ),
                        Text(l10n.speedUnit, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cues && s.nitroActive) ...[
                    Icon(Icons.bolt, size: 16, color: p.gold),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    l10n.nitro,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.nitro,
                        minHeight: 8,
                        backgroundColor: p.border,
                        color: s.nitroActive ? p.gold : p.info,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                s.surface.label,
                style: TextStyle(fontSize: 11, color: p.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Half-circle gauge: grey track, coloured fill up to [fraction].
class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fraction,
    required this.track,
    required this.fill,
  });

  final double fraction;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2 - 10;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height - 6),
      radius: radius,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = track;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = fill;
    canvas
      ..drawArc(rect, math.pi, math.pi, false, base)
      ..drawArc(rect, math.pi, math.pi * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction || old.fill != fill || old.track != track;
}
