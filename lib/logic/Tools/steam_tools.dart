import 'dart:io';
import 'package:game_miner/logic/Tools/vdf_tools.dart';

import 'crc32.dart';
import 'file_tools.dart';
import 'package:path/path.dart' as p;

class SteamTools {

  static String getSteamBaseFolder() {
    String homeFolder = FileTools.getHomeFolder();
    String path = "$homeFolder/.steam/steam";
    return path;
  }

  //The algorithm to generate an app id for steam is not clear. It seems to be dependant on exe path + app name but has a random component
  static int generateAppId(String exePath)  {
    //return Random().nextInt(pow(2, 32) as int);
    //return 0;

    var crc = CRC32.compute(exePath) | 0x80000000;

    return crc;
  }

  static Future<bool> openSteamClient(bool wait) async{
    var future = Process.run('steam', []);

    if(wait) {
      var result = await future;
      return result.exitCode == 0;
    }

    return true;
  }

  static Future<bool> closeSteamClient() async{
    var result = await Process.run('killall',["steam"]);
    return result.exitCode==0;
  }

  static Future<bool> isSteamRunning() async {
    var result = await Process.run('ps',["-A"]);
    return result.stdout.toString().contains(RegExp(r'\ssteam\n'));
  }
}