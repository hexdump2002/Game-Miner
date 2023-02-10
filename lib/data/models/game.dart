import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';

import 'package:game_miner/data/models/compat_tool_mapping.dart';
import 'package:game_miner/data/models/steam_shortcut_game.dart';
import 'package:game_miner/data/models/game_executable.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';
import 'package:game_miner/logic/Tools/game_tools.dart';
import 'package:game_miner/logic/Tools/string_tools.dart';
import 'package:path/path.dart' as pathLib;

import '../../logic/Tools/steam_tools.dart';


class Game {
  static int _id = 1;

  final int id;
  late String _path;
  late String name;
  bool isExternal = false;
  int gameSize = 0;
  DateTime creationDate = DateTime.now();
  int fileCount = 0;

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
  /*bool dataCameFromConfigFile() {
    GameExecutable? exe = exeFileEntries.firstWhereOrNull((element) => element.dataFromConfigFile==true);
    return exe != null;
  }*/

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

    //WE WON'T DO THIS HERE. WE REMOVE QUOTES FOR EVERY INTERNAL GAME SO NO NEED TO SEPARATE HERE
    /*//Check if exe is broken or not
    //Some shortcuts come with the params in the executable and this produces an error when trying to check if exe exists
    //So we try to get the real executable path
    String exePath = _getExecutable(absoluteFilePath);*/


    bool exists = FileTools.existsFileSync(absoluteFilePath);
    exeFileEntries.add(GameExecutable(path, absoluteFilePath, SteamTools.generateAppId(absoluteFilePath), !exists));
  }

  Future<void> resolveGameImages(String userId) async{

    for(GameExecutable ge in exeFileEntries) {
      GameExecutableImages images = await GameTools.getGameExecutableImages(ge.appId, userId);
      ge.images = images;
    }
  }

  void addExternalExeFile(SteamShortcut steamShortcut, CompatToolMapping? pm) {
    //Check if exe is broken or not
    //Some shortcuts come with the params in the executable and this produces an error when trying to check if exe exists
    //So we try to get the real executable path
    String exePath = _getExecutable(steamShortcut.exePath);
    bool exists = FileTools.existsFileSync(StringTools.removeQuotes(exePath));
    var uge = GameExecutable.asExternal(steamShortcut, !exists, protonMapping: pm, );
    isExternal = true;
    exeFileEntries.add(uge);
  }

  String _getExecutable(String exePath) {
    String exe= exePath.trim();
    if(exe.isEmpty) return exePath;

    //Type "/usr/bin/flatpak" params
    if(exe.startsWith("\"")) {
      int index = exe.indexOf("\"",1);
      if(index!=exe.length-1) {
        return exe.substring(0, index+1).trim();
      }
    }
    else{
      int index = exe.indexOf(" ",1);
      //If we didn't started with \" but we found a space it means the type is /usr/bin/flatpak params
      if(index!=-1){
        return exe.substring(0, index+1).trim();
      }
    }

    return exePath;

  }


  void addExeFiles(List<String> filePaths) {
    filePaths.forEach((filePath) {
      addExeFile(filePath);
    });
  }


}
