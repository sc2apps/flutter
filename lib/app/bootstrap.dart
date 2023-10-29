import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sc2_leaderboards/app/app.dart';
import 'package:sc2_leaderboards/firebase_options.dart';

Future<void> bootstrap() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Implement argument and only use emulators in main_dev.dart
  // FirebaseFirestore.instance.useFirestoreEmulator("localhost", 8080);

  runApp(const ProviderScope(
    child: SCLeaderboardsApp(),
  ));
}
