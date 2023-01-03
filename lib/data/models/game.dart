import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:game_miner/data/models/compat_tool_mapping.dart';
import 'package:game_miner/data/models/steam_shortcut_game.dart';
import 'package:game_miner/data/models/game_executable.dart';
import 'package:path/path.dart' as pathLib;

class Game {
  late String path;
  late String name;
  bool isExternal = false;
  int gameSize = 0;
  final List<GameExecutable> exeFileEntries = [];

  //User Folders Game (Internal)
  Game(this.path) {
    List<String> pathComponents = pathLib.split(path);
    name = pathComponents.last;
    isExternal = false;
  }

  //Game not in User Folders (External)
  /*UserLibraryGame.asExternal() {
    path = "";
    name = "External";
    isExternal = true;
  }*/

  void addExeFile(String absoluteFilePath) {
    if (isExternal) throw Exception("Can't add an internal exe to an external game");

    exeFileEntries.add(GameExecutable(path, absoluteFilePath, false));
  }

  void addExternalExeFile(SteamShortcut steamShortcut, CompatToolMapping? pm) {
    var uge = GameExecutable.asExternal(steamShortcut, protonMapping: pm);
    isExternal = true;
    exeFileEntries.add(uge);
  }

  void addExeFiles(List<String> filePaths) {
    filePaths.forEach((filePath) {
      addExeFile(filePath);
    });
  }
}
