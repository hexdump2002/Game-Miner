import 'dart:async';

import 'package:game_miner/data/data_providers/settings_data_provider.dart';
import 'package:game_miner/data/data_providers/steam_config_data_provider.dart';
import 'package:game_miner/data/models/steam_config.dart';
import 'package:get_it/get_it.dart';

import '../models/settings.dart';

class SteamConfigRepository {
  final SteamConfigDataProvider _steamConfigDataProvider = GetIt.I<SteamConfigDataProvider>();
  SteamConfig? _steamConfig;

  Future<SteamConfig> load() async{
    if(_steamConfig == null) {
      _steamConfig = await _steamConfigDataProvider.load();
    }

    //Return a copy of the settings
    return _steamConfig!;
  }

  SteamConfig getConfig() {
    if(_steamConfig == null) {
      throw Exception("Steam Config is null because they hasn't been loaded. Aborting...");
    }
    return _steamConfig!;
  }

  void update(SteamConfig steamConfig) {
    _steamConfig = steamConfig;
  }

  void save() {
    throw Exception("Not implemented");
    /*_settingsDataProvider.saveSettings(_settings!);
    _addToStream(_settings!);*/
  }

}