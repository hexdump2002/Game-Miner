import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:game_miner/data/models/compat_tool_mapping.dart';
import 'package:game_miner/data/models/game_executable.dart';
import 'package:game_miner/data/models/game_export_data.dart';
import 'package:game_miner/data/repositories/compat_tools_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;

import '../../data/models/compat_tool.dart';
import '../../data/models/game.dart';
import '../blocs/game_mgr_cubit.dart';

enum GameStatus { NonAdded, Added, FullyAdded, AddedExternal }


class GameTools {
  static void handleGameExecutableErrorsForGame(Game g) {
    for (GameExecutable ge in g.exeFileEntries) {
      ge.errors.clear();
      if (ge.brokenLink) ge.errors.add(GameExecutableError(GameExecutableErrorType.BrokenExecutable, ""));
      if (!hasExecutableCorrectProtonsAssigned(ge)) {
        ge.errors.add(GameExecutableError(GameExecutableErrorType.InvalidProton, ge.compatToolCode));
        ge.compatToolCode = "None";
      }
    }
  }

  static bool hasExecutableCorrectProtonsAssigned(GameExecutable exe) {
    CompatToolsRepository ctr = GetIt.I<CompatToolsRepository>();
    List<CompatTool> cts = ctr.getCachedCompatTools();
    if (exe.compatToolCode != "None") {
      CompatTool? ctm = cts.firstWhereOrNull((element) => element.code == exe.compatToolCode);
      if (ctm == null) {
        return false;
      }
    }
    return true;
  }

  static bool doGamesHaveErrors(List<Game> games) {
    return games.firstWhereOrNull((e) => e.hasErrors())!=null;
  }


  static GameStatus getGameStatus(Game game) {
    if (game.isExternal) return GameStatus.AddedExternal;

    bool added = game.exeFileEntries.firstWhereOrNull((element) => element.added == true) != null;
    bool oneExeAddedAndCompatToolAssigned =
        game.exeFileEntries.firstWhereOrNull((element) => element.added == true && element.compatToolCode != "None") != null;

    GameStatus status = GameStatus.NonAdded;
    if (added == true && oneExeAddedAndCompatToolAssigned == true) {
      status = GameStatus.FullyAdded;
    } else if (added == true) {
      status = GameStatus.Added;
    }

    return status;
  }


  static Map<String, List<Game>> categorizeGamesByStatus(List<Game> games) {
    List<Game> notAdded = [],
        added = [],
        fullyAdded = [],
        addedExternal = [];

    for (int i = 0; i < games.length; ++i) {
      Game ug = games[i];
      var status = getGameStatus(ug);
      if (status == GameStatus.AddedExternal) {
        addedExternal.add(ug);
      }
      else if (status == GameStatus.FullyAdded) {
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
      finalList..addAll(withErrors)..addAll(notAdded)..addAll(added)..addAll(fullyAdded)..addAll(addedExternal);
    } else {
      finalList..addAll(addedExternal)..addAll(fullyAdded)..addAll(added)..addAll(notAdded)..addAll(withErrors);
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

  static void exportGame(Game game) {
    List<GameExecutableExportedData> geed = [];
    for (GameExecutable ge in game.exeFileEntries) {
      if (ge.added) {
        geed.add(GameExecutableExportedData(ge.compatToolCode, ge.relativeExePath, ge.name, ge.launchOptions));
      }
    }
    GameExportedData ged = GameExportedData(geed);

    String json = jsonEncode(ged);
    String fullPath = "${game.path}/gameminer_config.json";
    File(fullPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(json);
  }

  static Future<GameExportedData?> importGame(Game game) async {
    String path = "${game.path}/gameminer_config.json";
    var file = File(path);
    if (!await file.exists()) {
      return null;
    }
    else {
      await file.open();
      String json = await file.readAsString();
      var gmd = GameExportedData.fromJson(jsonDecode(json));
      return gmd;
    }
  }
}



