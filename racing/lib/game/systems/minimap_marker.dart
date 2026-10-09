import 'dart:ui';

import 'package:flame/extensions.dart';

/// A coloured dot on the minimap. [position] is a live vector that the car
/// updates in place, so the minimap always shows the current position.
class MinimapMarker {
  const MinimapMarker(this.position, this.color);

  final Vector2 position;
  final Color color;
}
