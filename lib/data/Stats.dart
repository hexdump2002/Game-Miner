import 'dart:io';

import 'package:steamdeck_toolbox/data/game_folder_stats.dart';
import 'package:steamdeck_toolbox/logic/Tools/VMGameTools.dart';
import 'package:steamdeck_toolbox/logic/blocs/non_steam_games_cubit.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../logic/Tools/file_tools.dart';

class GameFolderStats {
  int fileCount = 0;
  int size = 0;

  GameFolderStats(this.fileCount, this.size);
}

class GameFoldersStats {
  int aggregatedFileCount = 0;
  int aggregatedFilesSize= 0;
  List<GameFolderStats> statsByGame;

  GameFoldersStats(this.aggregatedFileCount, this.aggregatedFilesSize, this.statsByGame);
}

class Stats {

  //late Map<String, GameFolderStats> _folderStats;

  static Map<String, int> getGameStatusStats(List<VMUserGame> games) {
    Map<String, List<VMUserGame>> data = VMGameTools.categorizeGamesByStatus(games);
    return data.map((key, List<VMUserGame> value) => MapEntry<String, int>(key, value.length));
  }

  //TODO: get SD Card
  static Future<Map<String, int>> getStorageStats(List<VMUserGame> games) async {
    final diskSpace = DiskSpace();
    await diskSpace.scan();
    var disks = diskSpace.disks;
    var homeDisk = diskSpace.getDisk(Directory('/home'));
    var sdDisk = diskSpace.getDisk(Directory('/run/media/mmcblk0p1'));

    return {
      "ssdFreeSpace": homeDisk.availableSpace,
      "ssdTotalSpace": homeDisk.totalSize,
      "sdFreeSpace": sdDisk.availableSpace,
      "sdTotalSpace": sdDisk.totalSize
    };
  }



  /*Future<Map<String, GameFolderStats>> _getFolderStats(
    List<String> paths,
    List<VMUserGame> games,
  ) async {
    Map<String, GameFolderStats> stats = {};

    Map<String, List<VMUserGame>> gamesByPath = VMGameTools.categorizeGamesBySourceFolder(games, paths);

    for (var path in gamesByPath.keys) {
      List<VMUserGame> gamesInPath = gamesByPath[path]!;

      var gamesByStatus = VMGameTools.categorizeGamesByStatus(games);

      List<VMUserGame> nonAdded = gamesByStatus['notAdded']!;
      List<VMUserGame> added = gamesByStatus['added']!;
      List<VMUserGame> fullyAdded = gamesByStatus['fullyAdded']!;

      Map<String, int> nonAddedMetaData = await _getGamesFileMetaData(nonAdded);
      Map<String, int> addedMetaData = await _getGamesFileMetaData(added);
      Map<String, int> fullyAddedMetaData = await _getGamesFileMetaData(fullyAdded);

      assert((nonAdded.length + added.length + fullyAdded.length) == games.length);

      const String fcKey = 'fileCount';
      const String szKey = 'size';
      int totalFileCount = nonAddedMetaData[fcKey]! + addedMetaData[fcKey]! + fullyAddedMetaData[fcKey]!;
      int totalSize = nonAddedMetaData[szKey]! + addedMetaData[szKey]! + fullyAddedMetaData[szKey]!;

      var gs = GameFolderStats(
        path: path,
        fileCount: totalFileCount,
        sizeInBytes: totalSize,
        nonAddedGamesCount: nonAdded.length,
        addedGamesCount: added.length,
        fullyAddedGamesCount: fullyAdded.length,
        nonAddedGamesFileCount: nonAddedMetaData[fcKey]!,
        addedGamesFileCount: addedMetaData[fcKey]!,
        fullyAddedGamesFileCount: fullyAddedMetaData[fcKey]!,
        nonAddedGamesSizeInBytes: nonAddedMetaData[szKey]!,
        addedGamesSizeInBytes: addedMetaData[szKey]!,
        fullyAddedGamesSizeInBytes: fullyAddedMetaData[szKey]!,
      );

      stats[path] = gs;

      assert(gs.addedGamesCount + gs.fullyAddedGamesCount + gs.nonAddedGamesCount == games.length);
      assert(gs.addedGamesFileCount + gs.fullyAddedGamesFileCount + gs.nonAddedGamesFileCount == gs.fileCount);
      assert(gs.addedGamesSizeInBytes + gs.nonAddedGamesSizeInBytes + gs.fullyAddedGamesSizeInBytes == gs.sizeInBytes);
    }

    return stats;
  }*/

  //This function returns the folder metadata in the same order the games list is
  static Future<GameFoldersStats> getGamesFolderStats(List<VMUserGame> games) async {
    List<GameFolderStats> statsByGame = [];

    int totalFilesCount = 0;
    int totalFilesSize = 0;

    for (var game in games) {
      var metaData = await FileTools.getFolderMetaData(game.userGame.path, recursive: true);
      var fileCount = metaData['fileCount']!;
      var size = metaData['size']!;
      statsByGame.add(GameFolderStats(fileCount, size));
      totalFilesCount += fileCount;
      totalFilesSize += size;
    }

    return GameFoldersStats(totalFilesCount, totalFilesSize, statsByGame);
  }

  /*int getGameCount() {
    return _folderStats.entries.fold(0, (value, element) => value + element.value.getGameCount());
  }

  int getAddedGameCount() {
    return _folderStats.entries.fold(0, (value, element) => value + element.value.addedGamesCount);
  }

  int getFullyAddedGameCount() {
    return _folderStats.entries.fold(0, (value, element) => value + element.value.fullyAddedGamesCount);
  }

  int getNonAddedGameCount() {
    return _folderStats.entries.fold(0, (value, element) => value + element.value.nonAddedGamesCount);
  }*/

  /*int getSSDTotalSize() {
    return _ssdTotalSizeInBytes;
  }

  int getSSDFreeSpace() {
    return _ssdFreeSizeInBytes;
  }*/
}
