import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import '../../data/user_game.dart';
import '../blocs/non_steam_games_cubit.dart';

enum VMGameAddedStatus {NonAdded, Added, FullyAdded, AddedExternal}

class VMGameTools {

  static VMGameAddedStatus getGameStatus(VMUserGame vmUserGame) {
    UserGame ug = vmUserGame.userGame;

    if(ug.isExternal) return VMGameAddedStatus.AddedExternal;

    bool added = vmUserGame.userGame.exeFileEntries.firstWhereOrNull((element) => element.added == true) != null;
    bool oneExeAddedAndProtonAssigned =
        vmUserGame.userGame.exeFileEntries.firstWhereOrNull((element) => element.added == true && element.protonCode != "None") != null;

    VMGameAddedStatus status = VMGameAddedStatus.NonAdded;
    if (added == true && oneExeAddedAndProtonAssigned == true) {
      status =  VMGameAddedStatus.FullyAdded;
    } else if (added == true) {
      status = VMGameAddedStatus.Added;
    }

    return status;
  }

  static Map<String, List<VMUserGame>> categorizeGamesByStatus(List<VMUserGame> games) {
    List<VMUserGame> notAdded = [],
        added = [],
        fullyAdded = [],
        addedExternal = [];

    for (int i = 0; i < games.length; ++i) {
      VMUserGame ug = games[i];
      var status = getGameStatus(ug);
      if(status == VMGameAddedStatus.AddedExternal) {
        addedExternal.add(ug);
      }
      else if (status == VMGameAddedStatus.FullyAdded) {
        fullyAdded.add(ug);
      } else if (status == VMGameAddedStatus.Added) {
        added.add(ug);
      } else {
        notAdded.add(ug);
      }
    }

    return {"added": added, "fullyAdded": fullyAdded, "notAdded": notAdded, "addedExternal": addedExternal};
  }

  static Map<String, List<VMUserGame>> categorizeGamesBySourceFolder(List<VMUserGame> games, List<String> searchPaths) {

    Map<String, List<VMUserGame>> gamesByPath = {};

    //Add all path as keys
    searchPaths.forEach((path) {
      gamesByPath[path] = [];
    });

    //Add all games to each path. External ones are not from library so we skip them
    games.where((element) => !element.userGame.isExternal).forEach((game) {
      gamesByPath[p.dirname(game.userGame.path)]!.add(game);
    });

    return gamesByPath;
  }

  static List<VMUserGame> sortByName(SortDirection sortDirection, List<VMUserGame> games) {

    if (sortDirection == SortDirection.Asc) {
      games.sort((a, b) => a.userGame.name.toLowerCase().compareTo(b.userGame.name.toLowerCase()));
    } else {
      games.sort((a, b) => b.userGame.name.toLowerCase().compareTo(a.userGame.name.toLowerCase()));
    }

    return games;
  }

  static List<VMUserGame> sortByStatus(SortDirection sortDirection, List<VMUserGame> games) {


    var gameCategories = categorizeGamesByStatus(games);
    List<VMUserGame> notAdded = gameCategories['notAdded']!;
    List<VMUserGame> added = gameCategories['added']!;
    List<VMUserGame> fullyAdded = gameCategories['fullyAdded']!;
    List<VMUserGame> addedExternal = gameCategories['addedExternal']!;
    notAdded.sort((a, b) => a.userGame.name.toLowerCase().compareTo(b.userGame.name.toLowerCase()));
    added.sort((a, b) => a.userGame.name.toLowerCase().compareTo(b.userGame.name.toLowerCase()));
    fullyAdded.sort((a, b) => a.userGame.name.toLowerCase().compareTo(b.userGame.name.toLowerCase()));
    addedExternal.sort((a, b) => a.userGame.name.toLowerCase().compareTo(b.userGame.name.toLowerCase()));

    List<VMUserGame> finalList = [];

    if (sortDirection == SortDirection.Desc) {
      finalList..addAll(notAdded)..addAll(added)..addAll(fullyAdded)..addAll(addedExternal);
    } else {
      finalList..addAll(addedExternal)..addAll(fullyAdded)..addAll(added)..addAll(notAdded);
    }

    assert(games.length == finalList.length);
    games = finalList;

    return games;
  }

  static List<VMUserGame> sortBySize(SortDirection sortDirection, List<VMUserGame> games) {
    if (sortDirection == SortDirection.Asc) {
      games.sort((a, b) => a.userGame.gameSize.compareTo(b.userGame.gameSize));
    } else {
      games.sort((a, b) => b.userGame.gameSize.compareTo(a.userGame.gameSize));
    }

    return games;
  }


}