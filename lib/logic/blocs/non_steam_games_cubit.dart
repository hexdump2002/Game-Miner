import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:meta/meta.dart';
import 'package:steamdeck_toolbox/data/non_steam_game_exe.dart';
import 'package:steamdeck_toolbox/logic/Tools/steam_tools.dart';
import 'package:steamdeck_toolbox/logic/Tools/vdf_tools.dart';
import 'package:steamdeck_toolbox/logic/blocs/settings_cubit.dart';
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
  List<ProtonMapping> _protonMappings = [];

  NonSteamGamesCubit() : super(IninitalState());

  void loadData(String currentUserId, List<String> gamesPath) async {
    emit(RetrievingGameData());

    var result = await Future.wait([_findGames(gamesPath), _loadShortcutsVdfFile(currentUserId), SteamTools.loadProtons(), VdfTools.loadConfigVdf()]);
    var userGames = result[0] as List<UserGame>;
    _games = userGames.map<VMUserGame>((o) => VMUserGame(o, false)).toList();

    _availableProntons = result[2] as List<String>;
    _availableProntons.insert(0,"None");

    _protonMappings = result[3] as List<ProtonMapping>;

    var registeredNonSteamGames = result[1] as List<NonSteamGameExe>;

    UserGame externalGame = UserGame.asExternal();

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
          uge.fillFromNonSteamGame(nsg, e.path);
          uge.added = true;
          finished = true;

          //Find the proton mapping
          ProtonMapping? pm = _protonMappings.firstWhereOrNull((e) => uge.appId.toString() == e.id);
          if(pm!=null) {
            uge.fillProtonMappingData(pm.name, pm.config, pm.priority);
          }
        }

        ++i;
      }

      //We got an exe path that did not come from our list of folders (previously added or source folder was deleted in toolbox)
      if (!finished) {
        //Add external exe and provid proton mapping
        ProtonMapping? pm = _protonMappings.firstWhereOrNull((e) => nsg.appId.toString() == e.id);
        externalGame.addExternalExeFile(nsg, pm);
      }
    }

    if (externalGame.exeFileEntries.isNotEmpty) {
      _games.add(VMUserGame(externalGame, false));
    }

    emit(GamesDataRetrieved(_games, _availableProntons));
  }

  refresh(String currentUserId, List<String> gamesPath) {
    loadData(currentUserId, gamesPath);
  }

  Future<List<NonSteamGameExe>> loadShortcutsVdfFile(String userId) async {
    //we're on linux, just get home folder
    String homeFolder = FileTools.getHomeFolder();
    var vdfAbsolutePath = "$homeFolder.steam/steam/userdata/$userId/config/shortcuts.vdf";

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

  Future<List<NonSteamGameExe>> _loadShortcutsVdfFile(String userId) async {
    //we're on linux, just get home folder
    String os = Platform.operatingSystem;
    Map<String, String> envVars = Platform.environment;
    var vdfAbsolutePath = "${FileTools.getHomeFolder()}/.steam/steam/userdata/$userId/config/shortcuts.vdf";

    return VdfTools.loadShortcutsVdf(vdfAbsolutePath);
  }

  swapExeAdding(UserGameExe uge, String defaultProton) {
    uge.added = !uge.added;

    if (uge.added) {
      uge.appId = SteamTools.generateAppId();
      uge.fillProtonMappingData(defaultProton, "", "250");
    } else {
      uge.appId = 0;
      uge.clearProtonMappingData();
    }
    emit(GamesDataChanged(_games, _availableProntons));
  }

  void swapExpansionStateForItem(int index) {
    _games[index].foldingState = !_games[index].foldingState;
    emit(GamesFoldingDataChanged(_games, _availableProntons));
  }

  void saveData(Settings settings) async {
    EasyLoading.show(status: "Saving shortcuts");
    await saveShortCuts(settings.currentUserId);
    /*EasyLoading.showSuccess("Data saved!. We will synch with Steam now");
    await syncWithSteam(settings);
    EasyLoading.showSuccess("Steam sync succesfull!");
    refresh(settings.currentUserId, settings.searchPaths);
    EasyLoading.showSuccess("Saving proton mappings");*/
    //await saveProntonMappings();

    EasyLoading.showSuccess("Data saved!");
  }

  Future<void> saveShortCuts(String userId) async {
    //Build backup
    String homeFolder = FileTools.getHomeFolder();
    var sourceVdfAbsolutePath = "$homeFolder/.steam/steam/userdata/$userId/config/shortcuts.vdf";
    //await File(sourceVdfAbsolutePath).copy("$homeFolder/.steam/steam/$userId/config/shortcuts2.vdf");

    File file = File(sourceVdfAbsolutePath);
    RandomAccessFile raf = await file.openSync(mode: FileMode.writeOnly);

    //Write header
    await raf.writeByte(0);
    await raf.writeString("shortcuts");
    await raf.writeByte(0);

    int index = 0;
    try {
      for (int i = 0; i < _games.length; ++i) {
        VMUserGame ug = _games[i];
        index = await ug.userGame.saveToStream(raf, index);
      }
      ;

      //End of file
      await raf.writeByte(8);
      await raf.writeByte(8);
    } catch (e) {
      print("An error ocurred while saving shortcuts.vdf file. The error was ${e.toString()}");
    } finally {
      await raf.close();
    }
  }

  Future<void> saveProntonMappings() async {
    Map<int, ProtonMapping> usedProtonMappings = {};
    _games.forEach((e) {
      e.userGame.exeFileEntries.forEach((uge) {
        if (usedProtonMappings.containsKey(uge.appId)) throw Exception("An appId with 2 differnt pronton mappings found!. This is not valid.");
        if (uge.protonVersion == null) return;

        usedProtonMappings[uge.appId] = ProtonMapping(uge.appId.toString(), uge.protonVersion!, uge.protonConfig, uge.protonPriority!);
      });
    });

    List<ProtonMapping> protonMappings = usedProtonMappings.entries.map((entry) => entry.value).toList();

    await VdfTools.saveConfigVdf(protonMappings);
  }

  setProtonDataFor(UserGameExe uge, String? value) {
    assert(value!=null);

    if(value=="None") {
      uge.clearProtonMappingData();
    }
    else{
      uge.fillProtonMappingData(value!,"","250");
    }

    emit(GamesDataChanged(_games, _availableProntons));
  }

  List<bool> isProtonAssignedForGame(VMUserGame vmUserGame)
  {
    bool added = false;
    bool protonAssigned =false;
    int i =0;

    UserGame ug = vmUserGame.userGame;

    while((!added || !protonAssigned) && i<vmUserGame.userGame.exeFileEntries.length) {
      UserGameExe exe = ug.exeFileEntries[i];
      if(exe.added == true) added=true;
      if(exe.protonVersion!=null) protonAssigned = true;

      ++i;
    }

    return [added,protonAssigned];

  }

  void sortByName() {
    _games.sort((a,b) => a.userGame.name.compareTo(b.userGame.name));
    emit(GamesDataChanged(_games, _availableProntons));
  }

  void sortByProtonAssigned() {
    _games.sort((a,b) {
      bool protonAddedA = isProtonAssignedForGame(a)[1];
      bool protonAddedB = isProtonAssignedForGame(b)[1];
      if(protonAddedA==protonAddedB) {
        return 0;
      } else if(!protonAddedA  && protonAddedB) {
        return 1;
      } else {
        return -1;
      }
    });
    emit(GamesDataChanged(_games, _availableProntons));
  }

  void sortBySteamAdded() {
    _games.sort((a,b) {
      bool protonAddedA = isProtonAssignedForGame(a)[0];
      bool protonAddedB = isProtonAssignedForGame(b)[0];
      if(protonAddedA==protonAddedB) {
        return 0;
      } else if(!protonAddedA  && protonAddedB) {
        return 1;
      } else {
        return -1;
      }
    });
    emit(GamesDataChanged(_games, _availableProntons));
  }

  Future<void> syncWithSteam(Settings settings) async {
    SteamTools.openSteamClient();

    await Future.delayed(Duration(seconds: 15));

    if(await SteamTools.closeSteamClient())
      print("Steam closed succesfully");
    else
      print("Error closing steam");

    refresh(settings.currentUserId, settings.searchPaths);
  }

}
