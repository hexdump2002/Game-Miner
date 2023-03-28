import 'package:game_miner/data/models/game_folder_stats.dart';

class GameMinerCachedFolderStatsData {
  Map<String,GameFolderStats> pathsToFolderStats = <String,GameFolderStats>{};

  GameMinerCachedFolderStatsData(this.pathsToFolderStats);

  GameMinerCachedFolderStatsData.fromJson(Map<String, dynamic> json) {

    //Map<String,dynamic> map = json['pathsToFolderStats'];
    for(String key in json.keys)
    {
      GameFolderStats stats = GameFolderStats.fromJson(json[key] as Map<String,dynamic>);
      pathsToFolderStats[key] = stats;
    }
  }

  Map<String, dynamic> toJson() {
    return {'pathsToFolderStats':pathsToFolderStats};
  }
}