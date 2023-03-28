import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:game_miner/data/models/app_storage.dart';
import 'package:game_miner/data/models/game_folder_stats.dart';
import 'package:game_miner/data/models/game_miner_cached_stats_data.dart';
import 'package:game_miner/data/models/game_miner_data.dart';
import 'package:game_miner/data/models/steam_user.dart';
import 'package:game_miner/logic/io/text_vdf_file.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../logic/Tools/file_tools.dart';
import '../models/steam_app.dart';



class GameStatsProvider {
  Future<Map<String,GameFolderStats>> load(String path) async {
    GameMinerCachedFolderStatsData gmd = GameMinerCachedFolderStatsData(<String,GameFolderStats>{});

    var file = File(path);
    if(!file.existsSync())
    {
      save(path, <String,GameFolderStats>{});
    }
    else {
      file.openSync();
      String json = file.readAsStringSync();
      gmd = GameMinerCachedFolderStatsData.fromJson(jsonDecode(json));
    }

    return gmd.pathsToFolderStats;
  }

  void save(String path, Map<String,GameFolderStats> gcfs) {
    File(path).openSync(mode:FileMode.writeOnly);

    GameMinerCachedFolderStatsData gmd = GameMinerCachedFolderStatsData(gcfs);

    String json = jsonEncode(gcfs);

    File(path)
      ..createSync(recursive: false)
      ..writeAsStringSync(json);
  }


}
