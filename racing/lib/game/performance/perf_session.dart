import 'dart:io';

import 'package:racing/data/models/app_settings.dart';
import 'package:racing/game/performance/frame_monitor.dart';

/// A timed test run. Start it, play for [seconds], and a text report is
/// returned. Used for the before/after numbers in the performance notes.
///
/// Reports are plain text with the prefix "PERF", so they are easy to find
/// in the console (filter by PERF).
class PerfSession {
  PerfSession({this.seconds = 30});

  final double seconds;

  bool _active = false;
  bool get isRecording => _active;

  late FrameMonitor _frames;
  String _label = '';
  GraphicsQuality _startQuality = GraphicsQuality.high;
  GraphicsQuality _quality = GraphicsQuality.high;
  double _elapsed = 0;
  double _aiSum = 0;
  double _aiWorst = 0;
  int _aiSamples = 0;
  int _rssStartMb = -1;
  final List<String> _events = [];

  void start({
    required String label,
    required GraphicsQuality quality,
    required FrameMonitor frames,
  }) {
    _active = true;
    _label = label;
    _startQuality = quality;
    _quality = quality;
    _frames = frames..clear();
    _elapsed = 0;
    _aiSum = 0;
    _aiWorst = 0;
    _aiSamples = 0;
    _events.clear();
    _rssStartMb = _rssMb();
  }

  void noteQualityChange(GraphicsQuality q) {
    _quality = q;
    _events.add('t=${_elapsed.toStringAsFixed(1)}s quality -> ${q.name}');
  }

  /// Call every frame while recording. Returns the report when the run ends.
  String? tick({
    required double dt,
    required double aiMs,
    required GraphicsQuality quality,
  }) {
    if (!_active) return null;
    _elapsed += dt;
    _aiSum += aiMs;
    _aiSamples++;
    if (aiMs > _aiWorst) _aiWorst = aiMs;
    if (quality != _quality) noteQualityChange(quality);
    if (_elapsed < seconds) return null;
    return stop();
  }

  /// Ends the run early and returns its report (or null if not recording).
  String? stop() {
    if (!_active) return null;
    _active = false;
    final s = _frames.snapshot();
    final aiAvg = _aiSamples == 0 ? 0 : _aiSum / _aiSamples;
    final rssEnd = _rssMb();
    final buffer = StringBuffer()
      ..writeln('PERF REPORT  track=$_label  seconds=${_elapsed.toStringAsFixed(1)}')
      ..writeln('PERF quality start=${_startQuality.name} end=${_quality.name}')
      ..writeln('PERF frames=${s.frames} avg=${s.avgMs.toStringAsFixed(2)}ms '
          'fps=${s.fps.toStringAsFixed(1)} p95=${s.p95Ms.toStringAsFixed(2)}ms '
          'worst=${s.worstMs.toStringAsFixed(2)}ms')
      ..writeln('PERF ai avg=${aiAvg.toStringAsFixed(3)}ms '
          'worst=${_aiWorst.toStringAsFixed(3)}ms (budget 2 ms)')
      ..writeln('PERF memory rss start=${_rssStartMb}MB end=${rssEnd}MB');
    for (final e in _events) {
      buffer.writeln('PERF event $e');
    }
    return buffer.toString();
  }

  static int _rssMb() {
    try {
      return (ProcessInfo.currentRss / (1024 * 1024)).round();
    } catch (_) {
      return -1;
    }
  }
}
