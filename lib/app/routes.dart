import 'package:go_router/go_router.dart';
import 'package:sc2_leaderboards/leaderboards/pages/leaderboard.dart';
import 'package:sc2_leaderboards/leaderboards/pages/matches.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      name: 'leaderboard',
      path: Leaderboard.route,
      builder: (context, state) => const Leaderboard(),
      routes: [
        GoRoute(
          name: 'matches',
          path: Matches.route.substring(Leaderboard.route.length),
          builder: (context, state) => const Matches(),
        ),
        GoRoute(
          name: Matches.profileRouteName,
          path:
              '${Matches.route.substring(Leaderboard.route.length)}/:profileId',
          builder: (context, state) {
            final profile = state.pathParameters['profileId']!;
            return Matches(
              playerId: profile,
            );
          },
        ),
      ],
    ),
  ],
);
