import 'dart:io';

import 'package:steamdeck_toolbox/data/game_folder_stats.dart';
import 'package:steamdeck_toolbox/logic/Tools/VMGameTools.dart';
import 'package:steamdeck_toolbox/logic/blocs/non_steam_games_cubit.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../logic/Tools/file_tools.dart';

class GlobalStats {
  int _ssdTotalSizeInBytes = 0;
  int _sdTotalCardInBytes = 0;
  int _ssdFreeSizeInBytes = 0;
  int _sdFreelCardInBytes = 0;

  late Map<String, GameFolderStats> _folderStats;

  GlobalStats() {}

  Future<void> initialize(List<String> paths, List<VMUserGame> games) async {
    _folderStats = await _getFolderStats(paths, games);
  }
  Future<Map<String, GameFolderStats>> _getFolderStats(List<String> paths, List<VMUserGame> games, ) async{

    Map<String, GameFolderStats> stats = {};

    Map<String, List<VMUserGame>> gamesByPath = VMGameTools.categorizeGamesBySourceFolder(games, paths);

    final diskSpace = DiskSpace();
    await diskSpace.scan();
    var disks = diskSpace.disks;
    var homeDisk = diskSpace.getDisk(Directory('/home'));
    _ssdFreeSizeInBytes = homeDisk.availableSpace;
    _ssdTotalSizeInBytes = homeDisk.totalSize;

    for (var path in gamesByPath.keys) {
      List<VMUserGame> gamesInPath = gamesByPath[path]!;

      var gamesByStatus = VMGameTools.categorizeGamesByStatus(games);

      List<VMUserGame> nonAdded = gamesByStatus['notAdded']!;
      List<VMUserGame> added = gamesByStatus['added']!;
      List<VMUserGame> fullyAdded = gamesByStatus['fullyAdded']!;

      Map<String, int> nonAddedMetaData = await _getGamesFileMetaData(nonAdded);
      Map<String, int> addedMetaData = await _getGamesFileMetaData(added);
      Map<String, int> fullyAddedMetaData = await _getGamesFileMetaData(fullyAdded);

      assert( (nonAdded.length+added.length+fullyAdded.length) == games.length);

      const String fcKey = 'fileCount';
      const String szKey = 'size';
      int totalFileCount = nonAddedMetaData[fcKey]! + addedMetaData[fcKey]! + fullyAddedMetaData[fcKey]!;
      int totalSize = nonAddedMetaData[szKey]! + addedMetaData[szKey]! + fullyAddedMetaData[szKey]!;

      var gs = GameFolderStats(
        path:path,
        fileCount:totalFileCount,
        sizeInBytes:totalSize,
        nonAddedGamesCount: nonAdded.length,
        addedGamesCount:added.length,
        fullyAddedGamesCount: fullyAdded.length,
        nonAddedGamesFileCount: nonAddedMetaData[fcKey]!,
        addedGamesFileCount: addedMetaData[fcKey]!,
        fullyAddedGamesFileCount:fullyAddedMetaData[fcKey]!,
        nonAddedGamesSizeInBytes:nonAddedMetaData[szKey]!,
        addedGamesSizeInBytes:addedMetaData[szKey]!,
        fullyAddedGamesSizeInBytes: fullyAddedMetaData[szKey]!,
      );

      stats[path] = gs;

      assert(gs.addedGamesCount+gs.fullyAddedGamesCount+gs.nonAddedGamesCount== games.length);
      assert(gs.addedGamesFileCount+gs.fullyAddedGamesFileCount+gs.nonAddedGamesFileCount== gs.fileCount);
      assert(gs.addedGamesSizeInBytes+gs.nonAddedGamesSizeInBytes+gs.fullyAddedGamesSizeInBytes== gs.sizeInBytes);
    }

    return stats;
  }

  Future<Map<String, int>> _getGamesFileMetaData(List<VMUserGame> games) async {
    int fileCount = 0;
    int totalSize = 0;

    for (var game in games) {
      var metaData = await FileTools.getFolderMetaData(game.userGame.path,recursive: true);
      fileCount += metaData['fileCount']!;
      totalSize += metaData['size']!;
    }

    //print(await DiskSpace.getFreeDiskSpace);

    return {'fileCount': fileCount, 'size': totalSize};
  }



  int getGameCount() {
    return _folderStats.entries.fold(0,(value, element) => value+element.value.getGameCount());
  }
  int getAddedGameCount() {
    return _folderStats.entries.fold(0,(value, element) => value+element.value.addedGamesCount);
  }
  int getFullyAddedGameCount() {
    return _folderStats.entries.fold(0,(value, element) => value+element.value.fullyAddedGamesCount);
  }
  int getNonAddedGameCount() {
    return _folderStats.entries.fold(0,(value, element) => value+element.value.nonAddedGamesCount);
  }

  int getSSDTotalSize() {
    return _ssdTotalSizeInBytes;
  }

  int getSSDFreeSpace() {
    return _ssdFreeSizeInBytes;
  }
}