import 'dart:io';

import 'package:collection/collection.dart';
import 'package:game_miner/data/models/steam_user.dart';
import 'package:game_miner/logic/io/text_vdf_file.dart';
import 'package:universal_disk_space/universal_disk_space.dart';
import 'package:path/path.dart' as p;

import '../../logic/Tools/file_tools.dart';
import '../models/steam_config.dart';


class SteamConfigDataProvider {

  Future<SteamConfig> load() async {

    String homeFolder = FileTools.getHomeFolder();
    String basePath = "$homeFolder/.local/share/Steam/config/"; //Changed because of flatpak

    List<LibraryFolder> libraryFolders = await _loadLibraryFolders(p.join(basePath,'libraryfolders.vdf'));
    List<SteamUser> steamLoggedUsers = await _loadLoggedUsers(p.join(basePath,'loginusers.vdf'));


    return SteamConfig(steamLoggedUsers, libraryFolders);
  }

  Future<List<LibraryFolder>> _loadLibraryFolders(String searchPath) async {

    List<LibraryFolder> libraryFolders = [];

    TxtVdfFile file = TxtVdfFile();
    file.open(searchPath, FileMode.read);
    Map<String, dynamic> obj = await file.read();
    file.close();

    Map<String,dynamic> libraryFoldersMap = obj['libraryfolders'];

    for(String key in libraryFoldersMap.keys) {
      Map<String,dynamic> libraryFolderMap = libraryFoldersMap[key];
      String path = libraryFolderMap['path'];
      Map<String,String> installedAppsMap =  Map<String,String>.from(libraryFolderMap["apps"]);
      List<LibraryFolderApp> installedApps = [];
      for(String key in installedAppsMap.keys) {
        installedApps.add(LibraryFolderApp(key, installedAppsMap[key]!));
      }

      libraryFolders.add(LibraryFolder(path, installedApps));
    }


    return libraryFolders;
  }

  Future<List<SteamUser>> _loadLoggedUsers(String searchPath) async {

    List<SteamUser> steamUsers = [];

    TxtVdfFile file = TxtVdfFile();
    file.open(searchPath, FileMode.read);
    Map<String, dynamic> obj = await file.read();
    file.close();

    Map<String,dynamic> steamLoggedUsers = obj['users'];

    for(String key in steamLoggedUsers.keys) {
      Map<String,dynamic> userMap = Map<String,String>.from(steamLoggedUsers[key]);
      steamUsers.add(SteamUser(userMap['accountname']!, userMap['personaname']!,key));
    }


    return steamUsers;
  }
}
