import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';

import 'package:game_miner/data/models/compat_tool_mapping.dart';
import 'package:game_miner/data/models/steam_shortcut_game.dart';
import 'package:game_miner/data/models/game_executable.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';
import 'package:game_miner/logic/Tools/string_tools.dart';
import 'package:path/path.dart' as pathLib;


class Game {
  static int _id = 1;

  final int id;
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

  //Did we fully or partially configured game exe data from config file?
  bool dataCameFromConfigFile() {
    GameExecutable? exe = exeFileEntries.firstWhereOrNull((element) => element.dataFromConfigFile==true);
    return exe != null;
  }

  bool hasErrors() {
    GameExecutable? exe = exeFileEntries.firstWhereOrNull((element) => element.errors.isNotEmpty);
    return exe != null;
  }

  //User Folders Game (Internal)
  Game(String path, this.name) : id=_id {
    ++_id;
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

    //Check if exe is broken or not
    bool exists = FileTools.existsFileSync(absoluteFilePath);
    exeFileEntries.add(GameExecutable(path, absoluteFilePath,!exists));
  }

  void addExternalExeFile(SteamShortcut steamShortcut, CompatToolMapping? pm) {
    bool exists = FileTools.existsFileSync(StringTools.removeQuotes(steamShortcut.exePath));
    var uge = GameExecutable.asExternal(steamShortcut, !exists, protonMapping: pm, );
    isExternal = true;
    exeFileEntries.add(uge);
  }

  void addExeFiles(List<String> filePaths) {
    filePaths.forEach((filePath) {
      addExeFile(filePath);
    });
  }


}
