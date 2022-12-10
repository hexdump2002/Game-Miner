import 'dart:io';
import 'dart:math';
import 'crc32.dart';
import 'file_tools.dart';

class SteamTools {

  static Future<List<String>> loadExternalProtons() async {
    late final List<String> protons;

    String homeFolder = FileTools.getHomeFolder();
    String path = "$homeFolder/.local/share/Steam/compatibilitytools.d";
    protons =
    await FileTools.getFolderFilesAsync(path, retrieveRelativePaths: true, recursive: false);

    protons.sort();

    return protons;

  }

  /*static Future<List<String>> loadProtons() async {
    List<String>  builtInProtons = ["proton_experimental##Proton Experimental","proton_7##Proton 7.0-5","proton_63##Proton 6.3-8","proton_513##Proton 5.13-6","proton_5##Proton 5.0-10","proton_411##Proton 4.11-13",
      "proton_42##Proton 4.2-9","proton_316##Proton 3.16-9","proton_37##Proton 3.7-8","proton_hotfix##Proton Hotfix","steamlinuxruntime##Steam Linux Runtime"];
    List<String> protons = await loadExternalProtons();
    protons.addAll(builtInProtons);

    protons.sort();

    return protons;
  }*/


  //The algorithm to generate an app id for steam is not clear. It seems to be dependant on exe path + app name but has a random component
  static int generateAppId(String exePath)  {
    //return Random().nextInt(pow(2, 32) as int);
    //return 0;

    var crc = CRC32.compute(exePath) | 0x80000000;
    print(crc);
    return crc;
  }

  static Future<String> getUserId() async{
    String homeFolder = FileTools.getHomeFolder();
    String path = "$homeFolder/.steam/steam/userdata";

    //Todo, check for empty folder
    var folders = await FileTools.getFolderFilesAsync(path,retrieveRelativePaths: true, recursive: false,regExFilter: "",onlyFolders: true);

    return folders[0];
  }

  static Future<bool> openSteamClient() async{
    var result = await Process.run('steam',[]);
    return result.exitCode==0;
  }

  static Future<bool> closeSteamClient() async{
    var result = await Process.run('killall',["steam"]);
    return result.exitCode==0;
  }
}