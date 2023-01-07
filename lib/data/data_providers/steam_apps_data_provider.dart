import 'dart:io';

import 'package:collection/collection.dart';
import 'package:game_miner/data/models/steam_user.dart';
import 'package:game_miner/logic/io/text_vdf_file.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../logic/Tools/file_tools.dart';
import '../models/steam_app.dart';



class SteamAppsDataProvider {

  //TODO:This should return all steam apps detected in steamapps. Not just the ones with storage in shadercache or compatdata
  Future<List<SteamApp>> load() async {

    List<SteamApp> apps = [];

    String homeFolder = FileTools.getHomeFolder();

    String searchPath = "$homeFolder/.local/share/Steam/steamapps"; //Changed because of flatpak

    bool searchInCompatData = await FileTools.existsFolder("$searchPath/compatdata");
    bool searchInShaderCacheData = await FileTools.existsFolder("$searchPath/shadercache");

    List<SteamApp> steamApps = await _loadSteamApps(searchPath, searchInCompatData, searchInShaderCacheData);
    return steamApps;

  }

  Future<List<SteamApp>> _loadSteamApps(String searchPath, searchInCompatData, searchInShaderCacheData) async {

    List<SteamApp> apps = [];

    //Todo, check for empty folder
    var steamAppFiles = await FileTools.getFolderFilesAsync(searchPath, retrieveRelativePaths: false, recursive: false, regExFilter: r'.+.acf$', onlyFolders: false);

    for(String steamAppPath in steamAppFiles) {
      TxtVdfFile file = TxtVdfFile();
      file.open(steamAppPath, FileMode.read);
      Map<String, dynamic> obj = await file.read();
      file.close();

      int shaderCacheSize = -1;
      int compatDataSize = -1;

      if(!obj["appstate"].containsKey("appid")) throw NotFoundException("Appid field was not found in app manifest $steamAppPath");

      String appId =  obj["appstate"]["appid"];

      if (searchInCompatData && await FileTools.existsFolder("$searchPath/compatdata/$appId")) {
          Map<String, int> metaData = await FileTools.getFolderMetaData("$searchPath/compatdata/$appId", recursive: true);
          compatDataSize = metaData['size']!;
      }
      if(searchInShaderCacheData && await FileTools.existsFolder("$searchPath/shadercache/$appId")) {
        Map<String, int> metaData = await FileTools.getFolderMetaData("$searchPath/shadercache/$appId",recursive: true);
        shaderCacheSize = metaData['size']!;
      }

      SteamApp app = SteamApp.FromMap(obj['appstate'], shaderCacheSize, compatDataSize, );
      apps.add(app);
    }

    return apps;
  }


}
