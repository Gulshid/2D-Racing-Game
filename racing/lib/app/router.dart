import 'package:go_router/go_router.dart';
import 'package:racing/data/tracks/track_library.dart';
import 'package:racing/features/menu/menu_screen.dart';
import 'package:racing/features/race/race_screen.dart';
import 'package:racing/features/setup/race_setup_screen.dart';
import 'package:racing/features/splash/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const menu = '/menu';
  static const setup = '/setup';
  static const race = '/race';

  /// Builds the race URL: /race?track=<id>&car=<index>
  static String raceUrl({required String trackId, required int carIndex}) =>
      Uri(
        path: race,
        queryParameters: {'track': trackId, 'car': '$carIndex'},
      ).toString();
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.menu,
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: AppRoutes.setup,
      builder: (context, state) => const RaceSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.race,
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return RaceScreen(
          trackId: q['track'] ?? TrackLibrary.all.first.id,
          carIndex: int.tryParse(q['car'] ?? '') ?? 0,
        );
      },
    ),
  ],
);
