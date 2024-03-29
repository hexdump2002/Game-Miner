import 'dart:io';

import 'package:collection/collection.dart';
import 'package:game_miner/data/models/steam_user.dart';
import 'package:game_miner/logic/Tools/steam_tools.dart';
import 'package:game_miner/logic/io/text_vdf_file.dart';
import 'package:universal_disk_space/universal_disk_space.dart';
import 'package:path/path.dart' as p;

import '../../logic/Tools/file_tools.dart';
import '../models/steam_config.dart';


class SteamConfigDataProvider {

  Future<SteamConfig> load() async {

    String basePath = "${SteamTools.getSteamBaseFolder()}/config/"; //Changed because of flatpak


    List<LibraryFolder> libraryFolders = await _loadLibraryFolders(p.join(basePath,'libraryfolders.vdf'));
    List<SteamUser> steamLoggedUsers = await _loadLoggedUsers(p.join(basePath,'loginusers.vdf'));

    for(SteamUser steamUser in steamLoggedUsers) {
      var map = await _getLocalConfigForUser(steamUser.steamId32);
      steamUser.avatarHash = map["userlocalconfigstore"]?["friends"]?[steamUser.steamId32]?["avatar"];
    }

    return SteamConfig(steamLoggedUsers, libraryFolders);
  }

  Future<List<LibraryFolder>> _loadLibraryFolders(String searchPath) async {

    List<LibraryFolder> libraryFolders = [];

    TxtVdfFile file = TxtVdfFile();
    file.open(searchPath, FileMode.read);
    CanonicalizedMap<String,String, dynamic> obj = await file.read();
    file.close();

    CanonicalizedMap<String,String,dynamic> libraryFoldersMap = obj['libraryfolders'];

    for(String key in libraryFoldersMap.keys) {
      CanonicalizedMap<String,String,dynamic> libraryFolderMap = libraryFoldersMap[key];
      String path = libraryFolderMap['path'];
      //CanonicalizedMap<String,String,String> installedAppsMap =  CanonicalizedMap<String,String,String>.from(libraryFolderMap["apps"], (key)=> key.toLowerCase());
      CanonicalizedMap<String,String,dynamic> installedAppsMap = libraryFolderMap["apps"];
      List<LibraryFolderApp> installedApps = [];
      for(String key in installedAppsMap.keys) {
        installedApps.add(LibraryFolderApp(key, installedAppsMap[key]! as String) );
      }

      libraryFolders.add(LibraryFolder(path, installedApps));
    }


    return libraryFolders;
  }

  Future<List<SteamUser>> _loadLoggedUsers(String searchPath) async {

    List<SteamUser> steamUsers = [];

    TxtVdfFile file = TxtVdfFile();
    file.open(searchPath, FileMode.read);
    CanonicalizedMap<String,String, dynamic> obj = await file.read();
    file.close();

    CanonicalizedMap<String,String,dynamic> steamLoggedUsers = obj['users'];

    for(String key in steamLoggedUsers.keys) {
      CanonicalizedMap<String,String,dynamic> userMap = steamLoggedUsers[key];
      steamUsers.add(SteamUser(userMap['accountname']! as String, userMap['personaname']! as String,key));
    }


    return steamUsers;
  }


  Future<Map<String, dynamic>> _getLocalConfigForUser(String userId) async {
    TxtVdfFile file = TxtVdfFile();
    String homeFolder = FileTools.getHomeFolder();
    String path = "${SteamTools.getSteamBaseFolder()}/userdata/$userId/config/localconfig.vdf";
    await file.open(path, FileMode.read);
    CanonicalizedMap<String,String,dynamic> map = await file.read();

    return map;
  }
}
