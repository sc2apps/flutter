import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sc2_leaderboards/players/models/player.dart';
import 'package:sc2_leaderboards/players/services/players.dart';

class Matches extends StatefulWidget {
  static const String route = '/matches';
  static const String profileRouteName = 'profile_matches';

  final String? playerId;

  const Matches({super.key, this.playerId});

  @override
  State<Matches> createState() => _MatchesState();
}

class _MatchesState extends State<Matches> {
  // static final dateFormatter = DateFormat.MMMd().add_jm();
  static final dateFormatter = DateFormat('MMM d h:mm a');

  StreamSubscription? sub;
  StreamSubscription? profileSub;
  Player? profile;

  List<Map<String, dynamic>> matches = [];

  @override
  void initState() {
    var playerCol = FirebaseFirestore.instance
        .collection('matches')
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (widget.playerId != null) {
      playerCol = playerCol.where(
        'participants',
        arrayContains: widget.playerId,
      );
      profileSub =
          playersCollection.doc(widget.playerId).snapshots().listen((event) {
        profile = event.data();
      });
    }

    // .withConverter(
    //   fromFirestore: (doc, opts) =>
    //       Player.fromJson(Map<String, Object?>.from(doc.data()!)),
    //   toFirestore: (p, opts) => Map<String, Object?>.from(p.toJson()),
    // )

    sub = playerCol.snapshots().listen((event) {
      matches = event.docs
          .map((d) => d.data())
          .where((m) => m['match'] != null && m['match']['completedAt'] != null)
          .toList();
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    profileSub?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> playersFor(
      {required Map<String, dynamic> match, required bool winners}) {
    return List<Map<String, dynamic>>.from(
      match['match']['profileMatches']
          .where((pm) => pm['decision'] == (winners ? 'win' : 'loss'))
          .map((pm) => Map<String, dynamic>.from(pm['profile'])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text("SC2 Leaderboard - Scion Match History"),
      ),
      body: ListView(
        children: [
          if (profile != null) _buildProfile(context, profile),
          for (final match in matches) _buildMatchRow(context, match),
        ],
      ),
    );
  }

  double safeToDouble(dynamic val) {
    return switch (val) {
      String() => double.parse(val),
      double() => val,
      int() => val as double,
      _ => 0,
    };
  }

  String safeToString(dynamic val, {int fixed = 1}) {
    return safeToDouble(val).toStringAsFixed(fixed);
  }

  Widget _buildProfile(BuildContext context, Player profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile.name,
                style: Theme.of(context).textTheme.headlineMedium),
            Text(
              "Games: ${profile.numGames} Wins: ${profile.wins} Losses: ${profile.losses}",
            ),
            Text(
              "Upsets: ${profile.upsets} Been Upset: ${profile.beenUpset}",
            ),
          ],
        ),
      ),
    );
  }

  String durationToString(Duration d) {
    var str = "";
    if (d.inHours > 0) str = "${d.inHours}:";

    return str +
        ([d.inMinutes, d.inSeconds]
            .map((d) => d % 60)
            .map((d) => d < 10 ? '0$d' : d)
            .join(':'));
  }

  DateTime safeParseDate(dynamic date) {
    return switch (date) {
      Timestamp() => date.toDate(),
      String() => DateTime.parse(date),
      _ => DateTime.now()
    }
        .toLocal();
  }

  double eloAfter(Map<String, dynamic> match, bool winner) {
    final key = winner ? 'winnerMMR' : 'looserMMR';
    final changeKey = winner ? 'wonElo' : 'lostElo';

    final change = switch (match[changeKey]) {
      String() => int.parse(match[changeKey]),
      num() => match[changeKey],
      _ => winner ? 1 : -1
    };
    return (match[key] ?? 2500) + change;
  }

  Widget _buildMatchRow(BuildContext context, Map<String, dynamic> match) {
    final winners = playersFor(match: match, winners: true);
    final loosers = playersFor(match: match, winners: false);

    final time = safeParseDate(match['createdAt']);

    final duration = safeParseDate(match['match']['completedAt'])
        .difference(safeParseDate(match['closedAt']));

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: IntrinsicHeight(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match['map'] is String
                              ? match['map']
                              : match['map']['name'],
                        ),
                        Text(
                          dateFormatter.format(time),
                          style: TextStyle(
                            color: Colors.grey[400],
                          ),
                        ),
                        Text(
                          "Length: ${durationToString(duration)}",
                          style: TextStyle(
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildPlayerDetails(
                          winners,
                          elo: eloAfter(match, true),
                          eloChange: match['wonElo'] ?? 1,
                        ),
                        const Text('vs'),
                        _buildPlayerDetails(
                          loosers,
                          elo: eloAfter(match, false),
                          eloChange: match['lostElo'] ?? -1,
                          alignment: CrossAxisAlignment.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerDetails(
    List<Map<String, dynamic>> players, {
    required dynamic elo,
    required dynamic eloChange,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    final names = players.map((p) => p['name']).toList()..sort();
    final ids = players.map((p) => p['profileId']).toList()..sort();

    final playerName = "${names.join(', ')} (${safeToString(elo)})";
    final playerId = ids.join('-');

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: alignment,
        children: [
          const SizedBox(width: double.infinity),
          Align(
            alignment: alignment == CrossAxisAlignment.start
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 0,
                ),
              ),
              child: Text(
                playerName,
                textAlign: alignment == CrossAxisAlignment.start
                    ? TextAlign.start
                    : TextAlign.end,
              ),
              onPressed: () {
                context.goNamed(
                  Matches.profileRouteName,
                  pathParameters: {'profileId': playerId},
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "${safeToDouble(eloChange) > 0 ? 'Won' : 'Lost'} ${safeToString(eloChange)}",
              style: TextStyle(color: Colors.grey[500]),
              textAlign: alignment == CrossAxisAlignment.start
                  ? TextAlign.start
                  : TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
