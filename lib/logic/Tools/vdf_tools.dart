import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:game_miner/data/non_steam_game_exe.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';

const int kEofMark = 0x0808;

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

    var file = File(path);
    var fileExists = await file.exists();
    if(!fileExists) return [];

    Uint8List buffer = await file.readAsBytes();

    //Skip header
    var seekIndex = 0xB;

    var eof = false;

    eof = _isShortcutsEndOfFile(buffer, seekIndex);

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


  static Future<List<ProtonMapping>>  loadConfigVdf() async {
    String relativePath = ".local/share/Steam/config/config.vdf";

    String fullPath = "${FileTools.getHomeFolder()}/$relativePath";
    var file =  File(fullPath);
    var fileExists = await file.exists();
    if(!fileExists) return [];

    await file.open();
    String json = await file.readAsString();

    RegExp r = RegExp(r'"CompatToolMapping"\n\t*{\n(\t*("(\d+)\"\n\t*{\n\t*\"name\"\t*\"(.*)\"\n\t*\"config\"\t*\"(.*)\"\n\t*\"priority\"\t*\"\d+\"\n\t*}\n))*\t*}');
    var match = r.firstMatch(json);
    String compatToolMappingText = (json.substring(match!.start, match!.end));
    r = RegExp(r'"(\d+)\"\n\t*{\n\t*\"name\"\t*\"(.*)\"\n\t*\"config\"\t*\"(.*)\"\n\t*\"priority\"\t*\"(\d+)\"\n\t*}');
    var matches = r.allMatches(compatToolMappingText);

    List<ProtonMapping> protonMappings = [];

    matches.forEach((element) {
      protonMappings.add(ProtonMapping(element.group(1)!, element.group(2)!, element.group(3)!, element.group(4)!));
    });

    return Future.value(protonMappings);
  }
  
  static Future<void> saveConfigVdf(List<ProtonMapping> protonMappings) async {

    String relativePath = ".local/share/Steam/config/config.vdf";

    String fullPath = "${FileTools.getHomeFolder()}/$relativePath";
    var file =  File(fullPath);
    await file.open();
    String contents = await file.readAsString();

    int rootIdent = _getCategoryIndentation(contents, "CompatToolMapping");

    RegExp r = RegExp(r'"CompatToolMapping"\n\t*{\n(\t*("(\d+)\"\n\t*{\n\t*\"name\"\t*\"(.*)\"\n\t*\"config\"\t*\"(.*)\"\n\t*\"priority\"\t*\"\d+\"\n\t*}\n))*\t*}');

    String dstString = '"CompatToolMapping"';
    dstString+="\n";
    dstString+=_al("{","\t",rootIdent);
    dstString+="\n";
    protonMappings.forEach((e) {
      dstString = _writeProntoMappingToStr(dstString, e, rootIdent+1);
    });
    dstString+= _al("}","\t",rootIdent);

    contents = contents.replaceAll(r, dstString);

    await file.writeAsString(contents);

  }

  static String _al(String source, String strToAdd, int count) {
    for(int i=0; i<count; ++i) {
      source=strToAdd+source;
    }

    return source;
  }

  static int _getCategoryIndentation(String contents, String category)
  {
    var r = RegExp('\t*"$category"\n\t+{');
    var match = r.firstMatch(contents);

    if(match == null ) return -1;

    String s = contents.substring(match.start,match.end);

    bool finished = false;
    int i = 0;

    if(s[0]!='\t') {
      finished = true;
    }
    else {
      ++i;
      while (!finished && i < s.length) {
        if (s[i] != '\t') {
          finished = true;
        }
        else {
          ++i;
        }
      }
    }

    return finished ? i : -1;
  }

  static String _writeProntoMappingToStr(String dstString, ProtonMapping e, int indent) {
    dstString+=_al('"${e.id}"\n',"\t", indent);
    dstString+=_al("{\n","\t",indent);
    dstString+= _al('"name"\t\t"${e.name}"\n',"\t",indent+1);
    dstString+= _al('"config"\t\t"${e.config}"\n',"\t",indent+1);
    dstString+= _al('"priority"\t\t"${e.priority}"\n',"\t",indent+1);
    dstString+= _al('}',"\t",indent);
    dstString+= "\n";

    return dstString;
  }
}
