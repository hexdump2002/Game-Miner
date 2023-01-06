import 'dart:io';

import 'package:game_miner/data/models/steam_user.dart';
import 'package:game_miner/logic/io/text_vdf_file.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../logic/Tools/file_tools.dart';
import '../models/steam_app.dart';



class SteamAppsDataProvider {
  Future<List<SteamApp>> load() async {

    List<SteamApp> apps = [];

    String homeFolder = FileTools.getHomeFolder();

    String searchPath = "$homeFolder/.local/share/Steam/steamapps"; //Changed because of flatpak

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

      if(await FileTools.existsFolder("$searchPath/compatdata/$appId")) {
        Map<String, int> metaData = await FileTools.getFolderMetaData("$searchPath/compatdata/$appId",recursive: true);
        compatDataSize = metaData['size']!;
      }
      bool pepe = await FileTools.existsFile("$searchPath/shadercache/$appId");
      if(await FileTools.existsFolder("$searchPath/shadercache/$appId")) {
        Map<String, int> metaData = await FileTools.getFolderMetaData("$searchPath/shadercache/$appId",recursive: true);
        shaderCacheSize = metaData['size']!;
      }

      SteamApp app = SteamApp.FromMap(obj['appstate'], shaderCacheSize, compatDataSize, );
      apps.add(app);
    }

    return apps;
  }
}
