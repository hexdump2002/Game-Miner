import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as pathLib;
import 'package:steamdeck_toolbox/logic/Tools/file_tools.dart';
import 'package:path/path.dart' as p;

import 'non_steam_game_exe.dart';

class UserGameExe {
  late bool brokenLink;
  late String relativeExePath;
  late String name;
  late String protonName;
  bool added = false;

  String entryId = "";
  int appId = 0;
  String startDir = "";
  String icon = "";
  String shortcutPath = "";
  String launchOptions = "";
  bool isHidden = false;
  bool allowDdesktopConfig = false;
  bool allowOverlay = false;
  bool openVr = false;
  bool devkit = false;
  String devkitGameId = "";
  String devkitOverrideAppId = "";
  int lastPlayTime = 0;
  String flatPackAppId = "";

  UserGameExe(String enclosingFolderPath, String absoluteExePath, this.brokenLink,{NonSteamGameExe? nonSteamGameExe}) {

    relativeExePath = absoluteExePath.substring(enclosingFolderPath.length+1);

    if(nonSteamGameExe != null)
    {
      entryId = nonSteamGameExe.entryId;
      appId = nonSteamGameExe.appId;
      name = nonSteamGameExe.appName;
      startDir = nonSteamGameExe.startDir;
      icon = nonSteamGameExe.icon;
      shortcutPath = nonSteamGameExe.shortcutPath;
      launchOptions = nonSteamGameExe.launchOptions;
      isHidden = nonSteamGameExe.isHidden;
      allowDdesktopConfig = nonSteamGameExe.allowDdesktopCconfig;
      allowOverlay = nonSteamGameExe.allowOverlay;
      openVr = nonSteamGameExe.openVr;
      devkit = nonSteamGameExe.devkit;
      devkitGameId = nonSteamGameExe.devkitGameId;
      devkitOverrideAppId = nonSteamGameExe.devkitOverrideAppId;
      lastPlayTime = nonSteamGameExe.lastPlayTime;
      flatPackAppId = nonSteamGameExe.flatPackAppId;
    }
    else
    {
      name = p.split(relativeExePath).last;
      appId = Random().nextInt(pow(2,32) as int);
      startDir = p.dirname(absoluteExePath) ;
    }

  }

}

class UserGame {
  late final String path;
  late final String name;
  final List<UserGameExe> exeFileEntries = [];

  UserGame(this.path) {
    List<String> pathComponents = pathLib.split(path);
    name = pathComponents.last;
  }

  void addExeFile(String absoluteFilePath, {NonSteamGameExe? nonSteamGameExe}) {
    exeFileEntries.add(UserGameExe(path, absoluteFilePath,false,nonSteamGameExe:nonSteamGameExe));
  }

  void addExeFiles(List<String> filePaths) {
    filePaths.forEach((filePath) {
      addExeFile(filePath);
    });
  }

  //TODO: Move all this to write to a in memory buffer and then dump it to the file
  Future<int> saveToStream(RandomAccessFile raf, int blockId) async {

    for(int i=0; i<exeFileEntries.length; ++i) {
      UserGameExe ef = exeFileEntries[i];
      if (!ef.added) continue;

      await _writeBlockId(raf, blockId++);

      await _writeInt32BEProperty(raf, "appid", ef.appId);
      await _writeStringProperty(raf,"AppName", ef.name);
      await _writeStringProperty(raf, "Exe", "\"$path/${ef.relativeExePath}\"");
      await _writeStringProperty(raf, "StartDir", "\"${ef.startDir}\"");
      await _writeStringProperty(raf, "icon", "\"${ef.icon}\"");
      await _writeStringProperty(raf, "ShortcutPath", "${ef.shortcutPath}");
      await _writeStringProperty(raf, "LaunchOptions", "\"${ef.launchOptions}\"");
      await _writeBoolProperty(raf, "IsHidden", ef.isHidden);
      await _writeBoolProperty(raf, "AllowDesktopConfig", ef.allowDdesktopConfig);
      await _writeBoolProperty(raf, "AllowOverlay", ef.allowOverlay);
      await _writeBoolProperty(raf, "OpenVR", ef.openVr);
      await _writeBoolProperty(raf, "Devkit", ef.devkit);
      await _writeStringProperty(raf, "DevkitGameID", ef.devkitGameId);
      await _writeStringProperty(raf, "DevkitOverrideAppID", ef.devkitOverrideAppId);
      await _writeInt32BEProperty(raf, "LastPlayTime", ef.lastPlayTime);
      await _writeStringProperty(raf, "FlatpakAppID", ef.flatPackAppId);

      //Tags are not supported (Tags type is 0)
      await raf.writeByte(0);
      await raf.writeString("tags");
      await raf.writeByte(0);
      await raf.writeByte(8);
      await raf.writeByte(8);
    }

    return blockId;
  }

  Future<void> _writeBlockId(RandomAccessFile raf, int num)  async {
    if(num>99) {
      throw Exception("Can't write more than 999 non steam games");
    }

    if(num>9) {
      await raf.writeByte(num~/10 + 0x30);
    }
    else {
      await raf.writeByte(0);
    }


    await raf.writeByte(num%10+0x30);
    await raf.writeByte(0);


  }

  Future<void> _writeStringProperty(RandomAccessFile raf, String propName, String propValue) async {
    await raf.writeByte(0x01);
    await raf.writeString(propName);
    await raf.writeByte(0);
    await raf.writeString(propValue);
    await raf.writeByte(0);
  }
  Future<void> _writeInt32BEProperty(RandomAccessFile raf, String propName, int value) async {
    await raf.writeByte(0x02);

    await raf.writeString(propName);
    await raf.writeByte(0);

    await raf.writeByte((value & 0x000000FF));
    await raf.writeByte((value & 0x0000FF00) >> 8);
    await raf.writeByte((value & 0x00FF0000) >> 16);
    await raf.writeByte((value & 0xFF000000) >> 24);



  }


  Future<void> _writeBoolProperty(RandomAccessFile raf, String propName, bool value) async {
    int intValue = value ? 1 : 0;
    await _writeInt32BEProperty(raf, propName, intValue);

  }
}
