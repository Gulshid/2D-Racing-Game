import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:racing/data/models/app_settings.dart';
import 'package:racing/game/racing_game.dart';
import 'package:racing/game/systems/input_controller.dart';
import 'package:racing/game/systems/tilt_steering.dart';

/// On-screen driving controls. The layout follows the Control scheme setting:
///  - Buttons: left and right steer buttons.
///  - Wheel: a drag-able steering wheel.
///  - Tilt: tilt the phone to steer, with a live bar and a Centre button.
/// Pedals, nitro and drift are the same in both layouts. Each button is its
/// own Listener, so several can be held at once.
class TouchControlsOverlay extends StatelessWidget {
  const TouchControlsOverlay({required this.game, super.key});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    final t = game.input.touch;
    final scheme = game.controlScheme;
    return SafeArea(
      minimum: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: scheme == ControlScheme.tilt
                ? _TiltPanel(tilt: game.tilt)
                : scheme == ControlScheme.wheel
                ? _SteeringWheel(onSteer: (v) => t.analog = v)
                : Row(
                    children: [
                      HoldButton(
                        icon: Icons.arrow_back_ios_new,
                        size: 88,
                        onChanged: (v) => t.left = v,
                      ),
                      const SizedBox(width: 14),
                      HoldButton(
                        icon: Icons.arrow_forward_ios,
                        size: 88,
                        onChanged: (v) => t.right = v,
                      ),
                    ],
                  ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _Pedals(t: t),
          ),
        ],
      ),
    );
  }
}

class _Pedals extends StatelessWidget {
  const _Pedals({required this.t});

  final InputSource t;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HoldButton(
              icon: Icons.bolt,
              label: 'NITRO',
              size: 62,
              onChanged: (v) => t.nitroOn = v,
            ),
            const SizedBox(width: 12),
            HoldButton(
              icon: Icons.sync_alt,
              label: 'DRIFT',
              size: 62,
              onChanged: (v) => t.handbrakeOn = v,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HoldButton(
              icon: Icons.stop_rounded,
              label: 'BRAKE',
              size: 74,
              onChanged: (v) => t.brakePedal = v,
            ),
            const SizedBox(width: 12),
            HoldButton(
              icon: Icons.keyboard_double_arrow_up,
              label: 'GAS',
              size: 100,
              onChanged: (v) => t.gas = v,
            ),
          ],
        ),
      ],
    );
  }
}

/// Steering wheel you drag left and right. It turns with your finger and
/// springs back to centre when released. Steering is the wheel's angle, so a
/// half turn gives half lock.
class _SteeringWheel extends StatefulWidget {
  const _SteeringWheel({required this.onSteer});

  final ValueChanged<double> onSteer;

  @override
  State<_SteeringWheel> createState() => _SteeringWheelState();
}

class _SteeringWheelState extends State<_SteeringWheel> {
  /// Full lock of the on-screen wheel, in radians (about 140 degrees).
  static const double _lock = 2.45;
  static const double _size = 150;

  double _steer = 0;

  void _set(double v) {
    if (v == _steer) return;
    setState(() => _steer = v);
    widget.onSteer(v);
  }

  void _drag(Offset local) {
    const c = _size / 2;
    final dx = local.dx - c;
    final dy = local.dy - c;
    // Ignore touches right at the hub: the angle there is unreliable.
    if (dx * dx + dy * dy < 20 * 20) return;
    final angle = math.atan2(dx, -dy);
    _set((angle / _lock).clamp(-1.0, 1.0).toDouble());
  }

  @override
  void dispose() {
    widget.onSteer(0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => _drag(d.localPosition),
      onPanUpdate: (d) => _drag(d.localPosition),
      onPanEnd: (_) => _set(0),
      onPanCancel: () => _set(0),
      child: SizedBox(
        width: _size,
        height: _size,
        child: CustomPaint(painter: _WheelPainter(_steer * _lock)),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.angle);

  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = const Color(0xAA1B1F27);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xCCFFFFFF);
    final spoke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xCCFF5A1F);
    final hub = Paint()..color = const Color(0xCC1B1F27);
    final mark = Paint()..color = const Color(0xFFFFFFFF);

    canvas
      ..drawCircle(c, r, ring)
      ..drawCircle(c, r, rim)
      ..save()
      ..translate(c.dx, c.dy)
      ..rotate(angle);
    // Three spokes: one at the top (the reference mark) and two low ones.
    canvas
      ..drawLine(Offset.zero, Offset(0, -r + 6), spoke)
      ..drawLine(Offset.zero, Offset(-r * 0.7, r * 0.45), spoke)
      ..drawLine(Offset.zero, Offset(r * 0.7, r * 0.45), spoke)
      ..drawCircle(Offset.zero, 18, hub)
      ..drawCircle(Offset(0, -r + 12), 4, mark)
      ..restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.angle != angle;
}

class HoldButton extends StatefulWidget {
  const HoldButton({
    required this.icon,
    required this.onChanged,
    this.size = 72,
    this.label,
    super.key,
  });

  final IconData icon;
  final String? label;
  final double size;
  final ValueChanged<bool> onChanged;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  bool _down = false;

  void _set(bool value) {
    if (_down == value) return;
    setState(() => _down = value);
    widget.onChanged(value);
  }

  @override
  void dispose() {
    if (_down) widget.onChanged(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _down ? const Color(0xCCFF5A1F) : const Color(0x55FFFFFF),
          border: Border.all(color: const Color(0x99FFFFFF), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: widget.size * 0.4, color: Colors.white),
            if (widget.label != null)
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tilt steering panel: live steering bar, status, and a Centre button that
/// makes the phone's current angle the new "straight".
class _TiltPanel extends StatelessWidget {
  const _TiltPanel({required this.tilt});

  final TiltSteering tilt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: tilt.hasData,
            builder: (context, ok, _) => Text(
              ok
                  ? 'Tilt the phone to steer'
                  : 'No motion sensor data (test on a real phone)',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: tilt.steer,
            builder: (context, v, _) => Container(
              width: 160,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0x55FFFFFF),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Align(
                alignment: Alignment(v.clamp(-1.0, 1.0).toDouble(), 0),
                child: Container(
                  width: 16,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A1F),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: OutlinedButton.icon(
              onPressed: tilt.recalibrate,
              icon: const Icon(Icons.center_focus_strong, size: 16),
              label: const Text('CENTRE', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}
