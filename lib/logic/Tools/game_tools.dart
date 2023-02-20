import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:game_miner/data/models/app_storage.dart';
import 'package:game_miner/data/models/compat_tool_mapping.dart';
import 'package:game_miner/data/models/game_executable.dart';
import 'package:game_miner/data/models/game_export_data.dart';
import 'package:game_miner/data/repositories/compat_tools_repository.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';
import 'package:game_miner/logic/Tools/steam_tools.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:collection/collection.dart';

import '../../data/stats.dart';
import '../../data/models/compat_tool.dart';
import '../../data/models/game.dart';
import '../../data/repositories/apps_storage_repository.dart';
import '../blocs/game_mgr_cubit.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

enum GameStatus { NonAdded, Added, FullyAdded, AddedExternal }

class GameTools {
  static void handleGameExecutableErrorsForGame(Game g) {
    for (GameExecutable ge in g.exeFileEntries) {
      ge.errors.clear();
      if (ge.added && ge.brokenLink) ge.errors.add(GameExecutableError(GameExecutableErrorType.BrokenExecutable, ""));
      if (!hasExecutableCorrectProtonsAssigned(ge)) {
        ge.errors.add(GameExecutableError(GameExecutableErrorType.InvalidProton, ge.compatToolCode));
        //No reseteamos compatToolCode pq queremos mostrar el proton en el combo
      }
    }
  }

  static bool hasExecutableCorrectProtonsAssigned(GameExecutable exe) {
    CompatToolsRepository ctr = GetIt.I<CompatToolsRepository>();
    List<CompatTool> cts = ctr.getCachedCompatTools();
    if (exe.compatToolCode != "not_assigned" && exe.compatToolCode != "no_use") {
      CompatTool? ctm = cts.firstWhereOrNull((element) => element.code == exe.compatToolCode);
      if (ctm == null) {
        return false;
      }
    }
    return true;
  }

  static bool doGamesHaveErrors(List<Game> games) {
    return games.firstWhereOrNull((e) => e.hasErrors()) != null;
  }

  static GameStatus getGameStatus(Game game) {
    if (game.isExternal) return GameStatus.AddedExternal;

    bool added = game.exeFileEntries.firstWhereOrNull((element) => element.added == true) != null;
    bool oneExeAddedAndCompatToolAssigned =
        game.exeFileEntries.firstWhereOrNull((element) => element.added == true && element.compatToolCode != "not_assigned") != null;

    GameStatus status = GameStatus.NonAdded;
    if (added == true && oneExeAddedAndCompatToolAssigned == true) {
      status = GameStatus.FullyAdded;
    } else if (added == true) {
      status = GameStatus.Added;
    }

    return status;
  }

  static Map<String, List<Game>> categorizeGamesByStatus(List<Game> games) {
    List<Game> notAdded = [], added = [], fullyAdded = [], addedExternal = [];

    for (int i = 0; i < games.length; ++i) {
      Game ug = games[i];
      var status = getGameStatus(ug);
      if (status == GameStatus.AddedExternal) {
        addedExternal.add(ug);
      } else if (status == GameStatus.FullyAdded) {
        fullyAdded.add(ug);
      } else if (status == GameStatus.Added) {
        added.add(ug);
      } else {
        notAdded.add(ug);
      }
    }

    return {"added": added, "fullyAdded": fullyAdded, "notAdded": notAdded, "addedExternal": addedExternal};
  }

  static Map<String, List<Game>> categorizeGamesBySourceFolder(List<Game> games, List<String> searchPaths) {
    Map<String, List<Game>> gamesByPath = {};

    //Add all path as keys
    searchPaths.forEach((path) {
      gamesByPath[path] = [];
    });

    //Add all games to each path. External ones are not from library so we skip them
    games.where((element) => !element.isExternal).forEach((game) {
      gamesByPath[p.dirname(game.path)]!.add(game);
    });

    return gamesByPath;
  }

  static List<Game> sortByName(SortDirection sortDirection, List<Game> games) {
    if (sortDirection == SortDirection.Asc) {
      games.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      games.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }

    return games;
  }

  static List<Game> sortByStatus(SortDirection sortDirection, List<Game> games) {
    var gameCategories = categorizeGamesByStatus(games);
    List<Game> notAdded = gameCategories['notAdded']!;
    List<Game> added = gameCategories['added']!;
    List<Game> fullyAdded = gameCategories['fullyAdded']!;
    List<Game> addedExternal = gameCategories['addedExternal']!;
    List<Game> withErrors = gameCategories['withErrors']!;

    withErrors.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notAdded.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    added.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    fullyAdded.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    addedExternal.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    List<Game> finalList = [];

    if (sortDirection == SortDirection.Desc) {
      finalList
        ..addAll(withErrors)
        ..addAll(notAdded)
        ..addAll(added)
        ..addAll(fullyAdded)
        ..addAll(addedExternal);
    } else {
      finalList
        ..addAll(addedExternal)
        ..addAll(fullyAdded)
        ..addAll(added)
        ..addAll(notAdded)
        ..addAll(withErrors);
    }

    assert(games.length == finalList.length);
    games = finalList;

    return games;
  }

  static List<Game> sortBySize(SortDirection sortDirection, List<Game> games) {
    if (sortDirection == SortDirection.Asc) {
      games.sort((a, b) => a.gameSize.compareTo(b.gameSize));
    } else {
      games.sort((a, b) => b.gameSize.compareTo(a.gameSize));
    }

    return games;
  }

  static Future<GameFolderStats?> getGameFolderStats(Game game) async {
    if(!game.isExternal) {
      var metaData = await FileTools.getFolderMetaData(game.path, recursive: true);
      var fileCount = metaData['fileCount']!;
      var size = metaData['size']!;
      var dateSinceEpoc = metaData['creationDate'];
      return GameFolderStats(fileCount, size,DateTime.fromMicrosecondsSinceEpoch(dateSinceEpoc!));
    }
    else {
      return null;
    }
  }


  static Future<void> exportShortcutArt(String outputFolder, GameExecutable exe, String userId) async {
    String sourcePath = "${SteamTools.getSteamBaseFolder()}/userdata/$userId/config/grid";
    String destPath = outputFolder + "/game_miner_data";

    try {

      String hash= md5.convert(utf8.encode(exe.relativeExePath)).toString();

      //Check if we must create the needed folder to hold the images
      if (!await FileTools.existsFolder(destPath)) {
        await Directory(destPath).create();
      }

      String regEx = "^${exe.appId}.*";
      List<String>? imageFiles = await FileTools.getFolderFilesAsync(sourcePath, recursive: false, regExFilter: regEx);
      if(imageFiles!=null) {
        for (String imageFile in imageFiles) {
          String fileName = p.basename(imageFile);
          String postFix = _getShortcutArtPostFixWithExtension(fileName);
          String destName = "$hash$postFix";
          String fullPath = p.join(destPath, destName);
          await File(imageFile).copy(fullPath);
        }
      }
    } catch (ex) {
      print("Error: $ex");
    }
  }

  static String _getShortcutArtPostFixWithExtension(String fileName) {
    //Cover
    int index = fileName.indexOf("p.");
    if(index!=-1) {
      return fileName.substring(index);
    }

    //ico, logo, etc.
    index = fileName.indexOf(r'_');
    if(index!=-1) {
      return fileName.substring(index);
    }

    //Home image
    index = fileName.indexOf(".");
    return fileName.substring(index);

  }
  static Future<bool> deleteGameConfig(Game game) async{
    String fullConfigFilePath = "${game.path}/gameminer_config.json";
    String fullConfigDataFolderPath = "${game.path}/game_miner_data";
    try {
      if(await FileTools.existsFile(fullConfigFilePath)) {
        await File(fullConfigFilePath).delete();
      }

      if(await FileTools.existsFolder(fullConfigDataFolderPath)) {
        await Directory(fullConfigDataFolderPath).delete(recursive: true);
      }


      return true;
    }
    catch(ex) {
      print(ex);
      return false;
    }
  }

  static Future<bool> exportGame(Game game, String userId) async {
    bool success = true;
    try {
      List<GameExecutableExportedData> geed = [];

      for (int i = 0; i < game.exeFileEntries.length; ++i) {
        GameExecutable ge = game.exeFileEntries[i];
        if (ge.added) {
          geed.add(GameExecutableExportedData(ge.compatToolCode, ge.relativeExePath, ge.name, ge.launchOptions));
          await exportShortcutArt(game.path, ge, userId);
        }
      }
      GameExportedData ged = GameExportedData(geed);

      String json = jsonEncode(ged);
      String fullPath = "${game.path}/gameminer_config.json";
      var file = File(fullPath);
      await file.create(recursive: true);
      await file.writeAsString(json);
    }
    catch(ex) {
      success = false;
      print(ex);
    }

    return success;
  }

  static Future<GameExecutableImages> getGameExecutableImages(int appId, String userId) async {
    String imagesPath = "${SteamTools.getSteamBaseFolder()}/userdata/$userId/config/grid";

    try {
      //Check if we have art to import
      if (!await FileTools.existsFolder(imagesPath)) {
        return GameExecutableImages();
      }

      String? heroImage, coverImage, iconImage, logoImage;
      List<String>? imageFiles = await FileTools.getFolderFilesAsync(imagesPath, recursive: false, regExFilter: "${appId}_*");
      for (String imageFile in imageFiles!) {
        String fileName = p.basenameWithoutExtension(imageFile);
        if (fileName == "${appId}p")
          coverImage = imageFile;
        else if (fileName == "${appId}_hero")
          heroImage = imageFile;
        else if (fileName == "${appId}_icon")
          iconImage = imageFile;
        else if (fileName == "${appId}_logo") logoImage = imageFile;
      }

      return GameExecutableImages(iconImage: iconImage, heroImage: heroImage, coverImage: coverImage, logoImage: logoImage);
    } catch (ex) {
      print("Error reading images: $ex");
      return GameExecutableImages();
    }
  }

  static Future<void> importShortcutArt(String outputFolder, GameExecutable exe, String userId) async {
    String destPath = "${SteamTools.getSteamBaseFolder()}/userdata/$userId/config/grid";
    String sourcePath = outputFolder + "/game_miner_data";

    try {
      //Check if we have art to import
      if (!await FileTools.existsFolder(sourcePath)) {
        return;
      }

      //Check if grid folders exist if not create it
      if (!await FileTools.existsFolder(destPath)) {
        await Directory(destPath).create();
      }

      String hash = md5.convert(utf8.encode(exe.relativeExePath)).toString();
      String regEx = "^$hash.*";
      List<String>? imageFiles = await FileTools.getFolderFilesAsync(sourcePath, recursive: false, regExFilter: regEx);
      if(imageFiles!=null) {
        for (String imageFile in imageFiles) {
          String fileName = p.basename(imageFile);
          fileName = fileName.replaceFirst(hash, exe.appId.toString());
          String fullPath = p.join(destPath, fileName);
          await File(imageFile).copy(fullPath);
        }
      }
    } catch (ex) {
      print("Error: $ex");
    }
  }

  static Future<GameExportedData?> importGame(Game game) async {
    String path = "${game.path}/gameminer_config.json";
    var file = File(path);
    if (!await file.exists()) {
      return null;
    } else {
      await file.open();
      String json = await file.readAsString();
      var gmd = GameExportedData.fromJson(jsonDecode(json));
      return gmd;
    }
  }

  static Future<void> deleteGameData(Game game, List<AppStorage> appsStorage, bool deleteCompatData, bool deleteShaderData) async {
    if (deleteCompatData) {
      await deleteCompatToolData(game, appsStorage);
    }

    if (deleteShaderData) {
      await deleteShaderCacheData(game, appsStorage);
    }
  }

  static Future<void> deleteCompatToolData(Game game, List<AppStorage> appsStorage) async {
    String basePath = "${SteamTools.getSteamBaseFolder()}/steamapps";

    for (GameExecutable ge in game.exeFileEntries) {
      //if (ge.added) {
        AppStorage? as = appsStorage!.firstWhereOrNull((element) {
          return element.appId == ge.appId.toString() && element.storageType == StorageType.CompatData;
        });
        if (as != null) {
          print("BOrrando compatdata de exe ${as.appId}");
          String pathToDelete = "$basePath/compatdata/${as.appId}";
          await Directory(pathToDelete).delete(recursive: true);
        }
      //}
    }
  }

  static Future<void> deleteShaderCacheData(Game game, List<AppStorage> appsStorage) async {
    String basePath = "${SteamTools.getSteamBaseFolder()}/steamapps";

    for (GameExecutable ge in game.exeFileEntries) {
      //if (ge.added) {
        AppStorage? as =
            appsStorage!.firstWhereOrNull((element) => element.appId == ge.appId.toString() && element.storageType == StorageType.ShaderCache);
        if (as != null) {
          String pathToDelete = "$basePath/shadercache/${as.appId}";
          await Directory(pathToDelete).delete(recursive: true);
        }
      //}
    }
  }

  static Future<void> deleteGameImages(Game game, String currentUserId) async {
    String basePath = "${SteamTools.getSteamBaseFolder()}/userdata/$currentUserId/config/grid";

    for (GameExecutable ge in game.exeFileEntries) {
      List<String>? imageFiles = await FileTools.getFolderFilesAsync(basePath, recursive: false, regExFilter: "${ge.appId}_*");
      if(imageFiles!=null) {
        for (String imageFile in imageFiles) {
          await File(imageFile).delete();
        }
      }
    }
  }

  static String? getGameImagePath(Game game, GameExecutableImageType imageType) {
    String? path;

    int index = 0;
    while (path == null && index < game.exeFileEntries.length) {
      GameExecutable ge = game.exeFileEntries[index];

      switch (imageType) {
        case GameExecutableImageType.Icon:
          path = ge.images.iconImage;
          break;
        case GameExecutableImageType.CoverSmall:
        case GameExecutableImageType.CoverMedium:
        case GameExecutableImageType.CoverBig:
          path = ge.images.coverImage;
          break;
        case GameExecutableImageType.Banner:
          path = ge.images.heroImage;
          break;
        case GameExecutableImageType.HalfBanner:
          path = ge.images.heroImage;
          break;
        default:
          path = null;
      }

      ++index;
    }

    return path;
  }


}
