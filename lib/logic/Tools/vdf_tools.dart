import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';

import '../../data/models/compat_tool_mapping.dart';





class VdfTools {
  //Test after a clean steam client
  /*static Future<List<NonSteamGameExe>> loadShortcutsVdf(String path) async {
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
  }*/

  /*static bool _isShortcutsEndOfFile(Uint8List buffer, int from){
    var dataView = ByteData.sublistView(buffer);
    var val = dataView.getUint16(from,Endian.little);
    return val == kEofMark;
  }*/



}
