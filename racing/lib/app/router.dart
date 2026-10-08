import 'package:go_router/go_router.dart';
import 'package:racing_game/features/menu/menu_screen.dart';
import 'package:racing_game/features/race/race_screen.dart';
import 'package:racing_game/features/splash/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const menu = '/menu';
  static const race = '/race';
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
      path: AppRoutes.race,
      builder: (context, state) => const RaceScreen(),
    ),
  ],
);
