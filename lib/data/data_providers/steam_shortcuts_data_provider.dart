import 'dart:typed_data';

import 'package:game_miner/data/models/steam_shortcut_game.dart';
import 'package:game_miner/logic/io/binary_vdf_file.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../logic/Tools/file_tools.dart';
import '../../logic/io/binary_vdf_buffer.dart';

const int kEofMark = 0x0808;

class SteamShortcutDataProvider {

  SteamShortcutDataProvider();

  Future<List<SteamShortcut>> loadShortcutGames(String userId) async {

    String homeFolder = FileTools.getHomeFolder();
    String shortcutsPath = "$homeFolder/.local/share/Steam/userdata/$userId/config/shortcuts.vdf";

    List<SteamShortcut> nonSteamGames = [];

    try {
      var file = BinaryVdfBuffer(shortcutsPath);
      file.seek(0xB);

      var eof = false;

      eof = _isShortcutsEndOfFile(file);

      while (!eof) {
        //Skipt first byte of block
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

  Future<void> saveShortcuts(String userId, List<SteamShortcut> shortcuts) async {

    String homeFolder = FileTools.getHomeFolder();
    String shortcutsPath = "$homeFolder.steam/steam/userdata/$userId/config/shortcuts.vdf";

    BinaryVdfFile file = BinaryVdfFile(shortcutsPath);
    file.open();

    int blockId= 0;

    for (SteamShortcut shortcut in shortcuts) {

      await _writeBlockId(file, blockId++);

      await file.writeInt32BEProperty("appid", shortcut.appId);
      await file.writeStringProperty("AppName", shortcut.appName, addQuotes:false);
      await file.writeStringProperty( "Exe", shortcut.exePath);
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

      //00 08 08 00 31 30 00 (02) (Numero 10)
      //00 08 08 00 31 00 (02)    (Numero 1)

      file.writeByte(8);
      file.writeByte(8);
    }
  }

  Future<void> _writeBlockId(BinaryVdfFile file, int num) async {
    await file.writeByte(0);
    await file.writeString(num.toString());
    await file.writeByte(0);
  }

  bool _isShortcutsEndOfFile(BinaryVdfBuffer file){
    var val = file.readUint16(Endian.little);

    //rollback pointer
    file.seek(-2, relative: true);

    return val == kEofMark;
  }


}