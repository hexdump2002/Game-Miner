import 'package:collection/collection.dart';
import 'package:game_miner/data/data_providers/compat_tools_mapping_data_provider.dart';
import 'package:game_miner/data/data_providers/steam_shortcuts_data_provider.dart';
import 'package:game_miner/data/models/compat_tool_mapping.dart';
import 'package:game_miner/data/models/steam_shortcut_game.dart';
import 'package:game_miner/data/models/game.dart';
import 'package:game_miner/data/repositories/cache_repository.dart';
import 'package:game_miner/logic/Tools/string_tools.dart';
import 'package:get_it/get_it.dart';
import '../data_providers/user_library_games_data_provider.dart';
import '../models/game_executable.dart';

class GamesRepository extends CacheRepository<Game> {
  final String cacheKey = "Games";

  late final SteamShortcutDataProvider _steamShortcutsDataProvider;
  late final UserLibraryGamesDataProvider _libraryGamesDataProvider;
  late final CompatToolsMappingDataProvider _compatToolsMappingDataProvider;

  GamesRepository() {
    _steamShortcutsDataProvider = GetIt.I<SteamShortcutDataProvider>();
    _libraryGamesDataProvider = GetIt.I<UserLibraryGamesDataProvider>();
    _compatToolsMappingDataProvider = GetIt.I<CompatToolsMappingDataProvider>();
  }

  List<Game>? getGames() {
    List<Game>? games = getObjectsFromCache(cacheKey);
    return games;
  }

  Future<List<Game>> loadGames(String userId, List<String> userLibraryPaths) async {

    List<Game>? games = getObjectsFromCache(cacheKey);

    if(games == null) {
      List<SteamShortcut> shortcuts = await _steamShortcutsDataProvider.loadShortcutGames(userId);
      List<Game> userLibraryGames = await _libraryGamesDataProvider.loadGames(userLibraryPaths);
      List<CompatToolMapping> compatToolMappings = await _compatToolsMappingDataProvider.loadCompatToolMappings();

      games = List.from(userLibraryGames);

      for (SteamShortcut shortcut in shortcuts) {
        bool finished = false;
        var i = 0;
        while (!finished && i < userLibraryGames.length) {
          Game e = userLibraryGames[i];
          GameExecutable? gameExecutable = e.exeFileEntries.firstWhereOrNull((exe) {
            return "${e.path}/${exe.relativeExePath}" == StringTools.removeQuotes(shortcut.exePath);
          });

          if (gameExecutable != null) {
            gameExecutable.fillFromNonSteamGame(shortcut, e.path);
            gameExecutable.added = true;
            finished = true;

            //Find the proton mapping
            CompatToolMapping? pm = compatToolMappings.firstWhereOrNull((e) => gameExecutable.appId.toString() == e.id);
            if (pm != null) {
              gameExecutable.fillProtonMappingData(pm.name, pm.config, pm.priority);
            }
          }

          ++i;
        }

        //We got an exe path that did not come from our list of folders (previously added or source folder was deleted in toolbox)
        if (!finished) {
          //Add external exe and provid proton mapping
          CompatToolMapping? pm = compatToolMappings.firstWhereOrNull((e) => shortcut.appId.toString() == e.id);
          Game ug = Game(shortcut.appName);
          ug.addExternalExeFile(shortcut, pm);
          games.add(ug);
        }
      }

      setCacheKey(cacheKey, games);
    }

    return games!;
  }

  //Request a reload in next iteration
  void invalidateGamesCache() {
    removeCacheKey(cacheKey);
  }

  //TODO: Move all this to write to a in memory buffer and then dump it to the file
  Future<void> saveGames(String userId, List<Game> games) async {


    //Convert Games into steam shortcuts data provider model (only the ones selected)
    List<SteamShortcut> shortcuts = [];

    for(Game g in games) {
      for(GameExecutable ge in g.exeFileEntries) {

        if(ge.added == true) {
          SteamShortcut s = SteamShortcut();
          s.entryId = ge.entryId;
          s.appId = ge.appId;
          s.appName = ge.name;
          s.startDir = StringTools.addQuotesToPath(ge.startDir);
          s.icon = ge.icon;
          s.shortcutPath = StringTools.addQuotesToPath(ge.shortcutPath);
          s.launchOptions = ge.launchOptions;
          s.isHidden = ge.isHidden;
          s.allowDesktopConfig = ge.allowDdesktopConfig;
          s.allowOverlay = ge.allowOverlay;
          s.openVr = ge.openVr;
          s.devkit = ge.devkit;
          s.devkitGameId = ge.devkitGameId;
          s.devkitOverrideAppId = ge.devkitOverrideAppId;
          s.lastPlayTime = ge.lastPlayTime;
          s.flatPackAppId = ge.flatPackAppId;
          s.exePath = g.isExternal
              ? StringTools.addQuotesToPath(ge.relativeExePath)
              : StringTools.addQuotesToPath(ge.getAbsolutePath());
          s.tags = ge.tags;
          shortcuts.add(s);
        }
      }
    }

    _steamShortcutsDataProvider.saveShortcuts(userId, shortcuts);
  }




}