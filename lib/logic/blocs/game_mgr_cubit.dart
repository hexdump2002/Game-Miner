import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:game_miner/data/data_providers/settings_data_provider.dart';
import 'package:game_miner/data/models/compat_tool.dart';
import 'package:game_miner/data/models/steam_user.dart';
import 'package:game_miner/data/repositories/compat_tools_mapping_repository.dart';
import 'package:game_miner/data/repositories/compat_tools_repository.dart';
import 'package:game_miner/data/repositories/games_repository.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:game_miner/data/Stats.dart';
import 'package:game_miner/logic/Tools/steam_tools.dart';
import 'package:game_miner/logic/blocs/settings_cubit.dart';
import 'dart:io' show Directory, File;
import 'package:path/path.dart' as p;
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../data/models/compat_tool_mapping.dart';
import '../../data/models/game_executable.dart';
import '../../data/models/game.dart';
import '../../data/models/settings.dart';
import '../../data/repositories/steam_user_repository.dart';
import '../Tools/game_tools.dart';

part 'game_mgr_state.dart';


enum SortBy { Name, Status }

enum SortDirection { Asc, Desc }

class GameMgrCubit extends Cubit<GameMgrBaseState> {
  List<Game> _games = [];
  List<bool> _gamesFoldingState = [];
  List<CompatTool> _availableCompatTools = [];
  List<CompatToolMapping> _compatToolsMappings = [];

  final CompatToolsRepository _compatToolsRepository = GetIt.I<CompatToolsRepository>();
  final GamesRepository _gameRepository = GetIt.I<GamesRepository>();
  final CompatToolsMappipngRepository _compatToolsMappipngRepository = GetIt.I<CompatToolsMappipngRepository>();

  late final Settings _settings;

  //Some page stats
  int _ssdTotalSizeInBytes = 0;
  int _sdCardTotalInBytes = 0;
  int _ssdFreeSizeInBytes = 0;
  int _sdCardFreeInBytes = 0;
  int _nonAddedGamesCount = 0;
  int _addedGamesCount = 0;
  int _fullyAddedGamesCount = 0;
  int _addedExternalCount = 0;

  List<bool> _sortStates = [true, false, false];
  List<bool> _sortDirectionStates = [false, true];

  //Not the best place to stored. Cubits should be platform agnostics
  final TextEditingController _genericTextController = TextEditingController();

  GameMgrCubit() : super(IninitalState()) {
    _settings  = GetIt.I<SettingsRepository>().getSettings()!;
    loadData(_settings);
  }


  Future<void> loadData(Settings settings) async {
    List<Game>? games = _gameRepository.getGames();

    if(games !=null) {
      _games = games;
    }
    else {
      emit(RetrievingGameData());

      await _refreshStorageSize();
      _games = await _gameRepository.loadGames(_settings.currentUserId, _settings.searchPaths);

      var folderStats = await Stats.getGamesFolderStats(_games);
      assert(folderStats.statsByGame.length == _games.length);

      //Todo: Think about update games in repository.
      for (int i = 0; i < folderStats.statsByGame.length; ++i) {
        _games[i].gameSize = folderStats.statsByGame[i].size;
      }
    }

    _games = GameTools.sortByName(SortDirection.Asc, _games);
    _gamesFoldingState = List.generate(_games.length, (index) => false);
    _availableCompatTools = await _compatToolsRepository.loadCompatTools();
    _compatToolsMappings = await _compatToolsMappipngRepository.loadCompatToolMappings();


    _refreshGameCount();
    emit(GamesDataRetrieved(_games, _gamesFoldingState,getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  refresh(Settings settings) {
    _gameRepository.invalidateGamesCache();
    loadData(settings);
  }

  List<String> getAvailableCompatToolDisplayNames() {
    List<String> ctn = _availableCompatTools.map<String>( (e) => e.displayName).toList();
    ctn.insert(0, "None");
    return ctn;
  }

  String getCompatToolDisplayNameFromCode(String code) {
    if(code == "None") return "None";
    return _availableCompatTools.firstWhere((element) => element.code == code).displayName;
  }

  String getCompatToolCodeFromDisplayName(String displayName) {
    if(displayName == "None") return "None";
    return _availableCompatTools.firstWhere((element) => element.displayName == displayName).code;
  }

  swapExeAdding(GameExecutable ge, String protonCode) {
    ge.added = !ge.added;

    if (ge.added) {
      ge.appId = SteamTools.generateAppId("${ge.startDir}/${ge.relativeExePath}");
      ge.fillProtonMappingData(protonCode, "", "250");
      //_globalStats.MoveGameByStatus(uge, VMGameAddedStatus.Added);
    } else {
      ge.appId = 0;
      ge.clearCompatTOolMappingData();
      //_globalStats.MoveGameByStatus(uge, VMGameAddedStatus.NonAdded);
    }

    _refreshGameCount();

    emit(GamesDataChanged(_games, _gamesFoldingState, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void swapExpansionStateForItem(int index) {
    _gamesFoldingState[index] = !_gamesFoldingState[index];
    emit(GamesFoldingDataChanged(_games, _gamesFoldingState,getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void saveData(Settings settings, {showInfo=true}) async {
    if(showInfo) {
      EasyLoading.show(status: tr("saving_games"));
    }

    await _gameRepository.saveGames(_settings.currentUserId, _games);

    await saveCompatToolMappings();

    if(showInfo) {
      EasyLoading.showSuccess(tr("data_saved"));
    }
  }

  Future<void> saveCompatToolMappings() async {
    Map<int, CompatToolMapping> usedProtonMappings = {};
    _games.forEach((e) {
      e.exeFileEntries.forEach((uge) {
        if (usedProtonMappings.containsKey(uge.appId)) throw Exception("An appId with 2 differnt pronton mappings found!. This is not valid.");
        if (uge.compatToolCode == "None") return;

        usedProtonMappings[uge.appId] = CompatToolMapping(uge.appId.toString(), uge.compatToolCode, uge.compatToolConfig, uge.compatToolPriority!);
      });
    });

    List<CompatToolMapping> compatToolMappings = usedProtonMappings.entries.map((entry) => entry.value).toList();

    await _compatToolsMappipngRepository.saveCompatToolMappings(compatToolMappings);
  }

  setCompatToolDataFor(GameExecutable uge, String value) {
    //assert(value!=null);

    if (value == "None") {
      uge.clearCompatTOolMappingData();
    } else {
      uge.fillProtonMappingData(getCompatToolCodeFromDisplayName(value), "", "250");
    }

    _refreshGameCount();

    emit(GamesDataChanged(_games, _gamesFoldingState,getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void deleteGame(BuildContext context, Game game) {
    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text(tr('delete_game')),
        content: Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(
                Icons.warning,
                color: Colors.red,
                size: 100,
              ),
            ),
            Expanded(
                child: RichText(
                    text: TextSpan(children: [
              TextSpan(text: tr("going_to") , style: TextStyle(color: Colors.black)),
              TextSpan(text: tr("delete_capitals"), style: TextStyle(color: Colors.redAccent)),
              TextSpan(text: " \"${game.name}\"", style: TextStyle(color: Colors.blue)),
              TextSpan(text: tr("from_file_system"), style: TextStyle(color: Colors.black)),
              TextSpan(text: tr("warning_action_undone"), style: TextStyle(color: Colors.red, fontSize: 18, height: 2))
            ]))),
          ],
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: Text("OK"),
            onPressed: () async {
              try {
                //Delete the file
                if (game.isExternal) {
                  await File("${game.path}/${game.exeFileEntries[0].relativeExePath}").delete();
                  _games.removeWhere((element) => element.exeFileEntries[0] == game.exeFileEntries[0]);
                } else {
                  await Directory(game.path).delete(recursive: true);
                  _games.removeWhere((element) => element.path == game.path);
                }

                EasyLoading.showSuccess(tr("game_was_deleted",args:[game.name]));


                await _refreshStorageSize();
                _refreshGameCount();

                //Persist new shortcuts file (TODO: split data saved to just save what is needed instead of everything everytime)
                saveData(_settings, showInfo: false);

                emit(GamesDataChanged(
                    _games,
                    _gamesFoldingState,
                    getAvailableCompatToolDisplayNames(),
                    _nonAddedGamesCount,
                    _addedGamesCount,
                    _fullyAddedGamesCount,
                    _addedExternalCount,
                    _ssdFreeSizeInBytes,
                    _sdCardFreeInBytes,
                    _ssdTotalSizeInBytes,
                    _sdCardTotalInBytes,
                    _sortStates,
                    _sortDirectionStates));
              } catch (e) {
                EasyLoading.showError(tr('game_couldnt_be_deleted',args:[game.name]));
                print(e.toString());
              }

              Navigator.pop(context);
            },
          ),
          BasicDialogAction(
            title: Text(tr("Cancel")),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void renameGame(BuildContext context, Game game) {
    _genericTextController.text = game.name;

    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text(tr("rename_game")),
        content: Padding(
          padding: EdgeInsets.all(8),
          child: TextField(
            controller: _genericTextController,
          ),
        ),
        actions: <Widget>[
          BasicDialogAction(
              title: Text("OK"),
              onPressed: () async {
                var text = _genericTextController.text;
                RegExp r = RegExp(r'^[\w\-. ]+$');

                if (!r.hasMatch(text)) {
                  showPlatformDialog(
                      context: context,
                      builder: (context) => BasicDialogAlert(
                              title: Text(tr('invalid_game_name')),
                              content: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text("The name is not valid. You can use numbers, letters,  and '-','_','.' characters.")),
                              actions: [
                                BasicDialogAction(
                                    title: Text("OK"),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    })
                              ]));
                  return;
                }

                try {
                  var oldPath = game.path;
                  var containerFolder = p.dirname(game.path);

                  game.path = p.join(containerFolder, game.name);

                  await Directory(oldPath).rename(game.path);
                  game.name = _genericTextController.text;

                  emit(GamesDataChanged(
                      _games,
                      _gamesFoldingState,
                      getAvailableCompatToolDisplayNames(),
                      _nonAddedGamesCount,
                      _addedGamesCount,
                      _fullyAddedGamesCount,
                      _addedExternalCount,
                      _ssdFreeSizeInBytes,
                      _sdCardFreeInBytes,
                      _ssdTotalSizeInBytes,
                      _sdCardTotalInBytes,
                      _sortStates,
                      _sortDirectionStates));

                  EasyLoading.showSuccess(tr("game_renamed"));

                } catch (e) {
                  EasyLoading.showError(tr("game_couldnt_be_renamed", args:[game.name]));

                }
                finally{
                  Navigator.pop(context);
                }
              }),
          BasicDialogAction(
            title: Text(tr("Cancel")),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void foldAll() {
    for(int i=0 ;i< _gamesFoldingState.length; ++i) {
      _gamesFoldingState[i] = false;
    }

    emit(GamesDataChanged(_games,_gamesFoldingState, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void sortByName({SortDirection? direction}) {
    _sortStates = [true, false, false];
    _games = GameTools.sortByName(_sortDirectionStates[0] ? SortDirection.Desc : SortDirection.Asc, _games);

    foldAll();

    emit(GamesDataChanged(_games, _gamesFoldingState,getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void sortByStatus() {
    _sortStates = [false, true, false];

    _games = GameTools.sortByStatus(_sortDirectionStates[0] ? SortDirection.Desc : SortDirection.Asc, _games);

    foldAll();

    emit(GamesDataChanged(_games, _gamesFoldingState,getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void sortBySize() {
    _sortStates = [false, false, true];

    _games = GameTools.sortBySize(_sortDirectionStates[0] ? SortDirection.Desc : SortDirection.Asc, _games);

    foldAll();

    emit(GamesDataChanged(_games, _gamesFoldingState,getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  Future<void> _refreshStorageSize() async {
    var data = await Stats.getStorageStats(_games);
    _ssdFreeSizeInBytes = data['ssdFreeSpace']!;
    _ssdTotalSizeInBytes = data['ssdTotalSpace']!;
    _sdCardFreeInBytes = data['sdFreeSpace']!;
    _sdCardTotalInBytes = data['sdTotalSpace']!;
  }

  void _refreshGameCount() {
    var data = Stats.getGameStatusStats(_games);
    _nonAddedGamesCount = data["notAdded"]!;
    _addedGamesCount = data["added"]!;
    _fullyAddedGamesCount = data["fullyAdded"]!;
    _addedExternalCount = data["addedExternal"]!;
  }

  List<bool> getSortStates() {
    return _sortStates;
  }

  List<bool> getSortDirectionStates() {
    return _sortDirectionStates;
  }

  setSortDirection(SortDirection sd) {
    _sortDirectionStates = sd == SortDirection.Asc ? [true, false] : [false, true];

    if (_sortStates[0]) {
      sortByName();
    } else if (_sortStates[1]) {
      sortByStatus();
    } else {
      sortBySize();
    }

    emit(GamesDataChanged(_games, _gamesFoldingState, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }
}