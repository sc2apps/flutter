import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sc2_leaderboards/leaderboards/pages/matches.dart';
import 'package:sc2_leaderboards/players/models/player.dart';
import 'package:sc2_leaderboards/players/services/players.dart';

enum PlayerRank {
  gm('Grandmaster', 1),
  master('Master', 9),
  diam('Diamond', 20),
  plat('Platinum', 25),
  gold('Gold', 25),
  silver('Silver', 15),
  bronze('Bronze', 5 + 100);

  final String name;
  final int percentage;
  String get token => toString().split('.').last;

  const PlayerRank(this.name, this.percentage);
}

class Leaderboard extends StatefulWidget {
  static const String route = '/';

  const Leaderboard({super.key});

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  StreamSubscription? sub;

  bool showArchon = false;
  bool showMonth = true;

  List<Player> players = [];

  @override
  void initState() {
    setupSubscription();
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  void setupSubscription() {
    final now = DateTime.now().toUtc();
    final thisMonth = DateTime.utc(now.year, now.month, 1);
    final playerCol = showMonth
        ? playersCollection.where('lastMatchAt',
            isGreaterThanOrEqualTo: thisMonth.toIso8601String())
        : playersCollection;

    sub?.cancel();
    sub = playerCol.snapshots().listen((event) {
      players = event.docs.map((d) => d.data()).toList()
        ..sort((a, b) => b.elo.compareTo(a.elo));
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlayers = showArchon
        ? players
        : players.where((p) => !p.name.contains(',')).toList();
    Map<PlayerRank, List<Player>> playersByRank = {};
    int currentIndex = 0;

    for (final rank in PlayerRank.values) {
      final ratio = rank.percentage / 100.0;
      final count = max<int>((ratio * filteredPlayers.length).round(), 1);
      if (currentIndex >= filteredPlayers.length) {
        playersByRank[rank] = [];
        continue;
      }

      playersByRank[rank] = filteredPlayers.sublist(
        currentIndex,
        min(currentIndex + count, filteredPlayers.length),
      );
      currentIndex += count;
    }
    int playerRank = 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SC2 Leaderboard - Scion"),
        actions: [
          IconButton(
            onPressed: () {
              showMonth = !showMonth;
              setState(() {});
              setupSubscription();
            },
            tooltip: showMonth ? "Showing This Month" : "Showing All Players",
            icon: Icon(showMonth ? Icons.calendar_month : Icons.all_inclusive,
                color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              showArchon = !showArchon;
              setState(() {});
            },
            tooltip: showArchon ? "Showing Archon Teams" : "Showing 1v1 only",
            icon: Icon(showArchon ? Icons.group : Icons.group_off,
                color: Colors.white),
          ),
          IconButton(
            tooltip: "Match History",
            onPressed: () {
              context.go(Matches.route);
            },
            icon: const Icon(Icons.history, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        children: [
          for (final rank in PlayerRank.values) ...[
            Card(
              margin: EdgeInsets.zero,
              shape:
                  const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              child: ListTile(
                leading: Image.asset('assets/ranks/${rank.token}.png'),
                title: Text(rank.name),
              ),
            ),
            for (final player in playersByRank[rank]!)
              ListTile(
                visualDensity: VisualDensity.comfortable,
                leading: SizedBox(
                  width: 32,
                  height: 96,
                  child: Center(
                    child: Text(
                      "${playerRank++}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: switch (playerRank - 1) {
                          1 => 48,
                          2 => 38,
                          3 => 32,
                          4 => 28,
                          5 => 24,
                          _ => 20,
                        },
                      ),
                    ),
                  ),
                ),
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(player.name),
                    onPressed: () {
                      context.goNamed(
                        Matches.profileRouteName,
                        pathParameters: {'profileId': player.identifier},
                      );
                    },
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  child: SelectableText(
                    player.elo.toStringAsFixed(1),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
