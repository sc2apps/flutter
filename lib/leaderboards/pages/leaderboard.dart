import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sc2_leaderboards/app/state/region.dart';
import 'package:sc2_leaderboards/app/widgets/app_scaffold.dart';
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

class Leaderboard extends ConsumerStatefulWidget {
  static const String route = '/';

  const Leaderboard({super.key});

  @override
  ConsumerState<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends ConsumerState<Leaderboard> {
  StreamSubscription? sub;

  bool showArchon = false;
  bool showMonth = true;

  List<Player> players = [];

  @override
  void initState() {
    ref.listen(regionNotifierProvider, (prior, region) {
      setupSubscription(region);
    });
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  void setupSubscription(int region) {
    final now = DateTime.now().toUtc();
    final thisMonth = DateTime.utc(now.year, now.month, 1);
    final playerCol = (showMonth
        ? playersCollection.where('lastMatchAt',
            isGreaterThanOrEqualTo: thisMonth.toIso8601String())
        : playersCollection); //TODO: .where('') region;

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

    return AppScaffold(
      appBar: AppBar(
        title: const Text("SC2 Leaderboard - Scion"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SimpleDialog(
                  children: [
                    InfoContent(),
                  ],
                ),
              );
            },
          ),
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
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
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
                              < 100 => 20,
                              < 1000 => 16,
                              _ => 12,
                            },
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
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
                                pathParameters: {
                                  'profileId': player.identifier
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          child: SelectableText(
                            player.elo.toStringAsFixed(1),
                            // style: const TextStyle(fontFamily: 'Courier'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class InfoContent extends StatelessWidget {
  const InfoContent({super.key});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    const contentStyle = TextStyle(fontFamily: "Arial", fontSize: 16);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              "What is this?",
              style: titleStyle,
            ),
            const SizedBox(height: 4),
            const SelectableText(
              "This website is meant to give scion a bit of a ladder experience, and a way to estimate player's skills. Ideally, you can more easily find people of similar skill to play with, or conceptualize where people are at.\n",
              style: contentStyle,
            ),
            SelectableText(
              "How do I get ranked?",
              style: titleStyle,
            ),
            const SizedBox(height: 4),
            const SelectableText(
              "To start gaining MMR all you have to do is hit \"make public\" in your scion lobbies, this works even if you have already filled the lobby with friends or people you specifically wanted to 1v1.",
              style: contentStyle,
            ),
            const SelectableText(
              "Replays can also be manually imported, contact Chase in the scion discord: https://discord.gg/AAJ2TUFJHS\n",
              style: contentStyle,
            ),
            SelectableText(
              "How does MMR work?",
              style: titleStyle,
            ),
            const SizedBox(height: 4),
            const SelectableText(
              "Everyone starts at 2500 MMR.  If two players are 800 mmr apart the higher rated player is expected to win at a rate of 10:1, 1600 mmr would be 100:1, and the MMR awarded is based on those expectations.  If two players are of equal skill, the winner will get approximately 40 points but in a maximally extreme case the winner could get 80 points (because they were much lower rated), on the other extreme you could win 1 point. I'm using pyelo for a lot of this math, though I did fix a bug it had.",
              style: contentStyle,
            ),
          ],
        ),
      ),
    );
  }
}
