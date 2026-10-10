import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/scheduler.dart';

/// Summary of recent frames.
class FrameStats {
  const FrameStats({
    required this.frames,
    required this.avgMs,
    required this.p95Ms,
    required this.worstMs,
  });

  static const empty = FrameStats(frames: 0, avgMs: 0, p95Ms: 0, worstMs: 0);

  final int frames;
  final double avgMs;
  final double p95Ms;
  final double worstMs;

  double get fps => avgMs <= 0 ? 0 : 1000 / avgMs;
}

/// Records real frame times (build plus raster) from Flutter's own frame
/// timings. These are the numbers the phone actually spends per frame, so
/// they work in profile and release builds too.
///
/// Stores the last [capacity] frames in a fixed buffer, so it never grows.
class FrameMonitor {
  FrameMonitor({this.capacity = 600}) : _ring = Float64List(capacity);

  final int capacity;
  final Float64List _ring;
  int _count = 0;
  int _head = 0;
  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  /// Must be called when the race ends, or the callback keeps running.
  void detach() {
    if (!_attached) return;
    _attached = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  void clear() {
    _count = 0;
    _head = 0;
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final ms = (t.buildDuration + t.rasterDuration).inMicroseconds / 1000;
      _ring[_head] = ms;
      _head = (_head + 1) % capacity;
      if (_count < capacity) _count++;
    }
  }

  /// Averages and percentiles over the stored frames. Cheap enough to call
  /// a few times a second; it is not meant to run every frame.
  FrameStats snapshot() {
    if (_count == 0) return FrameStats.empty;
    final sorted = List<double>.generate(_count, (i) => _ring[i]);
    sorted.sort();
    var sum = 0.0;
    for (final v in sorted) {
      sum += v;
    }
    return FrameStats(
      frames: _count,
      avgMs: sum / _count,
      p95Ms: sorted[((_count - 1) * 0.95).round()],
      worstMs: sorted.last,
    );
  }
}
