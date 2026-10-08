import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:racing/game/overlays/minimap.dart';
import 'package:racing/game/racing_game.dart';
import 'package:racing/game/systems/hud_state.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({required this.game, super.key});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Minimap (top-left, below the FPS counter)
          Positioned(
            left: 4,
            top: 30,
            child: SizedBox(
              width: 130,
              height: 86,
              child: CustomPaint(
                painter: MinimapPainter(
                  map: game.track,
                  carPosition: () => game.car.physics.position,
                  repaint: game.minimapTick,
                ),
              ),
            ),
          ),
          // Pause + tuning buttons (top-right)
          Positioned(
            right: 4,
            top: 4,
            child: Row(
              children: [
                if (kDebugMode) ...[
                  IconButton.filledTonal(
                    onPressed: game.toggleTuning,
                    icon: const Icon(Icons.tune),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton.filled(
                  onPressed: game.pauseGame,
                  icon: const Icon(Icons.pause),
                ),
              ],
            ),
          ),
          // Speedometer (bottom-center)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ValueListenableBuilder<HudState>(
                valueListenable: game.hud,
                builder: (context, s, _) => _Speedometer(state: s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Speedometer extends StatelessWidget {
  const _Speedometer({required this.state});

  final HudState state;

  static const _shadow = [Shadow(blurRadius: 6, color: Colors.black87)];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          state.drifting ? 'DRIFT' : ' ',
          style: const TextStyle(
            color: Color(0xFFFFC107),
            fontWeight: FontWeight.w900,
            fontSize: 14,
            shadows: _shadow,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${state.speedKmh}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                shadows: _shadow,
              ),
            ),
            const SizedBox(width: 4),
            const Text('km/h', style: TextStyle(fontSize: 12, shadows: _shadow)),
          ],
        ),
        SizedBox(
          width: 150,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.nitro,
              minHeight: 7,
              backgroundColor: Colors.black45,
              color: state.nitroActive
                  ? const Color(0xFFFFC107)
                  : const Color(0xFF29B6F6),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          state.surface.label,
          style: const TextStyle(fontSize: 11, shadows: _shadow),
        ),
      ],
    );
  }
}
