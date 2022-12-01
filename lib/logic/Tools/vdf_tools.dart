import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:steamdeck_toolbox/data/non_steam_game_exe.dart';

const int kEofMark = 0x0808;

class VdfTools {
  //Test after a clean steam client
  static Future<List<NonSteamGameExe>> readShortcuts(String path) async {
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
      eof = _isEndOfFile(buffer, seekIndex);
    }

    return nonSteamGames;
  }

  static bool _isEndOfFile(Uint8List buffer, int from){
    var dataView = ByteData.sublistView(buffer);
    var val = dataView.getUint16(from,Endian.little);
    return val == kEofMark;
  }
}
