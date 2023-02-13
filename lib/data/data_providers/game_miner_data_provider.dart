import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:game_miner/data/models/app_storage.dart';
import 'package:game_miner/data/models/game_miner_data.dart';
import 'package:game_miner/data/models/steam_user.dart';
import 'package:game_miner/logic/io/text_vdf_file.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../logic/Tools/file_tools.dart';
import '../models/steam_app.dart';



class GameMinerDataProvider {
  Future<GameMinerData> load(String path) async {
    GameMinerData gmd = GameMinerData(<String,String>{});

    var file = File(path);
    if(!file.existsSync())
    {
      saveGameMinerData(path, gmd);
    }
    else {
      file.openSync();
      String json = file.readAsStringSync();
      gmd = GameMinerData.fromJson(jsonDecode(json));
    }

    return gmd;
  }

  void saveGameMinerData(String path, GameMinerData gmd) {
    File(path).openSync(mode:FileMode.writeOnly);

    String json = jsonEncode(gmd);

    File(path)
      ..createSync(recursive: false)
      ..writeAsStringSync(json);
  }


}
