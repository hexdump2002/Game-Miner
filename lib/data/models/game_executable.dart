import 'package:game_miner/data/models/compat_tool_mapping.dart';
import 'package:game_miner/data/models/steam_shortcut_game.dart';
import 'package:game_miner/logic/Tools/compat_tool_tools.dart';
import 'package:path/path.dart' as p;
import 'package:collection/collection.dart';

import '../../logic/Tools/string_tools.dart';

enum GameExecutableErrorType {InvalidProton, BrokenExecutable}

enum GameExecutableImageType {None, Icon, CoverSmall, CoverMedium, CoverBig, HalfBanner, Banner}

class GameExecutableImages {
  final String? iconImage;
  final String? heroImage;
  final String? coverImage;
  final String? logoImage;
  GameExecutableImages({this.iconImage, this.heroImage, this.coverImage, this.logoImage});
}

class GameExecutableError {
  GameExecutableErrorType type;
  String data;
  GameExecutableError(this.type,this.data);
}

class GameExecutable {
  GameExecutableImages images = GameExecutableImages();
  List<GameExecutableError> errors = [];
  late bool brokenLink;
  late String relativeExePath;
  late String name;

  String compatToolCode = CompatToolTools.notAssigned; //If null there's no proton mapping assigned to this executable
  String compatToolPriority="0";
  String compatToolConfig="";
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
  int devkitOverrideAppId = 0;
  int lastPlayTime = 0;
  String flatPackAppId = "";

  List <String> tags = [];

  GameExecutable(String enclosingFolderPath, String absoluteExePath, this.appId, this.brokenLink) {
    relativeExePath = absoluteExePath.substring(enclosingFolderPath.length + 1);

    name = p.split(relativeExePath).last;
    startDir = p.dirname(absoluteExePath);

    clearCompatToolMappingData();
  }

  bool hasErrorType(GameExecutableErrorType geet) {
    return errors.firstWhereOrNull((element) => element.type == geet)!=null;
  }


  GameExecutable.asExternal(SteamShortcut nonSteamGameExe,this.brokenLink, {CompatToolMapping? protonMapping}) {
    relativeExePath = nonSteamGameExe.exePath;
    entryId = nonSteamGameExe.entryId;
    appId = nonSteamGameExe.appId;
    name = nonSteamGameExe.appName;
    startDir = nonSteamGameExe.startDir;
    icon = nonSteamGameExe.icon;
    shortcutPath = nonSteamGameExe.shortcutPath;
    launchOptions = nonSteamGameExe.launchOptions;
    isHidden = nonSteamGameExe.isHidden;
    allowDdesktopConfig = nonSteamGameExe.allowDesktopConfig;
    allowOverlay = nonSteamGameExe.allowOverlay;
    openVr = nonSteamGameExe.openVr;
    devkit = nonSteamGameExe.devkit;
    devkitGameId = nonSteamGameExe.devkitGameId;
    devkitOverrideAppId = nonSteamGameExe.devkitOverrideAppId;
    lastPlayTime = nonSteamGameExe.lastPlayTime;
    flatPackAppId = nonSteamGameExe.flatPackAppId;
    tags = nonSteamGameExe.tags;

    added = true;

    if(protonMapping!=null) {
      compatToolCode=protonMapping.name;
      compatToolConfig=protonMapping.config;
      compatToolPriority = protonMapping.priority;
    }
  }

  void fillProtonMappingData(String protonCode, String protonConfig, String priority) {
    this.compatToolCode = protonCode;
    this.compatToolConfig = protonConfig;
    compatToolPriority = priority;
  }

  void clearCompatToolMappingData() {
    compatToolCode = CompatToolTools.notAssigned;
    compatToolConfig = "";
    compatToolPriority = "0";

  }

  void fillFromNonSteamGame(SteamShortcut nsg, String pathToGame) {
    relativeExePath = StringTools.removeQuotes(nsg.exePath).substring(pathToGame.length+1);
    entryId = nsg.entryId;
    appId = nsg.appId;
    name = nsg.appName;
    startDir = nsg.startDir;
    icon = nsg.icon;
    shortcutPath = nsg.shortcutPath;
    launchOptions = nsg.launchOptions;
    isHidden = nsg.isHidden;
    allowDdesktopConfig = nsg.allowDesktopConfig;
    allowOverlay = nsg.allowOverlay;
    openVr = nsg.openVr;
    devkit = nsg.devkit;
    devkitGameId = nsg.devkitGameId;
    devkitOverrideAppId = nsg.devkitOverrideAppId;
    lastPlayTime = nsg.lastPlayTime;
    flatPackAppId = nsg.flatPackAppId;
    tags = nsg.tags;
  }

  /*String getAbsolutePath() {
    return p.join(startDir, relativeExePath);
  }*/
}