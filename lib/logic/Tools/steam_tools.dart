import 'dart:math';

import 'file_tools.dart';

class SteamTools {

  static Future<List<String>> loadManuallyInstalledProtons() async {
    late final List<String> protons;

    String homeFolder = FileTools.getHomeFolder();
    String path = "$homeFolder/.local/share/Steam/compatibilitytools.d";
    protons =
    await FileTools.getFolderFilesAsync(path, retrieveRelativePaths: true, recursive: false);

    protons.sort();

    return protons;

  }

  static Future<List<String>> loadProtons() async {
    List<String>  builtInProtons = ["Proton Experimental", "Pronto 6.2", "Proton 5.1"];
    List<String> protons = await loadManuallyInstalledProtons();
    protons.addAll(builtInProtons);

    protons.sort();

    return protons;
  }

  static int generateAppId()  {
    return Random().nextInt(pow(2, 32) as int);
  }

  static Future<String> getUserId() async{
    String homeFolder = FileTools.getHomeFolder();
    String path = "$homeFolder/.steam/steam/userdata";

    //Todo, check for empty folder
    var folders = await FileTools.getFolderFilesAsync(path,retrieveRelativePaths: true, recursive: false,regExFilter: "",onlyFolders: true);

    return folders[0];
  }

}