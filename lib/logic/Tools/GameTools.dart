import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import '../../data/models/game.dart';
import '../blocs/non_steam_games_cubit.dart';

enum GameStatus {NonAdded, Added, FullyAdded, AddedExternal}

class GameTools {
  static GameStatus getGameStatus(Game game) {

    if(game.isExternal) return GameStatus.AddedExternal;

    bool added = game.exeFileEntries.firstWhereOrNull((element) => element.added == true) != null;
    bool oneExeAddedAndCompatToolAssigned =
        game.exeFileEntries.firstWhereOrNull((element) => element.added == true && element.compatToolCode != "None") != null;

    GameStatus status = GameStatus.NonAdded;
    if (added == true && oneExeAddedAndCompatToolAssigned == true) {
      status =  GameStatus.FullyAdded;
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
      if(status == GameStatus.AddedExternal) {
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
    notAdded.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    added.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    fullyAdded.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    addedExternal.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    List<Game> finalList = [];

    if (sortDirection == SortDirection.Desc) {
      finalList..addAll(notAdded)..addAll(added)..addAll(fullyAdded)..addAll(addedExternal);
    } else {
      finalList..addAll(addedExternal)..addAll(fullyAdded)..addAll(added)..addAll(notAdded);
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

}



