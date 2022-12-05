import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:steamdeck_toolbox/data/non_steam_game_exe.dart';
import 'package:steamdeck_toolbox/logic/Tools/file_tools.dart';

const int kEofMark = 0x0808;

//"(\t*\"(\d+)\"\n\t*{\n\t*\"name\"\t*\"(.*)\"\n\t*\"config\"\t*\"(.*)\"\n\t*\"priority\"\t*\"\d+\"\n\t*})+"

class ProtonMapping {
  late String id;
  late String name;
  late String config;
  late String priority;

  ProtonMapping(this.id,this.name,this.config,this.priority);
}

class VdfTools {
  //Test after a clean steam client
  static Future<List<NonSteamGameExe>> loadShortcutsVdf(String path) async {
    List<NonSteamGameExe> nonSteamGames = [];

    Uint8List buffer = await File(path).readAsBytes();

    //Skip header
    var seekIndex = 0xB;

    var eof = false;

    while (!eof) {
      //Skipt first byte of block
      seekIndex+=1;

      var retVal = NonSteamGameExe.fromBuffer(buffer, seekIndex, true);
      nonSteamGames.add(retVal.item1);
      seekIndex = retVal.item2;
      eof = _isShortcutsEndOfFile(buffer, seekIndex);
    }

    return nonSteamGames;
  }

  static bool _isShortcutsEndOfFile(Uint8List buffer, int from){
    var dataView = ByteData.sublistView(buffer);
    var val = dataView.getUint16(from,Endian.little);
    return val == kEofMark;
  }


  static List<ProtonMapping>  loadConfigVdf(String path) {
    String relativePath = ".local/share/Steam/config/config.vdf";

    String fullPath = "${FileTools.getHomeFolder()}/$relativePath";
    var file =  File(fullPath)..openSync();
    String json = file.readAsStringSync();

    RegExp r = RegExp(r'"CompatToolMapping"\n\t*{\n(\t*("(\d+)\"\n\t*{\n\t*\"name\"\t*\"(.*)\"\n\t*\"config\"\t*\"(.*)\"\n\t*\"priority\"\t*\"\d+\"\n\t*}\n))+\t*}');
    var match = r.firstMatch(json);
    String compatToolMappingText = (json.substring(match!.start, match!.end));
    r = RegExp(r'"(\d+)\"\n\t*{\n\t*\"name\"\t*\"(.*)\"\n\t*\"config\"\t*\"(.*)\"\n\t*\"priority\"\t*\"(\d+)\"\n\t*}');
    var matches = r.allMatches(compatToolMappingText);

    List<ProtonMapping> protonMappings = [];

    matches.forEach((element) {
      protonMappings.add(ProtonMapping(element.group(1)!, element.group(2)!, element.group(3)!, element.group(4)!));
    });

    return protonMappings;
  }
  
  static void saveConfigVdf(List<ProtonMapping> protonMappings) {

  }
}
