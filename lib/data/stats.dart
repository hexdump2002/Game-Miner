import 'dart:io';

import 'package:game_miner/data/models/game.dart';
import 'package:game_miner/logic/Tools/game_tools.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../logic/Tools/file_tools.dart';

class GameFolderStats {
  int fileCount = 0;
  int size = 0;
  DateTime creationDate;
  GameFolderStats(this.fileCount, this.size, this.creationDate);
}

class AgregatedGameStats {
  int fileCount = 0;
  int totalSize= 0;

  AgregatedGameStats(this.fileCount, this.totalSize);
}

class Stats {

  //late Map<String, GameFolderStats> _folderStats;

  static Map<String, int> getGameStatusStats(List<Game> games) {
    Map<String, List<Game>> data = GameTools.categorizeGamesByStatus(games);
    return data.map((key, List<Game> value) => MapEntry<String, int>(key, value.length));
  }

  //TODO: get SD Card
  static Future<Map<String, int>> getStorageStats(List<Game> games) async {
    final diskSpace = DiskSpace();
    await diskSpace.scan();
    var disks = diskSpace.disks;
    //Originally it was just /home but it didn't worked when I created a flatpak bundle
    var homeDisk = diskSpace.getDisk(Directory('/home/hexdump/.var/app'));
    var sdDisk = diskSpace.getDisk(Directory('/run/media/mmcblk0p1'));

    return {
      "ssdFreeSpace": homeDisk.availableSpace,
      "ssdTotalSpace": homeDisk.totalSize,
      "sdFreeSpace": sdDisk.availableSpace,
      "sdTotalSpace": sdDisk.totalSize
    };
  }

}
