import 'dart:io';

import 'package:collection/collection.dart';
import 'package:game_miner/data/models/app_storage.dart';
import 'package:game_miner/data/models/steam_user.dart';
import 'package:game_miner/logic/io/text_vdf_file.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../logic/Tools/file_tools.dart';
import '../models/steam_app.dart';



class AppsStorageDataProvider {
  Future<List<AppStorage>> load() async {
    List<AppStorage> appsStorage = [];

    String homeFolder = FileTools.getHomeFolder();

    String searchPath = "$homeFolder/.local/share/Steam/steamapps"; //Changed because of flatpak

    bool searchInCompatData = await FileTools.existsFolder("$searchPath/compatdata");
    bool searchInShaderCacheData = await FileTools.existsFolder("$searchPath/shadercache");

    if(searchInCompatData) {
      var appIds = await FileTools.getFolderFilesAsync("$searchPath/compatdata", retrieveRelativePaths: true, recursive: false,  onlyFolders: true);
      for(String appId in appIds) {
        Map<String, int> metaData = await FileTools.getFolderMetaData("$searchPath/compatdata/$appId", recursive: true);
        appsStorage.add(AppStorage(appId,"UNKNOWN","UNKNOWN",-1, metaData['size']!,false));
      }
    }

    if(searchInShaderCacheData) {
      var appIds = await FileTools.getFolderFilesAsync("$searchPath/shadercache", retrieveRelativePaths: true, recursive: false,  onlyFolders: true);
      for(String appId in appIds){
        AppStorage? as = appsStorage.firstWhereOrNull((element) => element.appId == appId);
        Map<String, int> metaData = await FileTools.getFolderMetaData("$searchPath/shadercache/$appId", recursive: true);
        if(as == null)  {
          appsStorage.add(AppStorage(appId,"UNKNOWN","UNKNOWN",metaData['size']!,-1, false));
        }
        else {
          as.shaderCacheSize = metaData['size']!;
        }
      }
    }

    return appsStorage;
  }


}
