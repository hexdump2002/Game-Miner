import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:steamdeck_toolbox/data/non_steam_game_exe.dart';
import 'package:steamdeck_toolbox/logic/Tools/steam_tools.dart';
import 'package:steamdeck_toolbox/logic/Tools/vdf_tools.dart';
import 'dart:io' show File, FileMode, Platform, RandomAccessFile;

import '../../data/user_game.dart';
import '../Tools/file_tools.dart';

part 'non_steam_games_state.dart';

class VMUserGame {
  late final UserGame userGame;
  late bool foldingState;

  VMUserGame(this.userGame, this.foldingState);
}

class NonSteamGamesCubit extends Cubit<NonSteamGamesBaseState> {
  List<VMUserGame> _games = [];
  List<String> _availableProntons = [];

  NonSteamGamesCubit() : super(IninitalState());

  void loadData(List<String> gamesPath) async {
    emit(RetrievingGameData());
    var result = await Future.wait([_findGames(gamesPath), _loadShortcutsVdfFile(), SteamTools.loadProtons()]);
    var userGames = result[0] as List<UserGame>;
    _games = userGames.map<VMUserGame>((o) => VMUserGame(o, false)).toList();

    _availableProntons = result[2] as List<String>;

    var registeredNonSteamGames = result[1] as List<NonSteamGameExe>;

    UserGame externalGame = UserGame.asExternal();

    //List<VMUserGame> externalGames = [];
    //Fill all needed data in user games
    for (NonSteamGameExe nsg in registeredNonSteamGames) {
      bool finished = false;
      var i = 0;
      while (!finished && i < userGames.length) {
        UserGame e = _games[i].userGame;
        UserGameExe? uge = e.exeFileEntries.firstWhereOrNull((exe) {
          return "${e.path}/${exe.relativeExePath}" == nsg.exePath;
        });

        if (uge != null) {
          uge.added = true;
          finished = true;
        }

        ++i;
      }

      //We got an exe path that did not come from our list of folders (previously added or source folder was deleted in toolbox)
      if(!finished) {
        /*//search if we have a UserGame with the same startDir to group the exes. With non steam games added manually we can't group by relative path
        UserGame? e = userGames.firstWhereOrNull((ug) => ug.path == nsg.startDir);
        e ??= UserGame(nsg.startDir);*/
        externalGame.addExternalExeFile(nsg);
        /*externalGames.add(VMUserGame(e, false));*/
      }
    }

    if(externalGame.exeFileEntries.isNotEmpty) {
      _games.add(VMUserGame(externalGame,false));
    }
    //_games.addAll(externalGames);


    /*await Future.delayed(const Duration(seconds:5), () {
      emit(GamesDataRetrieved(_games, _availableProntons));
    });*/
    emit(GamesDataRetrieved(_games, _availableProntons));
  }

  refresh(List<String> gamesPath) {
    loadData(gamesPath);
  }

  Future<List<NonSteamGameExe>> loadShortcutsVdfFile() async {
    //we're on linux, just get home folder
    String homeFolder = FileTools.getHomeFolder();
    var vdfAbsolutePath = "$homeFolder.steam/steam/userdata/255842936/config/shortcuts.vdf";

    return VdfTools.loadShortcutsVdf(vdfAbsolutePath);
  }

  Future<List<UserGame>> _findGames(List<String> searchPaths) async {
    final List<UserGame> userGames = [];

    for (String searchPath in searchPaths) {
      List<String> gamesPath = await FileTools.getFolderFilesAsync(searchPath, retrieveRelativePaths: false, recursive: false);
      List<UserGame> ugs = gamesPath.map<UserGame>((e) => UserGame(e)).toList();

      userGames.addAll(ugs);

      //Find exe files
      for (UserGame ug in ugs) {
        List<String> exeFiles = await FileTools.getFolderFilesAsync(ug.path, retrieveRelativePaths: false, recursive: true, regExFilter: r".*\.exe$");
        ug.addExeFiles(exeFiles);
      }
    }

    return userGames;
  }

  Future<List<NonSteamGameExe>> _loadShortcutsVdfFile() async {
    //we're on linux, just get home folder
    String os = Platform.operatingSystem;
    Map<String, String> envVars = Platform.environment;
    var vdfAbsolutePath = "${FileTools.getHomeFolder()}/.steam/steam/userdata/255842936/config/shortcuts.vdf";

    return VdfTools.loadShortcutsVdf(vdfAbsolutePath);
  }

  swapExeAdding(UserGameExe uge) {
    uge.added = !uge.added;

    emit(GamesDataChanged(_games, _availableProntons));
  }

  void swapExpansionStateForItem(int index) {
    _games[index].foldingState = !_games[index].foldingState;
    emit(GamesFoldingDataChanged(_games, _availableProntons));
  }

  void saveShortCuts() async {
    /*_games.forEach((g) {
      print("* ${g.userGame.name}");
      g.userGame.exeFileEntries.forEach((ge) {
        print("-- ${ge.name}");
      });
    });*/

    //Build backup
    String homeFolder = FileTools.getHomeFolder();
    var sourceVdfAbsolutePath = "$homeFolder/.steam/steam/userdata/255842936/config/shortcuts.vdf";
    await File(sourceVdfAbsolutePath).copy("$homeFolder/.steam/steam/userdata/255842936/config/shortcuts2.vdf");

    File file = File(sourceVdfAbsolutePath);
    RandomAccessFile raf = await file.openSync(mode: FileMode.writeOnly);

    //Write header
    await raf.writeByte(0);
    await raf.writeString("shortcuts");
    await raf.writeByte(0);

    int index = 0;
    try {
      for(int i=0; i<_games.length; ++i) {
        VMUserGame ug = _games[i];
        index = await ug.userGame.saveToStream(raf, index);
      };

      //End of file
      await raf.writeByte(8);
      await raf.writeByte(8);
    }
    catch(e) {
      print("An error ocurred while saving shortcuts.vdf file. The error was ${e.toString()}");
    }
    finally {
      await raf.close();
    }

  }

}
