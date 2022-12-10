import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as pathLib;
import 'package:steamdeck_toolbox/logic/Tools/file_tools.dart';
import 'package:path/path.dart' as p;
import 'package:steamdeck_toolbox/logic/Tools/vdf_tools.dart';

import 'non_steam_game_exe.dart';

class UserGameExe {
  late bool brokenLink;
  late String relativeExePath;
  late String name;
  String? protonVersion; //If null there's no proton mapping assigned to this executable
  String protonPriority="0";
  String protonConfig="";
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

  UserGameExe(String enclosingFolderPath, String absoluteExePath, this.brokenLink) {
    relativeExePath = absoluteExePath.substring(enclosingFolderPath.length + 1);

    name = p.split(relativeExePath).last;
    appId = 0;
    startDir = p.dirname(absoluteExePath);

    clearProtonMappingData();
  }

  UserGameExe.asExternal(NonSteamGameExe nonSteamGameExe, {ProtonMapping? protonMapping}) {
    relativeExePath = nonSteamGameExe.exePath;
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

    added = true;

    if(protonMapping!=null) {
      protonVersion=protonMapping.name;
      protonConfig=protonMapping.config;
      protonPriority = protonMapping.priority;
    }
  }

  void fillProtonMappingData(String protonVersion, String protonConfig, String priority) {
    this.protonVersion = protonVersion;
    this.protonConfig = protonConfig;
    protonPriority = priority;
  }

  void clearProtonMappingData() {
    protonVersion = null;
    protonConfig = "";
    protonPriority = "0";

  }

  void fillFromNonSteamGame(NonSteamGameExe nsg, String pathToGame) {
    relativeExePath = nsg.exePath.substring(pathToGame.length+1);
    entryId = nsg.entryId;
    appId = nsg.appId;
    name = nsg.appName;
    startDir = nsg.startDir;
    icon = nsg.icon;
    shortcutPath = nsg.shortcutPath;
    launchOptions = nsg.launchOptions;
    isHidden = nsg.isHidden;
    allowDdesktopConfig = nsg.allowDdesktopCconfig;
    allowOverlay = nsg.allowOverlay;
    openVr = nsg.openVr;
    devkit = nsg.devkit;
    devkitGameId = nsg.devkitGameId;
    devkitOverrideAppId = nsg.devkitOverrideAppId;
    lastPlayTime = nsg.lastPlayTime;
    flatPackAppId = nsg.flatPackAppId;

  }
}

class UserGame {
  late final String path;
  late final String name;
  late final bool external;
  final List<UserGameExe> exeFileEntries = [];

  //User Folders Game (Internal)
  UserGame(this.path) {
    List<String> pathComponents = pathLib.split(path);
    name = pathComponents.last;
    external = false;
  }

  //Game not in User Folders (External)
  UserGame.asExternal() {
    path = "";
    name = "External";
    external = true;
  }

  void addExeFile(String absoluteFilePath) {
    if (external) throw Exception("Can't add an internal exe to an external game");

    exeFileEntries.add(UserGameExe(path, absoluteFilePath, false));
  }

  void addExternalExeFile(NonSteamGameExe nonSteamGameExe, ProtonMapping? pm) {
    if (!external) throw Exception("Can't add an interal exe to an external game");

    var uge = UserGameExe.asExternal(nonSteamGameExe, protonMapping: pm);

    exeFileEntries.add(uge);
  }

  void addExeFiles(List<String> filePaths) {
    filePaths.forEach((filePath) {
      addExeFile(filePath);
    });
  }

  //TODO: Move all this to write to a in memory buffer and then dump it to the file
  Future<int> saveToStream(RandomAccessFile raf, int blockId) async {
    for (int i = 0; i < exeFileEntries.length; ++i) {
      UserGameExe ef = exeFileEntries[i];
      if (!ef.added) continue;

      //Don't really know if this will go into the bloc id
      //await raf.writeByte(0);

      await _writeBlockId(raf, blockId++);

      await _writeInt32BEProperty(raf, "appid", ef.appId);
      await _writeStringProperty(raf, "AppName", ef.name);
      external
          ? await _writeStringProperty(raf, "Exe", "\"${ef.relativeExePath}\"")
          : await _writeStringProperty(raf, "Exe", "\"$path/${ef.relativeExePath}\"");
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

      //00 08 08 00 31 30 00 (02) (Numero 10)
      //00 08 08 00 31 00 (02)    (Numero 1)


      //Tags are not supported (Tags type is 0)
      await raf.writeByte(0);
      await raf.writeString("tags");
      await raf.writeByte(0);
      await raf.writeByte(8);
      await raf.writeByte(8);
    }

    return blockId;
  }

  Future<void> _writeBlockId(RandomAccessFile raf, int num) async {
    await raf.writeByte(0);
    await raf.writeString(num.toString());
    await raf.writeByte(0);
    /*if (num > 999) {
      throw Exception("Can't write more than 999 non steam games");
    }

    if(num>99) {
      await raf.writeByte(num ~/ 100 + 0x30);
    }
    else {
      await raf.writeByte(0);
    }

    if (num > 9) {
      await raf.writeByte(num ~/ 10 + 0x30);
    } else {
      await raf.writeByte(0);
    }

    await raf.writeByte(num % 10 + 0x30);
    await raf.writeByte(0);*/
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
