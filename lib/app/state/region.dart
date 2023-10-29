import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'region.g.dart';

@riverpod
class RegionNotifier extends _$RegionNotifier {
  @override
  int build() => 1;

  chooseRegion(int i) => state = i;
}
