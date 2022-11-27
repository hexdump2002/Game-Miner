import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:steamdeck_toolbox/data/non_steam_game.dart';
import 'package:steamdeck_toolbox/logic/Tools/vdf_tools.dart';
import 'dart:io' show Platform;

import '../../data/user_game.dart';
import '../Tools/file_tools.dart';

part 'non_steam_games_state.dart';

class NonSteamGamesCubit extends Cubit<NonSteamGamesBaseState> {
  NonSteamGamesCubit() : super(RetrievingGameData());

  void loadData(List<String> gamesPath) async {
    emit(RetrievingGameData());
    var result = await Future.wait([_findGames(gamesPath), _loadShortcutsVdfFile()]);
    var userGames = result[0] as List<UserGame>;
    var registeredNonSteamGames = result[1] as List<NonSteamGame>;

    //Fill all needed data in user games
    for (NonSteamGame nsg in registeredNonSteamGames) {
      bool finished = false;
      var i = 0;
      while (!finished && i < userGames.length) {
        UserGame e = userGames[i];
        UserGameExe? uge = e.exeFileEntries.firstWhereOrNull((exe) {
          return e.path + exe.relativeExePath == nsg.exePath;
        });

        if (uge != null) uge.added = true;

        ++i;
      }
    }

    emit(GamesDataRetrieved(userGames));
  }

  Future<List<NonSteamGame>> loadShortcutsVdfFile() async {
    //we're on linux, just get home folder
    String os = Platform.operatingSystem;
    Map<String, String> envVars = Platform.environment;
    var vdfAbsolutePath = envVars['HOME']! + ".steam/steam/userdata/255842936/config/shortcuts.vdf";

    return VdfTools.readShortcuts(vdfAbsolutePath);
  }

  Future<List<UserGame>> _findGames(List<String> searchPaths) async {
    final List<UserGame> userGames = [];

    for (String searchPath in searchPaths) {
      List<String> gamesPath = await FileTools.getFolderFilesAsync(searchPath, retrieveRelativePaths: false, recursive: false);
      List<UserGame> ugs = gamesPath.map<UserGame>((e) => UserGame(e)).toList();

      userGames.addAll(ugs);

      //Find exe files
      for (UserGame ug in ugs) {
        List<String> exeFiles = await FileTools.getFolderFilesAsync(ug.path, retrieveRelativePaths: true, recursive: true, regExFilter: r".*\.exe$");
        ug.addExeFiles(exeFiles);
      }
    }

    return userGames;
  }

  Future<List<NonSteamGame>> _loadShortcutsVdfFile() async {
    //we're on linux, just get home folder
    String os = Platform.operatingSystem;
    Map<String, String> envVars = Platform.environment;
    var vdfAbsolutePath = envVars['HOME']! + "/.steam/steam/userdata/255842936/config/shortcuts.vdf";

    return VdfTools.readShortcuts(vdfAbsolutePath);
  }
}
