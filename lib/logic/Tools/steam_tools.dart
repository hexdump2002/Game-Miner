import 'dart:io';
import 'package:steamdeck_toolbox/logic/Tools/vdf_tools.dart';

import 'crc32.dart';
import 'file_tools.dart';
import 'package:path/path.dart' as p;

class SteamTools {

  static Future<List<ProtonMapping>> loadExternalProtons() async {

    String homeFolder = FileTools.getHomeFolder();
    String path = "$homeFolder/.local/share/Steam/compatibilitytools.d";
    var protonFolders =  await FileTools.getFolderFilesAsync(path, retrieveRelativePaths: true, recursive: false);

    List<ProtonMapping> protonMappings = [];
    //Read manifests
    for(int i=0; i<protonFolders.length; ++i) {
      var e = protonFolders[i];
      var fullPath = p.join(p.join(path, e),"compatibilitytool.vdf");
      File f = File(fullPath);
      String json = await f.readAsString();

      RegExp r = RegExp(r'"compatibilitytools"\n{\s+"compat_tools"\n\s+{\n\s+"(.*)".*\n\s+{[\S\s]*"display_name"\s+"([a-zA-Z0-9-_ ]+)"');
      var match = r.firstMatch(json);

      if(match==null) throw Exception("Error reading proton manifest for $fullPath");

      protonMappings.add(ProtonMapping(match.group(1)!, match.group(2)!,"","250"));

    };

    protonMappings.sort((ProtonMapping a, ProtonMapping b) => a.name.compareTo(b.name));

    return protonMappings;

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
    //String path = "$homeFolder/.local/Steam/steam/userdata";
    String path = "$homeFolder/.local/share/Steam/userdata"; //Changed because of flatpak

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