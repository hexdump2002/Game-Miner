import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:game_miner/data/models/compat_tool_mapping.dart';
import 'package:game_miner/data/models/steam_shortcut_game.dart';
import 'package:game_miner/data/models/game_executable.dart';
import 'package:path/path.dart' as pathLib;

class Game {
  late String _path;
  late String name;
  bool isExternal = false;
  int gameSize = 0;
  final List<GameExecutable> exeFileEntries = [];

  String get path => _path;
  set path(String value) {

    for(GameExecutable ex in exeFileEntries) {
      if(ex.startDir.startsWith("$_path")) {
        ex.startDir=ex.startDir.replaceFirst(_path, value);
      }
    }
    _path= value;

  }

  //User Folders Game (Internal)
  Game(String path, this.name)  {
    _path = path;
    isExternal = false;
  }

  factory Game.fromPath(String folderPath) {
    List<String> pathComponents = pathLib.split(folderPath);
    String name = pathComponents.last;

    var game = Game(folderPath, name);
    return game;
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
