import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sc2_leaderboards/players/models/player.dart';

final playersCollection =
    FirebaseFirestore.instance.collection('players').withConverter(
          fromFirestore: (doc, opts) =>
              Player.fromJson(Map<String, Object?>.from(doc.data()!)),
          toFirestore: (p, opts) => Map<String, Object?>.from(p.toJson()),
        );
