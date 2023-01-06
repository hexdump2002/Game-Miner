import 'package:collection/collection.dart';
import 'package:game_miner/data/data_providers/compat_tools_mapping_data_provider.dart';
import 'package:game_miner/data/data_providers/steam_shortcuts_data_provider.dart';
import 'package:game_miner/data/models/compat_tool_mapping.dart';
import 'package:game_miner/data/models/steam_shortcut_game.dart';
import 'package:game_miner/data/models/game.dart';
import 'package:game_miner/data/repositories/cache_repository.dart';
import 'package:game_miner/logic/Tools/string_tools.dart';
import 'package:get_it/get_it.dart';
import '../data_providers/steam_apps_data_provider.dart';
import '../data_providers/user_library_games_data_provider.dart';
import '../models/game_executable.dart';
import '../models/steam_app.dart';

class SteamAppsRepository extends CacheRepository<SteamApp> {
  final String cacheKey = "SteamApps";

  late final SteamAppsDataProvider _steamAppsDataProvider;

  SteamAppsRepository() {
    _steamAppsDataProvider = GetIt.I<SteamAppsDataProvider>();
  }

  List<SteamApp>? getAll() {
    List<SteamApp>? steamAps = getObjectsFromCache(cacheKey);
    return steamAps;
  }

  Future<List<SteamApp>> load() async {

    List<SteamApp>? steamApps = getObjectsFromCache(cacheKey);

    if(steamApps == null) {
      steamApps = await _steamAppsDataProvider.load();
      setCacheKey(cacheKey, steamApps);
    }

    return steamApps!;
  }
}