import 'package:flutter/material.dart';
import 'package:sc2_leaderboards/app/routes.dart';

class SCLeaderboardsApp extends StatelessWidget {
  const SCLeaderboardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(),
        fontFamily: 'Michroma',
      ),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
