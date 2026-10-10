import 'package:go_router/go_router.dart';
import 'package:racing/app/design/app_widgets.dart';
import 'package:racing/core/constants/game_config.dart';
import 'package:racing/data/models/ai_profile.dart';
import 'package:racing/data/tracks/track_library.dart';
import 'package:racing/features/car_select/car_select_screen.dart';
import 'package:racing/features/menu/menu_screen.dart';
import 'package:racing/features/race/race_screen.dart';
import 'package:racing/features/settings/settings_screen.dart';
import 'package:racing/features/splash/splash_screen.dart';
import 'package:racing/features/track_select/track_select_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const menu = '/menu';
  static const tracks = '/tracks';
  static const cars = '/cars';
  static const settings = '/settings';
  static const race = '/race';

  /// Builds the race URL:
  /// /race?track=<id>&car=<index>&diff=<0..2>&ai=<0..6>
  static String raceUrl({
    required String trackId,
    required int carIndex,
    AiDifficulty difficulty = AiDifficulty.medium,
    int aiCount = GameConfig.aiDefaultOpponents,
  }) =>
      Uri(
        path: race,
        queryParameters: {
          'track': trackId,
          'car': '$carIndex',
          'diff': '${difficulty.index}',
          'ai': '$aiCount',
        },
      ).toString();
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => slideFadePage(
        key: state.pageKey,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.menu,
      pageBuilder: (context, state) => slideFadePage(
        key: state.pageKey,
        child: const MenuScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.tracks,
      pageBuilder: (context, state) => slideFadePage(
        key: state.pageKey,
        child: const TrackSelectScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.cars,
      pageBuilder: (context, state) => slideFadePage(
        key: state.pageKey,
        child: const CarSelectScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) => slideFadePage(
        key: state.pageKey,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.race,
      pageBuilder: (context, state) {
        final q = state.uri.queryParameters;
        return slideFadePage(
          key: state.pageKey,
          child: RaceScreen(
            trackId: q['track'] ?? TrackLibrary.all.first.id,
            carIndex: int.tryParse(q['car'] ?? '') ?? 0,
            difficulty:
                AiDifficulty.fromIndex(int.tryParse(q['diff'] ?? '') ?? 1),
            aiCount: (int.tryParse(q['ai'] ?? '') ??
                    GameConfig.aiDefaultOpponents)
                .clamp(0, GameConfig.aiMaxOpponents)
                .toInt(),
          ),
        );
      },
    ),
  ],
);
