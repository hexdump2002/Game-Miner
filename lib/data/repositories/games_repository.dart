
import 'package:collection/collection.dart';
import 'package:game_miner/data/data_providers/compat_tools_mapping_data_provider.dart';
import 'package:game_miner/data/data_providers/steam_shortcuts_data_provider.dart';
import 'package:game_miner/data/models/compat_tool_mapping.dart';
import 'package:game_miner/data/models/steam_shortcut_game.dart';
import 'package:game_miner/data/models/game.dart';
import 'package:game_miner/data/repositories/cache_repository.dart';
import 'package:game_miner/logic/Tools/game_tools.dart';
import 'package:game_miner/logic/Tools/steam_tools.dart';
import 'package:game_miner/logic/Tools/string_tools.dart';
import 'package:path/path.dart';
import 'package:get_it/get_it.dart';
import '../../logic/Tools/file_tools.dart';
import '../data_providers/user_library_games_data_provider.dart';
import '../models/game_executable.dart';
import '../models/game_export_data.dart';


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
  
  Game? getGame(int id) {
    return getObjectsFromCache(cacheKey)!.firstWhere((element) => element.id == id);
  }

  void update(Game game) {
    var games = getObjectsFromCache(cacheKey)!;
    int index = games.indexWhere((element) => element.id == game.id);
    games[index] = game;

  }

  Future<List<Game>> loadGames(String userId, List<String> userLibraryPaths) async {
    List<Game>? games = getObjectsFromCache(cacheKey);

    if (games == null) {
      List<SteamShortcut> shortcuts = await _steamShortcutsDataProvider.loadShortcutGames(userId);
      List<Game> userLibraryGames = await _libraryGamesDataProvider.loadGames(userLibraryPaths);
      List<CompatToolMapping> compatToolMappings = await _compatToolsMappingDataProvider.loadCompatToolMappings();

      //Apply configurations to games
      for(Game g in userLibraryGames) {
          GameExportedData? gee = await GameTools.importGame(g);
          if(gee!=null) {
            for(GameExecutable ge in g.exeFileEntries) {
              GameExecutableExportedData? foundGe=gee.executables.firstWhereOrNull((element) => element.executableRelativePath == ge.relativeExePath);
              if(foundGe!=null) {
                ge.name = foundGe.executableName;
                ge.launchOptions = foundGe.executableOptions;
                ge.added = true;
                ge.appId=SteamTools.generateAppId("${ge.startDir}/${ge.relativeExePath}");
                ge.fillProtonMappingData(foundGe.compatToolCode, "", "250");
                ge.dataFromConfigFile = true; //Mark as configured by config file
              }
            }
          }
      }

      games = userLibraryGames;

      for (SteamShortcut shortcut in shortcuts) {
        bool finished = false;
        var i = 0;
        while (!finished && i < userLibraryGames.length) {
          Game e = userLibraryGames[i];
          /*if(shortcut.startDir.contains("Blasp")) {
            print("yeah");
          }*/
          GameExecutable? gameExecutable = e.exeFileEntries.firstWhereOrNull((exe) {
            return "${e.path}/${exe.relativeExePath}" == StringTools.removeQuotes(shortcut.exePath);
          });

          if (gameExecutable != null) {
            gameExecutable.fillFromNonSteamGame(shortcut, e.path);
            gameExecutable.added = true;
            gameExecutable.dataFromConfigFile = false; //Unmark as configured by config file because it has a shortcut configured
            finished = true;

            //Find the proton mapping
            CompatToolMapping? pm = compatToolMappings.firstWhereOrNull((e) => gameExecutable.appId.toString() == e.id);
            if (pm != null) {
              gameExecutable.fillProtonMappingData(pm.name, pm.config, pm.priority);
            }
            else {
              gameExecutable.clearCompatToolMappingData();
            }
          }

          ++i;
        }

        //We got a shortcut exe path that did not match any in our games exefiles. This can be because it did not come come from our list of folders (previously added or source folder was deleted in GameMiner) or
        //The shortcut can belong to a game from our lib but the exe file does not exist.
        if (!finished) {
          String shortcutBaseName = dirname(StringTools.removeQuotes(shortcut.exePath));
          //We couldn't file an exe file in our games matching ths shortcut but perhaps it still belongs to our game folders and it is a broken link.
          Game? game = games.firstWhereOrNull((element) => shortcutBaseName.startsWith(element.path));
          if(game != null)  {
            GameExecutable gameExecutable = GameExecutable(game.path, shortcut.exePath, true);
            gameExecutable.fillFromNonSteamGame(shortcut, game.path);
            gameExecutable.added = true;

            //Find the proton mapping
            CompatToolMapping? pm = compatToolMappings.firstWhereOrNull((e) => gameExecutable.appId.toString() == e.id);
            if (pm != null) {
              gameExecutable.fillProtonMappingData(pm.name, pm.config, pm.priority);
            }

            game.exeFileEntries.add(gameExecutable);
          }
          else {
            //Add external exe and provid proton mapping
            CompatToolMapping? pm = compatToolMappings.firstWhereOrNull((e) => shortcut.appId.toString() == e.id);
            Game ug = Game(shortcut.startDir, shortcut.appName);
            ug.addExternalExeFile(shortcut, pm);
            games.add(ug);
          }
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

  List<SteamShortcut> _convertGamesToShortcuts(List<Game> games) {
    //Convert Games into steam shortcuts data provider model (only the ones selected)
    List<SteamShortcut> shortcuts = [];

    for (Game g in games) {
      for (GameExecutable ge in g.exeFileEntries) {
        if (ge.added == true) {
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
          s.exePath = g.isExternal ? StringTools.addQuotesToPath(ge.relativeExePath) : StringTools.addQuotesToPath("${g.path}/${ge.relativeExePath}");
          s.tags = ge.tags;
          shortcuts.add(s);
        }
      }
    }

    return shortcuts;
  }

  //TODO: Move all this to write to a in memory buffer and then dump it to the file
  Future<bool> saveGames(String shortcutsPath, List<Game> games, bool backupsEnabled, int maxBackupsCount) async {
    //await _steamShortcutsDataProvider.saveShortcuts( shortcutsPath, shortcuts);
    await _saveShortcuts(shortcutsPath, games, backupsEnabled, maxBackupCount: maxBackupsCount);
    await _saveCompatToolMappings(games, backupsEnabled, maxBackupCount: maxBackupsCount);
    return true;
  }

  Future<bool> saveGame(String shortcutPath, String userId, Game game) async {
    var shortcuts = _convertGamesToShortcuts([game]);

    //This means that no exe of this game has been added, so, no need to save anything
    if (shortcuts.isEmpty) {
      return false;
    }

    //TODO: backups support
    await _steamShortcutsDataProvider.updateShortcut(shortcutPath, userId, shortcuts[0]);

    return true;
  }
  
  Future<void> _saveShortcuts(String shortcutPath, List<Game> games,bool backupsEnabled,{int maxBackupCount=0})  async{
    var shortcuts = _convertGamesToShortcuts(games);

    Map<String, dynamic> extraParams = {};
    if (backupsEnabled) {

      await FileTools.saveFileSecure<List<SteamShortcut>>(shortcutPath, shortcuts, extraParams,
              (String path, List<SteamShortcut> games, Map<String, dynamic> extraParams) async {
            return await _doSaveShortcuts(path, shortcuts, extraParams);
          }, maxBackupCount);
    } else {
      await _doSaveShortcuts(shortcutPath, shortcuts, extraParams);
    }
  }
  
  Future<void> _saveCompatToolMappings(List<Game> games, bool backupsEnabled,{int maxBackupCount=0})  async {
    List<CompatToolMapping> ctms = await _compatToolsMappingDataProvider.loadCompatToolMappings();

    Map<int, CompatToolMapping> usedProtonMappings = {};
    games.forEach((e) {
      e.exeFileEntries.forEach((uge) {
        if(uge.added) {
          if (usedProtonMappings.containsKey(uge.appId)) throw Exception("An appId with 2 differnt pronton mappings found!. This is not valid.");
          if (uge.compatToolCode == "None") return;

          usedProtonMappings[uge.appId] = CompatToolMapping(uge.appId.toString(), uge.compatToolCode, uge.compatToolConfig, uge.compatToolPriority);
        }
      });
    });

    //Merge our old compat tool list
    List<CompatToolMapping> usedCompatToolMappings = usedProtonMappings.entries.map((entry) => entry.value).toList();
    for(CompatToolMapping usedProtonMapping in usedCompatToolMappings) {
      CompatToolMapping? foundCtm = ctms.firstWhereOrNull((element) => usedProtonMapping.id == element.id);
      if(foundCtm!=null) {
        foundCtm.name = usedProtonMapping.name;
        foundCtm.config = usedProtonMapping.config;
        foundCtm.priority = usedProtonMapping.priority;
      }
      else {
        ctms.add(usedProtonMapping);
      }
    }



    String homeFolder = FileTools.getHomeFolder();
    String configPath = "$homeFolder/.local/share/Steam/config/config.vdf";

    if (backupsEnabled) {
      Map<String, dynamic> extraParams = {"sourceFile": configPath};
      await FileTools.saveFileSecure<List<CompatToolMapping>>(configPath, ctms, extraParams,
              (String path, List<CompatToolMapping> games, Map<String, dynamic> extraParams) async {
            return await _doSaveCompatToolMappings(path, ctms, extraParams);
          }, maxBackupCount);
    } else {
      await _doSaveCompatToolMappings(configPath, ctms, <String, dynamic>{});
    }
  }

  Future<bool> _doSaveCompatToolMappings(String path, List<CompatToolMapping> compatToolsMappings, Map<String,dynamic> extraParams) async {
    await _compatToolsMappingDataProvider.saveCompatToolMappings(path, compatToolsMappings, extraParams);
    return true;
  }

  Future<bool> _doSaveShortcuts(String path, List<SteamShortcut> shortcuts, Map<String,dynamic> extraParams) async {
    await _steamShortcutsDataProvider.saveShortcuts(path, shortcuts);
    return true;
  }
}
