import 'package:flutter/material.dart';
import 'package:sc2_leaderboards/app/widgets/app_scaffold.dart';

class Challenges extends StatelessWidget {
  const Challenges({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text("Scion Challenges")),
      body: ListView(),
    );
  }
}
