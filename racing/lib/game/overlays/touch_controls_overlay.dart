import 'package:flutter/material.dart';
import 'package:racing/game/racing_game.dart';

/// On-screen steering, pedals, nitro and handbrake. Each button is an
/// independent Listener so several can be held at once (multi-touch).
class TouchControlsOverlay extends StatelessWidget {
  const TouchControlsOverlay({required this.game, super.key});

  final RacingGame game;

  @override
  Widget build(BuildContext context) {
    final t = game.input.touch;
    return SafeArea(
      minimum: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Row(
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
            child: Column(
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
            ),
          ),
        ],
      ),
    );
  }
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
