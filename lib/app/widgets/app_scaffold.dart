import 'package:flag/flag_enum.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sc2_leaderboards/app/state/region.dart';
import 'package:sc2_leaderboards/leaderboards/pages/leaderboard.dart';

class AppScaffold extends ConsumerWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  const AppScaffold({super.key, this.appBar, required this.body});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final region = ref.watch(regionNotifierProvider);
    return Scaffold(
      appBar: appBar,
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(color: Colors.black),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "SC2 Leaderboards",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RegionButton(
                          selected: region == 1,
                          flag: FlagsCode.US,
                          onPressed: () {
                            ref
                                .read(regionNotifierProvider.notifier)
                                .chooseRegion(1);
                          },
                        ),
                        RegionButton(
                          selected: region == 2,
                          flag: FlagsCode.EU,
                          onPressed: () {
                            ref
                                .read(regionNotifierProvider.notifier)
                                .chooseRegion(2);
                          },
                        ),
                        RegionButton(
                          selected: region == 3,
                          flag: FlagsCode.KR,
                          onPressed: () {
                            ref
                                .read(regionNotifierProvider.notifier)
                                .chooseRegion(3);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              title: const Text("Leaderboard"),
              onTap: () {
                context.go(Leaderboard.route);
              },
            ),
            ListTile(
              title: const Text("Challenges"),
              onTap: () {
                // context.go(Challenges.route);
              },
            ),
          ],
        ),
      ),
      body: body,
    );
  }
}

class RegionButton extends StatelessWidget {
  final bool selected;
  final FlagsCode flag;
  final VoidCallback onPressed;

  const RegionButton({
    super.key,
    required this.onPressed,
    required this.selected,
    required this.flag,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 32,
        splashRadius: 24,
        icon: Container(
          //   padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.blue : Colors.transparent,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(25.0),
          ),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            child: Flag.fromCode(
              flag,
              height: 48,
              width: 48,
              fit: BoxFit.cover,
              borderRadius: 0,
            ),
          ),
        ),
      ),
    );
  }
}
