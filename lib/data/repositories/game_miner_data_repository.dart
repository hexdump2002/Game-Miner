import 'dart:async';

import 'package:game_miner/data/data_providers/game_miner_data_provider.dart';
import 'package:game_miner/data/data_providers/settings_data_provider.dart';
import 'package:game_miner/data/models/game_miner_data.dart';
import 'package:get_it/get_it.dart';

import '../../logic/Tools/file_tools.dart';
import '../models/settings.dart';

class GameMinerDataRepository {
  final GameMinerDataProvider _gameMinerDataProvider = GetIt.I<GameMinerDataProvider>();
  GameMinerData? _gameMinerData;
  final String dataPath;

  GameMinerDataRepository(this.dataPath);

  Future<GameMinerData?> load() async {
    if(_gameMinerData == null) {
      _gameMinerData = await _gameMinerDataProvider.load(dataPath);
    }

    //Return a copy of the settings
    return _gameMinerData;
  }

  GameMinerData getGameMinerData() {
    if(_gameMinerData == null) {
      throw Exception("GameMinerDataProvider are null because they hasn't been loaded. Aborting...");
    }
    return _gameMinerData!;
  }

  void update(GameMinerData gameMinerData) {
    _gameMinerData = gameMinerData;
  }

  Future<void> save(bool backupsEnabled, int maxBackupsCount) async {
    if(_gameMinerData == null) {
      throw Exception("GameMinerDataProvider is null because it hasn't been loaded. Aborting...");
    }

    if (backupsEnabled) {
      await FileTools.saveFileSecure<GameMinerData>(dataPath, _gameMinerData!, {},
              (String path, GameMinerData gmd, Map<String, dynamic> extraParams) async {
                _gameMinerDataProvider.saveGameMinerData(path, _gameMinerData!);
                return true;
          }, maxBackupsCount);
    } else {
      _gameMinerDataProvider.saveGameMinerData(dataPath, _gameMinerData!);
    }
  }
}