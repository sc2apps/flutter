import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
class Player with _$Player {
  const factory Player({
    required String identifier, //team_id,
    required String name, //team_name,
    @Default([])
    List<Map<String, dynamic>> members, //[player for player in players],
    required int numGames, //0,
    required int wins, //0,
    required int losses, //0,
    required int draws, //0,
    required double elo, //ELO_MEAN,
    required int upsets, //0,
    required int beenUpset, //0,
  }) = _Player;

  factory Player.fromJson(Map<String, Object?> json) => _$PlayerFromJson(json);
}
