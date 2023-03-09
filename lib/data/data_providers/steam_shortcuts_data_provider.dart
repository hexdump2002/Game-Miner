import 'dart:io';
import 'dart:typed_data';

import 'package:game_miner/data/models/steam_shortcut_game.dart';
import 'package:game_miner/logic/io/binary_vdf_file.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../logic/Tools/file_tools.dart';
import '../../logic/Tools/steam_tools.dart';
import '../../logic/io/binary_vdf_buffer.dart';

const int kEofMark = 0x0808;

class SteamShortcutDataProvider {

  SteamShortcutDataProvider();

  Future<List<SteamShortcut>> loadShortcutGames(String userId) async {

    String homeFolder = FileTools.getHomeFolder();
    String shortcutsPath = "${SteamTools.getSteamBaseFolder()}/userdata/$userId/config/shortcuts.vdf";

    List<SteamShortcut> nonSteamGames = [];

    try {
      var file = BinaryVdfBuffer(shortcutsPath);
      file.seek(0xB);

      var eof = false;

      eof = _isShortcutsEndOfFile(file);

      while (!eof) {
        //Skip first byte of block
        file.seek(1, relative: true);

        var instance = SteamShortcut.fromBinaryVdfEntry(file);
        nonSteamGames.add(instance);

        eof = _isShortcutsEndOfFile(file);
      }

      return nonSteamGames;

    }
    on NotFoundException {
      return [];
    }
  }

  Future<void> saveShortcuts(/*String userId,*/ String shortcutsPath, List<SteamShortcut> shortcuts) async {

    String homeFolder = FileTools.getHomeFolder();
    //String shortcutsPath = "$homeFolder/.steam/steam/userdata/$userId/config/shortcuts.vdf";

    BinaryVdfFile file = BinaryVdfFile(shortcutsPath);
    await file.open(FileMode.writeOnly);

    //Write header
    await file.writeByte(0);
    await file.writeString("shortcuts");
    await file.writeByte(0);

    int blockId= 0;

    for (SteamShortcut shortcut in shortcuts) {

      //00 08 08 00 31 30 00 (02) (Numero 10)
      //00 08 08 00 31 00 (02)    (Numero 1)
      await _writeBlockId(file, blockId++);

      await file.writeInt32BEProperty("appid", shortcut.appId);
      await file.writeStringProperty("appname", shortcut.appName, addQuotes:false);
      await file.writeStringProperty( "exe", shortcut.exePath);
      await file.writeStringProperty( "StartDir", shortcut.startDir);
      await file.writeStringProperty( "icon", shortcut.icon);
      await file.writeStringProperty( "ShortcutPath", shortcut.shortcutPath);
      await file.writeStringProperty( "LaunchOptions", shortcut.launchOptions);
      await file.writeBoolProperty( "IsHidden", shortcut.isHidden);
      await file.writeBoolProperty( "AllowDesktopConfig", shortcut.allowDesktopConfig);
      await file.writeBoolProperty( "AllowOverlay", shortcut.allowOverlay);
      await file.writeBoolProperty( "OpenVR", shortcut.openVr);
      await file.writeBoolProperty( "Devkit", shortcut.devkit);
      await file.writeStringProperty( "DevkitGameID", shortcut.devkitGameId);
      await file.writeInt32BEProperty( "DevkitOverrideAppID", shortcut.devkitOverrideAppId);
      await file.writeInt32BEProperty( "LastPlayTime", shortcut.lastPlayTime);
      await file.writeStringProperty("FlatpakAppID", shortcut.flatPackAppId);
      await file.writeListProperty("tags", shortcut.tags);

      await file.writeByte(8);
      await file.writeByte(8);

    }



    await file.writeByte(8);
    await file.writeByte(8);

    await file.close();
  }

  Future<void> _writeBlockId(BinaryVdfFile file, int num) async {
    await file.writeByte(0);
    await file.writeString(num.toString());
    await file.writeByte(0);
  }

  bool _isShortcutsEndOfFile(BinaryVdfBuffer file){
    //Check if we read 08 until the end of the file
    var currentPos = file.getCurrentPointerPos();

    bool eof = file.getCurrentPointerPos() >= file.getSize()-1;

    while(!eof )
    {
      var byte = file.readByte();
      if(byte != 0x8) {
        file.seek(currentPos);
        return false;
      }

      eof = file.getCurrentPointerPos() >= file.getSize()-1;
    }

    return true;
  }

  Future<void> updateShortcut(String shortcutsPath,String userId, SteamShortcut ss ) async {
    var shortcuts = await loadShortcutGames(userId);
    shortcuts.removeWhere((element) => element.appId == ss.appId);
    shortcuts.add(ss);

    await saveShortcuts(shortcutsPath, shortcuts);
  }


}