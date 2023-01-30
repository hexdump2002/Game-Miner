import 'dart:io';

import 'package:collection/collection.dart';
import 'package:game_miner/data/models/app_storage.dart';
import 'package:game_miner/data/models/steam_user.dart';
import 'package:game_miner/logic/io/text_vdf_file.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../logic/Tools/file_tools.dart';
import '../models/steam_app.dart';



class AppsStorageDataProvider {
  Future<List<AppStorage>> load(List<String> searchPaths) async {
    List<AppStorage> appsStorage = [];

    for(String path in searchPaths) {
      var searchPath = path;

      String compatdataPath = "$searchPath/steamapps/compatdata";
      String shaderCacheDataPath = "$searchPath/steamapps/shadercache";
      bool searchInCompatData = await FileTools.existsFolder(compatdataPath);
      bool searchInShaderCacheData = await FileTools.existsFolder(shaderCacheDataPath);

      if (searchInCompatData) {
        var appIds = await FileTools.getFolderFilesAsync(compatdataPath, retrieveRelativePaths: true, recursive: false, onlyFolders: true);
        for (String appId in appIds) {
          Map<String, int> metaData = await FileTools.getFolderMetaData("$compatdataPath/$appId", recursive: true);
          appsStorage.add(AppStorage(
              appId,
              "",
              "",
              StorageType.CompatData,
              metaData['size']!,
              GameType.NonSteam,
              true));
        }
      }

      if (searchInShaderCacheData) {
        var appIds = await FileTools.getFolderFilesAsync(shaderCacheDataPath, retrieveRelativePaths: true, recursive: false, onlyFolders: true);
        for (String appId in appIds) {
          AppStorage? as = appsStorage.firstWhereOrNull((element) => element.appId == appId);
          Map<String, int> metaData = await FileTools.getFolderMetaData("$shaderCacheDataPath/$appId", recursive: true);
          //if(as == null)  {
          appsStorage.add(AppStorage(
              appId,
              "",
              "",
              StorageType.ShaderCache,
              metaData['size']!,
              GameType.NonSteam,
              true));
          /*}
          else {
            as.shaderCacheSize = metaData['size']!;
          }*/
        }
      }
    }

    return appsStorage;
  }


}
