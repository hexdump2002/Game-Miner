import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:collection/collection.dart';
import 'package:game_miner/data/models/compat_tool.dart';
import 'package:game_miner/data/repositories/apps_storage_repository.dart';

import 'package:game_miner/data/repositories/compat_tools_repository.dart';
import 'package:game_miner/data/repositories/game_miner_data_repository.dart';
import 'package:game_miner/data/repositories/games_repository.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';
import 'package:game_miner/logic/Tools/string_tools.dart';
import 'package:get_it/get_it.dart';

import 'package:game_miner/data/Stats.dart';
import 'package:game_miner/logic/Tools/steam_tools.dart';

import 'dart:io' show Directory, File;
import 'package:path/path.dart' as p;

import 'package:url_launcher/url_launcher.dart';

import '../../data/models/app_storage.dart';
import '../../data/models/compat_tool_mapping.dart';
import '../../data/models/game_executable.dart';
import '../../data/models/game.dart';
import '../../data/models/game_miner_data.dart';
import '../../data/models/settings.dart';
import '../Tools/game_tools.dart';

part 'game_mgr_state.dart';

enum SortDirection { Asc, Desc }

class GameViewExecutableErrors {
  int executableIndex;
  List<String> errors = [];

  GameViewExecutableErrors(this.executableIndex);
}

class GameView {
  Game game;
  bool isExpanded;
  bool modified;
  GameView(this.game, this.isExpanded, this.modified);
}

class GameMgrCubit extends Cubit<GameMgrBaseState> {
  List<Game> _baseGames = [];
  List<GameView> _gameViews = [];
  List<GameView> _filteredGames = [];
  List<CompatTool> _availableCompatTools = [];

  final CompatToolsRepository _compatToolsRepository = GetIt.I<CompatToolsRepository>();
  final GamesRepository _gameRepository = GetIt.I<GamesRepository>();

  //final CompatToolsMappingRepository _compatToolsMappipngRepository = GetIt.I<CompatToolsMappingRepository>();

  late final UserSettings _currentUserSettings;
  late final Settings _settings;

  @override
  bool get wantKeepAlive => true;

  //Some page stats
  int _ssdTotalSizeInBytes = 0;
  int _sdCardTotalInBytes = 0;
  int _ssdFreeSizeInBytes = 0;
  int _sdCardFreeInBytes = 0;
  int _nonAddedGamesCount = 0;
  int _addedGamesCount = 0;
  int _fullyAddedGamesCount = 0;
  int _addedExternalCount = 0;

  List<bool> _sortStates = [true, false, false, false];
  List<bool> _sortDirectionStates = [false, true];

  //Not the best place to stored. Cubits should be platform agnostics
  final TextEditingController _genericTextController = TextEditingController();

  GameMgrCubit() : super(IninitalState()) {
    _settings = GetIt.I<SettingsRepository>().getSettings();
    _currentUserSettings = _settings!.getUserSettings(_settings!.currentUserId)!;
    loadData(_currentUserSettings);
  }

  Future<void> loadData(UserSettings settings) async {
    final stopwatch = Stopwatch()..start();

    List<Game>? games = _gameRepository.getGames();

    /*if (games != null) {
      _baseGames = games;
    } else {*/
    if (games == null) {
      print("Cache Miss. Loading Games");
      emit(RetrievingGameData());

      /*_baseGames*/
      games = await _gameRepository.loadGames(_settings.currentUserId, _currentUserSettings.searchPaths);

      var folderStats = await Stats.getGamesFolderStats(/*_baseGames*/ games);
      assert(folderStats.statsByGame.length == /*_baseGames*/ games.length);

      for (int i = 0; i < folderStats.statsByGame.length; ++i) {
        games[i].gameSize = folderStats.statsByGame[i].size;
        _gameRepository.update(games[i]);
        //_baseGames[i].gameSize = folderStats.statsByGame[i].size;
      }
    }

    _baseGames = GameTools.sortByName(SortDirection.Asc, games);
    _gameViews = _generateGameViews(_baseGames);
    _filteredGames = [];
    _filteredGames.addAll(_gameViews);
    _availableCompatTools = await _compatToolsRepository.loadCompatTools();

    _refreshGameCount();
    await _refreshStorageSize();

    emit(GamesDataRetrieved(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));

    stopwatch.stop();
    print('[Logic] Time taken to execute method: ${stopwatch.elapsed}');
  }

  List<GameView> _generateGameViews(List<Game> games) {
    List<GameView> gameViews = [];
    for (Game g in games) {
      GameTools.handleGameExecutableErrorsForGame(g);
      bool modified =g.dataCameFromConfigFile();

      gameViews.add(GameView(g, false,modified));
    }
    return gameViews;
  }

  refresh() {
    _gameRepository.invalidateGamesCache();
    loadData(_currentUserSettings);
  }

  List<String> getAvailableCompatToolDisplayNames() {
    List<String> ctn = _availableCompatTools.map<String>((e) => e.displayName).toList();
    ctn.insert(0, "None");
    return ctn;
  }

  String getCompatToolDisplayNameFromCode(String code) {
    if (code.isEmpty || code == "None") return "None";
    CompatTool? ct = _availableCompatTools.firstWhereOrNull((element) => element.code == code);
    if (ct == null) return "None";

    return ct.displayName;
  }

  String getCompatToolCodeFromDisplayName(String displayName) {
    if (displayName == "None") return "None";
    CompatTool? ct = _availableCompatTools.firstWhereOrNull((element) => element.displayName == displayName);
    if (ct == null) return "Node";

    return ct.code;
  }

  swapExeAdding(GameView gv, GameExecutable ge) {
    ge.added = !ge.added;
    gv.modified = true;

    if (ge.added) {
      ge.appId = SteamTools.generateAppId("${ge.startDir}/${ge.relativeExePath}");
      ge.fillProtonMappingData(_currentUserSettings.defaultCompatTool, "", "250");
      //_globalStats.MoveGameByStatus(uge, VMGameAddedStatus.Added);
    } else {
      ge.appId = 0;
      ge.clearCompatToolMappingData();
      //_globalStats.MoveGameByStatus(uge, VMGameAddedStatus.NonAdded);
    }

    GameTools.handleGameExecutableErrorsForGame(gv.game);

    _refreshGameCount();

    emit(GamesDataChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void swapExpansionStateForItem(int index) {
    _filteredGames[index].isExpanded = !_filteredGames[index].isExpanded;
    emit(GamesFoldingDataChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  Future<void> trySave(BuildContext context) async {
    if(GameTools.doGamesHaveErrors(_baseGames)){
      showSimpleDialog(context,tr('warning'), tr('cant_save_with_errors'));
      return;
    }

    if (await SteamTools.isSteamRunning()) {
      showSteamActiveWhenSaving(context, () {
        _saveData();
      });
    } else {
      _saveData();
    }

    //Reset all game changes
    for(GameView gv in _gameViews) {
      gv.modified = false;
    }
    //This is needed because when a game has an error with proton. It is reset to none but not saved
    _refreshGameCount();

    emit(GamesDataChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));

  }

  void _saveData({showInfo = true}) async {
    if (showInfo) {
      EasyLoading.show(status: tr("saving_games"));
    }

    String homeFolder = FileTools.getHomeFolder();
    String shortcutsPath = "$homeFolder/.steam/steam/userdata/${_settings.currentUserId}/config/shortcuts.vdf";

    await _gameRepository.saveGames(shortcutsPath, _baseGames, _currentUserSettings.backupsEnabled, _currentUserSettings.maxBackupsCount);

    if (showInfo) {
      EasyLoading.showSuccess(tr("data_saved"));
    }
/*
    _refreshGameCount();

    emit(GamesDataChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));*/
  }

  void setCompatToolDataFor(GameView gv, GameExecutable uge, String value) {
    //assert(value!=null);

    if (value == "None") {
      uge.clearCompatToolMappingData();
    } else {
      uge.fillProtonMappingData(getCompatToolCodeFromDisplayName(value), "", "250");
    }

    gv.modified = true;

    GameTools.handleGameExecutableErrorsForGame(gv.game);
    _refreshGameCount();

    emit(GamesDataChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void tryDeleteGame(BuildContext context, Game game) async{
    if (await SteamTools.isSteamRunning()) {
    showSteamActiveWhenSaving(context, () {
      _deleteGame(context, game);
    });
    } else {
      _deleteGame(context, game);
    }
  }

  void _deleteGame(BuildContext context, Game game) {
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
              TextSpan(text: tr("going_to"), style: TextStyle(color: Colors.black)),
              TextSpan(text: tr("delete_capitals"), style: TextStyle(color: Colors.redAccent)),
              TextSpan(text: tr("delete_game_dialog_2", args: ['${game.name}']), style: TextStyle(color: Colors.black)),
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
                  _baseGames.removeWhere((element) => element.exeFileEntries[0] == game.exeFileEntries[0]);
                } else {
                  await Directory(game.path).delete(recursive: true);
                  _baseGames.removeWhere((element) => element.path == game.path);
                  _gameViews.removeWhere((element) => element.game.path == game.path);
                  _filteredGames.removeWhere((element) => element.game.path == game.path);
                }

                EasyLoading.showSuccess(tr("game_was_deleted", args: [game.name]));

                await _refreshStorageSize();
                _refreshGameCount();

                //Persist new shortcuts file (TODO: split data saved to just save what is needed instead of everything everytime)

                //Todo:Fix this!
                //saveData(showInfo: false);

                emit(GamesDataChanged(
                    _filteredGames,
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
                EasyLoading.showError(tr('game_couldnt_be_deleted', args: [game.name]));
                print(e.toString());
              }

              Navigator.pop(context);
            },
          ),
          BasicDialogAction(
            title: Text(tr("cancel")),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> tryRenameGame(BuildContext context, Game game) async {
    if(game.hasErrors()){
      showSimpleDialog(context,tr('warning'), tr('cant_rename_with_errors'));
      return;
    }

    if (await SteamTools.isSteamRunning()) {
      showSteamActiveWhenSaving(context, () {
        _renameGame(context, game);
      });
    } else {
      _renameGame(context, game);
    }
  }

  void _renameGame(BuildContext context, Game game) {
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

                  game.name = _genericTextController.text;
                  game.path = p.join(containerFolder, game.name);

                  //When a game is renamed we must rename the shortcuts too
                  String homeFolder = FileTools.getHomeFolder();
                  String shortcutsPath = "$homeFolder/.steam/steam/userdata/${_settings.currentUserId}/config/shortcuts.vdf";

                  if (_currentUserSettings.backupsEnabled) {
                    await FileTools.saveFileSecure<List<Game>>(shortcutsPath, [game], <String, dynamic>{'userId': _settings.currentUserId},
                        (String path, List<Game> games, Map<String, dynamic> extraParams) async {
                      return await _gameRepository.saveGame(path, extraParams['userId'], games[0]);
                    }, _currentUserSettings.maxBackupsCount);
                  } else {
                    await _gameRepository.saveGame(shortcutsPath, _settings.currentUserId, game);
                  }

                  await Directory(oldPath).rename(game.path);

                  emit(GamesDataChanged(
                      _filteredGames,
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
                  EasyLoading.showError(tr("game_couldnt_be_renamed", args: [game.name]));
                  print(e);
                } finally {
                  Navigator.pop(context);
                }
              }),
          BasicDialogAction(
            title: Text(tr("cancel")),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void foldAll() {
    for (GameView gv in _gameViews) {
      gv.isExpanded = false;
    }

    emit(GamesDataChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void sortByName({SortDirection? direction}) {
    _sortStates = [true, false, false, false];

    SortDirection sd = _sortDirectionStates[0] ? SortDirection.Desc : SortDirection.Asc;

    if (sd == SortDirection.Asc) {
      _filteredGames.sort((a, b) => a.game.name.toLowerCase().compareTo(b.game.name.toLowerCase()));
    } else {
      _filteredGames.sort((a, b) => b.game.name.toLowerCase().compareTo(a.game.name.toLowerCase()));
    }

    emit(GamesDataChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void sortByWithErrors({SortDirection? direction}) {
    _sortStates = [false, false, false, true];

    SortDirection sd = _sortDirectionStates[0] ? SortDirection.Desc : SortDirection.Asc;

    if (sd == SortDirection.Asc) {
      _filteredGames.sort((a, b) {
        int aVal = a.game.hasErrors() ? 2 : a.modified ? 1 : 0;
        int bVal = b.game.hasErrors() ? 2 : b.modified ? 1 : 0;
        return aVal.compareTo(bVal);

      });
    } else {
      _filteredGames.sort((a, b) {
        int aVal = a.game.hasErrors() ? 2 : a.modified ? 1 : 0;
        int bVal = b.game.hasErrors() ? 2 : b.modified ? 1 : 0;
        return bVal.compareTo(aVal);
      });
    }

    emit(GamesDataChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void sortByStatus() {
    _sortStates = [false, true, false, false];

    var gameCategories = categorizeGamesByStatus(_filteredGames);
    List<GameView> notAdded = gameCategories['notAdded']!;
    List<GameView> added = gameCategories['added']!;
    List<GameView> fullyAdded = gameCategories['fullyAdded']!;
    List<GameView> addedExternal = gameCategories['addedExternal']!;
    notAdded.sort((a, b) => a.game.name.toLowerCase().compareTo(b.game.name.toLowerCase()));
    added.sort((a, b) => a.game.name.toLowerCase().compareTo(b.game.name.toLowerCase()));
    fullyAdded.sort((a, b) => a.game.name.toLowerCase().compareTo(b.game.name.toLowerCase()));
    addedExternal.sort((a, b) => a.game.name.toLowerCase().compareTo(b.game.name.toLowerCase()));

    List<GameView> finalList = [];

    SortDirection sortDirection = _sortDirectionStates[0] ? SortDirection.Desc : SortDirection.Asc;

    if (sortDirection == SortDirection.Desc) {
      finalList
        ..addAll(notAdded)
        ..addAll(added)
        ..addAll(fullyAdded)
        ..addAll(addedExternal);
    } else {
      finalList
        ..addAll(addedExternal)
        ..addAll(fullyAdded)
        ..addAll(added)
        ..addAll(notAdded);
    }

    assert(_filteredGames.length == finalList.length);
    _filteredGames = finalList;

    emit(GamesDataChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void sortBySize() {
    _sortStates = [false, false, true, false];

    SortDirection sortDirection = _sortDirectionStates[0] ? SortDirection.Desc : SortDirection.Asc;

    if (sortDirection == SortDirection.Asc) {
      _filteredGames.sort((a, b) => a.game.gameSize.compareTo(b.game.gameSize));
    } else {
      _filteredGames.sort((a, b) => b.game.gameSize.compareTo(a.game.gameSize));
    }

    emit(GamesDataChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  Map<String, List<GameView>> categorizeGamesByStatus(List<GameView> games) {
    List<GameView> notAdded = [], added = [], fullyAdded = [], addedExternal = [];

    for (int i = 0; i < games.length; ++i) {
      Game ug = games[i].game;
      var status = GameTools.getGameStatus(ug);
      if (status == GameStatus.AddedExternal) {
        addedExternal.add(games[i]);
      } else if (status == GameStatus.FullyAdded) {
        fullyAdded.add(games[i]);
      } else if (status == GameStatus.Added) {
        added.add(games[i]);
      } else {
        notAdded.add(games[i]);
      }
    }

    return {"added": added, "fullyAdded": fullyAdded, "notAdded": notAdded, "addedExternal": addedExternal};
  }

  Future<void> _refreshStorageSize() async {
    var data = await Stats.getStorageStats(_baseGames);
    _ssdFreeSizeInBytes = data['ssdFreeSpace']!;
    _ssdTotalSizeInBytes = data['ssdTotalSpace']!;
    _sdCardFreeInBytes = data['sdFreeSpace']!;
    _sdCardTotalInBytes = data['sdTotalSpace']!;
  }

  void _refreshGameCount() {
    var data = Stats.getGameStatusStats(_baseGames);
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

  void setSortDirection(SortDirection sd) {
    _sortDirectionStates = sd == SortDirection.Asc ? [true, false] : [false, true];

    if (_sortStates[0]) {
      sortByName();
    } else if (_sortStates[1]) {
      sortByStatus();
    } else if (_sortStates[2]) {
      sortBySize();
    } else if (_sortStates[3]) {
      sortByWithErrors();
    }

    emit(GamesDataChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void sortFilteredGames() {
    if (_sortStates[0]) {
      sortByName();
    } else if (_sortStates[1]) {
      sortByStatus();
    } else {
      sortBySize();
    }

    emit(GamesDataChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void filterGamesByName(String searchTerm) {
    searchTerm = searchTerm.toLowerCase();
    _filteredGames = _gameViews.where((element) => element.game.name.toLowerCase().contains(searchTerm)).toList();
    sortFilteredGames();

    emit(SearchTermChanged(_filteredGames, getAvailableCompatToolDisplayNames(), _nonAddedGamesCount, _addedGamesCount, _fullyAddedGamesCount,
        _addedExternalCount, _ssdFreeSizeInBytes, _sdCardFreeInBytes, _ssdTotalSizeInBytes, _sdCardTotalInBytes, _sortStates, _sortDirectionStates));
  }

  void openFolder(Game game) async {
    String path = StringTools.removeQuotes(game.path); // external ones are not touched so they can come with this
    bool b = await launchUrl(Uri.parse("file:$path"));

    if (!b || !Directory(path).existsSync()) {
      EasyLoading.showError(tr("folder_not_exists"));
    }
  }

  void saveGameMinerDataAppidMappings(List<Game> baseGames) {
    /*//TODO:We can get the data from here but the correct way should be creating a SteamApps repository but... today I'm too tired
    AppsStorageRepository asr = GetIt.I<AppsStorageRepository>();
    var appsStorage = asr.getAll()!;*/

    GameMinerDataRepository repo = GetIt.I<GameMinerDataRepository>();
    GameMinerData gmd = repo.getGameMinerData();
    //Add added apps to the list
    for (Game game in baseGames) {
      for (GameExecutable ge in game.exeFileEntries) {
        if (ge.added) {
          gmd.appsIdToName[ge.appId.toString()] = ge.name;
        }
      }
    }

    //It seems steam handles these games as it should deleting the data when uninstalled
    /*for(AppStorage appStorage in appsStorage) {
      if(appStorage.isSteamApp) {
        gmd.appsIdToName[appStorage.appId] = appStorage.name;
      }
    }*/

    repo.update(gmd);
    repo.save();
  }

  void showSteamActiveWhenSaving(BuildContext context, VoidCallback actionFunction) {
    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text(tr('Steam is Running')),
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
            Expanded(child: Text(tr("steam_is_running")))
          ],
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: Text("OK"),
            onPressed: () async {
              Navigator.pop(context);
              EasyLoading.show(status: tr("closing_steam"));
              await SteamTools.closeSteamClient();
              while (await SteamTools.isSteamRunning() == true) {
                await Future.delayed(const Duration(seconds: 1));
              }
              EasyLoading.dismiss();
              actionFunction();
            },
          ),
          BasicDialogAction(
            title: Text(tr("cancel")),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void showSimpleDialog(BuildContext context, String caption, String message) {
    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text(caption),
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
            Expanded(child: Text(message))
          ],
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: Text("OK"),
            onPressed: ()  {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );

  }

  void exportGame(Game game) async{
    String exportPath = "${game.path}/gameminer_config.json";
    EasyLoading.show(status: tr("exporting_game_config",args:[exportPath]));
    GameTools.exportGame(game);
    EasyLoading.showSuccess(tr("game_config_exported",args:[exportPath]));
  }
}
