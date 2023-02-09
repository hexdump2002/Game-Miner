import 'dart:io';

import 'package:collection/collection.dart';
import 'package:game_miner/data/models/steam_user.dart';
import 'package:game_miner/logic/io/text_vdf_file.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../logic/Tools/file_tools.dart';
import '../models/steam_app.dart';



class SteamAppsDataProvider {

  //TODO:This should return all steam apps detected in steamapps. Not just the ones with storage in shadercache or compatdata
  Future<List<SteamApp>> load(List<String> libraryFolders) async {

    List<SteamApp> apps = [];

    String homeFolder = FileTools.getHomeFolder();

    List<SteamApp> steamApps = await _loadSteamApps(libraryFolders);
    return steamApps;

  }

  Future<List<SteamApp>> _loadSteamApps(List<String> libraryFolders) async {

    List<SteamApp> apps = [];


    for(String path in libraryFolders) {
      String steamAppsFolder = "$path/steamapps";

      //Todo, check for empty folder
      var steamAppFiles = await FileTools.getFolderFilesAsync(
          steamAppsFolder, retrieveRelativePaths: false, recursive: false, regExFilter: r'.+.acf$', onlyFolders: false);

      if (steamAppFiles != null) {
        for (String steamAppPath in steamAppFiles) {
          TxtVdfFile file = TxtVdfFile();
          file.open(steamAppPath, FileMode.read);
          CanonicalizedMap<String, String, dynamic> obj = await file.read();
          file.close();

          int shaderCacheSize = -1;
          int compatDataSize = -1;

          if (!obj["appstate"].containsKey("appid")) throw NotFoundException("Appid field was not found in app manifest $steamAppPath");

          String appId = obj["appstate"]["appid"];

          String appCompatdataPath = "$steamAppsFolder/compatdata/$appId";
          String appShaderCacheDataPath = "$steamAppsFolder/shadercache/$appId";
          bool searchInCompatData = await FileTools.existsFolder(appCompatdataPath);
          bool searchInShaderCacheData = await FileTools.existsFolder(appShaderCacheDataPath);

          if (searchInCompatData) {
            Map<String, int> metaData = await FileTools.getFolderMetaData(appCompatdataPath, recursive: true);
            compatDataSize = metaData['size']!;
          }
          if (searchInShaderCacheData) {
            Map<String, int> metaData = await FileTools.getFolderMetaData(appShaderCacheDataPath, recursive: true);
            shaderCacheSize = metaData['size']!;
          }

          SteamApp app = SteamApp.FromMap(obj['appstate'], searchInShaderCacheData, searchInCompatData, shaderCacheSize, compatDataSize);
          apps.add(app);
        }
      }
    }

    return apps;
  }


}
