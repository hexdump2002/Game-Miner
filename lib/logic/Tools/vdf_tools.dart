import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:steamdeck_toolbox/data/non_steam_game.dart';

const int kEofMark = 0x0808;

class VdfTools {
  //Test after a clean steam client
  static void readShortcuts(String path) async {
    Uint8List buffer = await File("/home/hexdump/.steam/steam/userdata/255842936/config/shortcuts.vdf").readAsBytes();

    //Skip header
    var seekIndex = 0xC;

    var eof = false;

    while (!eof) {
      var o = NonSteamGame.fromBuffer(buffer, seekIndex, true);
      eof = _isEndOfFile(buffer, seekIndex);
    }
  }

  static bool _isEndOfFile(Uint8List buffer, int from){
    var dataView = ByteData.sublistView(buffer);
    var val = dataView.getUint16(from,Endian.little);
    return val == kEofMark;
  }
}
