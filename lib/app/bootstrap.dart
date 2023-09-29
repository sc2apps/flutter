import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sc2_leaderboards/app/app.dart';
import 'package:sc2_leaderboards/firebase_options.dart';

Future<void> bootstrap() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SCLeaderboardsApp());
}
