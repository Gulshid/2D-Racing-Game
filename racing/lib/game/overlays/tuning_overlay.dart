import 'package:flutter/material.dart';
import 'package:racing/data/models/car_stats.dart';
import 'package:racing/game/racing_game.dart';

/// Debug panel: change car handling live while driving.
class TuningOverlay extends StatefulWidget {
  const TuningOverlay({required this.game, super.key});

  final RacingGame game;

  @override
  State<TuningOverlay> createState() => _TuningOverlayState();
}

class _TuningOverlayState extends State<TuningOverlay> {
  CarStats get _s => widget.game.car.physics.stats;

  void _apply(CarStats next) {
    setState(() => widget.game.car.physics.stats = next);
  }

  Widget _row(
    String label,
    double value,
    double min,
    double max,
    CarStats Function(double) update,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(fontSize: 11)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min,
              max: max,
              onChanged: (v) => _apply(update(v)),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(value < 10 ? 2 : 0),
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 78),
          child: Container(
            width: 320,
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xDD0B1F3A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TUNING - ${s.name}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  _row('Max speed', s.maxSpeed, 200, 900,
                      (v) => s.copyWith(maxSpeed: v)),
                  _row('Acceleration', s.acceleration, 80, 500,
                      (v) => s.copyWith(acceleration: v)),
                  _row('Steering', s.steering, 1, 4,
                      (v) => s.copyWith(steering: v)),
                  _row('Grip', s.grip, 2, 16, (v) => s.copyWith(grip: v)),
                  _row('Drift (handbrk)', s.driftFactor, 0.05, 1,
                      (v) => s.copyWith(driftFactor: v)),
                  _row('Slide tendency', s.slideTendency, 0, 0.8,
                      (v) => s.copyWith(slideTendency: v)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
