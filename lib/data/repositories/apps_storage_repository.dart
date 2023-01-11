import 'package:collection/collection.dart';
import 'package:game_miner/data/data_providers/app_storage_data_provider.dart';
import 'package:game_miner/data/data_providers/compat_tools_mapping_data_provider.dart';
import 'package:game_miner/data/data_providers/settings_data_provider.dart';
import 'package:game_miner/data/data_providers/steam_shortcuts_data_provider.dart';
import 'package:game_miner/data/models/app_storage.dart';
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

class AppsStorageRepository extends CacheRepository<AppStorage> {
  final String cacheKey = "AllAppStorage";

  late final SteamAppsDataProvider _steamAppsDataProvider;
  late final  AppsStorageDataProvider _appIdsStorageDataProvider;
  late final SteamShortcutDataProvider _steamShortcutDataProvider;

  AppsStorageRepository() {
    _steamAppsDataProvider = GetIt.I<SteamAppsDataProvider>();
    _appIdsStorageDataProvider = GetIt.I<AppsStorageDataProvider>();
    _steamShortcutDataProvider = GetIt.I<SteamShortcutDataProvider>();
  }

  //Request a reload in next iteration
  void invalidateCache() {
    removeCacheKey(cacheKey);
  }

  List<AppStorage>? getAll() {
    List<AppStorage>? appsStorage = getObjectsFromCache(cacheKey);
    return appsStorage;
  }

  Future<List<AppStorage>> load(String userId) async {

    List<AppStorage>? finalAppsStorage = getObjectsFromCache(cacheKey);

    if(finalAppsStorage == null) {
      //Steam apps (Apps that were downloaded and installed through steam)
      var steamApps = await _steamAppsDataProvider.load();

      //Here we have all app ids (Steam apps and not steam apps) that keep data in compatdata or shadercache folders
      finalAppsStorage = await _appIdsStorageDataProvider.load();

      //We want to return all AppStorage entries. But let's flag the ones that are Steam games and the ones that arent
      //We build AppStorage for every SteamApp too if it has any storage assigned in compatdata or shadercache
      for(SteamApp sa in steamApps) {
        AppStorage? appStorage = finalAppsStorage.singleWhereOrNull((element) => element.appId == sa.appId);
        if(appStorage != null) {
          appStorage.isSteamApp = true;
          appStorage.name = sa.name;
          appStorage.installdir = sa.installdir;
        }
      }

      //Get shortcuts data
      List<SteamShortcut> scs = await _steamShortcutDataProvider.loadShortcutGames(userId);

      var nonSteamAppStorage  = finalAppsStorage.where((element) => element.isSteamApp == false);

      for(AppStorage as in nonSteamAppStorage) {
        SteamShortcut? shortcut = scs.firstWhereOrNull((element) => element.appId.toString() == as.appId);
        if(shortcut!=null) {
          as.name = shortcut.appName;
          as.installdir = shortcut.startDir;
        }
      }

      setCacheKey(cacheKey, finalAppsStorage);
    }

    return finalAppsStorage!;
  }
}