import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/surface_type.dart';
import 'package:racing/data/tracks/track_library.dart';
import 'package:racing/game/components/track/track_map.dart';

void main() {
  for (final data in TrackLibrary.all) {
    group(data.name, () {
      final map = TrackMap(data);

      test('has a sensible length and sample count', () {
        expect(map.count, greaterThan(100));
        expect(map.length, greaterThan(4000));
      });

      test('spawn point is on plain asphalt', () {
        final spawn = map.spawn(0);
        expect(map.query(spawn.position).surface, SurfaceType.asphalt);
      });

      test('center of road is asphalt or a defined zone', () {
        for (var i = 0; i < map.count; i += 10) {
          final q = map.query(map.points[i]);
          expect(q.distance, lessThan(1));
          expect(q.distance, lessThan(map.halfWidth));
        }
      });

      test('curb and off-road are detected', () {
        final c = map.points[0];
        final n = map.normals[0];
        final curbPoint = Vector2(
          c.x + n.x * (map.halfWidth + GameConfig.curbWidth / 2),
          c.y + n.y * (map.halfWidth + GameConfig.curbWidth / 2),
        );
        final farPoint = Vector2(
          c.x + n.x * (map.halfWidth + GameConfig.curbWidth + 100),
          c.y + n.y * (map.halfWidth + GameConfig.curbWidth + 100),
        );
        expect(map.query(curbPoint).surface, SurfaceType.curb);
        expect(map.query(farPoint).surface, data.theme.offRoad);
      });

      test('hinted query matches full search', () {
        for (var i = 0; i < map.count; i += 17) {
          final p = map.points[i];
          final full = map.query(p);
          final hinted = map.query(p, hint: (i + 5) % map.count);
          expect(hinted.distance, closeTo(full.distance, 1e-6));
        }
      });

      test('different parts of the road never overlap', () {
        final minGap = data.roadWidth * 1.3;
        for (var i = 0; i < map.count; i += 3) {
          for (var j = i + 1; j < map.count; j += 3) {
            final along = map.cumulative[j] - map.cumulative[i];
            final arc = along < map.length - along ? along : map.length - along;
            if (arc > data.roadWidth * 3) {
              expect(
                map.points[i].distanceTo(map.points[j]),
                greaterThan(minGap),
              );
            }
          }
        }
      });
    });
  }

  test('progress increases along the track', () {
    final map = TrackMap(TrackLibrary.oval);
    final a = map.query(map.points[20]).progress;
    final b = map.query(map.points[80]).progress;
    expect(b, greaterThan(a));
  });
}
