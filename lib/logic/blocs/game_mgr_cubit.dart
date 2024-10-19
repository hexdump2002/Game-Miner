import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:collection/collection.dart';
import 'package:game_miner/data/models/compat_tool.dart';
import 'package:game_miner/data/models/game_export_data.dart';
import 'package:game_miner/data/repositories/apps_storage_repository.dart';

import 'package:game_miner/data/repositories/compat_tools_repository.dart';
import 'package:game_miner/data/repositories/game_miner_data_repository.dart';
import 'package:game_miner/data/repositories/games_repository.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/logic/Tools/compat_tool_tools.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';
import 'package:game_miner/logic/Tools/string_tools.dart';
import 'package:get_it/get_it.dart';

import 'package:game_miner/data/stats.dart';
import 'package:game_miner/logic/Tools/steam_tools.dart';

import 'dart:io' show Directory, File;
import 'package:path/path.dart' as p;

import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../../data/models/advanced_filter.dart';
import '../../data/models/app_storage.dart';
import '../../data/models/compat_tool_mapping.dart';
import '../../data/models/game_executable.dart';
import '../../data/models/game.dart';
import '../../data/models/game_miner_data.dart';
import '../../data/models/settings.dart';
import '../../data/repositories/steam_config_repository.dart';
import '../Tools/dialog_tools.dart';
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
  String? gameImagePath;
  bool selected;
  bool hasConfig;

  GameView(this.game, this.gameImagePath, this.isExpanded, this.modified, this.selected, this.hasConfig);
}

class GameMgrCubit extends Cubit<GameMgrBaseState> {
  List<Game> _baseGames = [];
  List<GameView> _gameViews = [];
  int _sortIndex = 0;
  int _sortDirectionIndex = 0;
  String _searchText = "";
  late AdvancedFilter _advancedFilter; //Current filter being applied

  String get searchText => _searchText;

  //Falgs if something has been modified. To disallow exiting or doing any action that could incur in data loss
  bool get modified => _gameViews.firstWhereOrNull((element) => element.modified == true) != null;

  List<GameView> _filteredGames = [];
  List<GameView> _sortedFilteredGames = []; //Just to not sort everytime
  List<CompatTool> _availableCompatTools = [];

  final CompatToolsRepository _compatToolsRepository = GetIt.I<CompatToolsRepository>();
  final GamesRepository _gameRepository = GetIt.I<GamesRepository>();

  late UserSettings _currentUserSettings;
  late final Settings _settings;

  GameExecutableImageType? _currentImageType;

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

  bool _multiSelectionMode = false;

  bool getMultiSelectionMode() {
    return _multiSelectionMode;
  }

  void swapMultiSelectionMode() {
    _multiSelectionMode = !_multiSelectionMode;
    notifyDataChanged();
  }

  GameMgrCubit() : super(IninitalState()) {
    _settings = GetIt.I<SettingsRepository>().getSettings();

    _currentUserSettings = _settings!.getUserSettings(_settings!.currentUserId)!;

    //Set current filter
    if(_currentUserSettings.filter!=null) {
      _advancedFilter = AdvancedFilter.fromJson(_currentUserSettings.filter!.toJson());
    }
    else
      _advancedFilter = AdvancedFilter([..._settings.getCurrentUserSettings()!.searchPaths]);
  }

  void loadData() {
    _currentUserSettings = _settings!.getUserSettings(_settings!.currentUserId)!;

    _loadData(_currentUserSettings);
  }

  Future<void> _loadData(UserSettings settings) async {
    // final stopwatch = Stopwatch()..start();

    _currentImageType ??= GameExecutableImageType.values[_currentUserSettings.defaultGameManagerView];

    List<Game>? games = _gameRepository.getGames();

    if (games == null) {
      //print("Cache Miss. Loading Games");
      emit(RetrievingGameData());

      /*_baseGames*/
      games = await _gameRepository.loadGames(_settings.currentUserId, _currentUserSettings.searchPaths);

      _baseGames = games!;

      _gameViews = await _generateGameViews(_baseGames);

      /*for(Game g in _baseGames) {
        for(GameExecutable ge in g.exeFileEntries) {
          print("${ge.appId} ${g.path}/${ge.relativeExePath}");
        }
      }*/
    }

    _filteredGames = [];
    _filteredGames.addAll(_gameViews);
    _availableCompatTools = await _compatToolsRepository.loadCompatTools();

    _applyCurrentAdvancedFilter();
    _sortedFilteredGames = sortFilteredByCurrent();

    _refreshGameCountFromGameViews(_sortedFilteredGames);
    await _refreshStorageSize();

    emit(GamesDataRetrieved(
        _sortedFilteredGames,
        getAvailableCompatToolDisplayNames(),
        _nonAddedGamesCount,
        _addedGamesCount,
        _fullyAddedGamesCount,
        _addedExternalCount,
        _ssdFreeSizeInBytes,
        _sdCardFreeInBytes,
        _ssdTotalSizeInBytes,
        _sdCardTotalInBytes,
        _sortIndex,
        _sortDirectionIndex,
        searchText,
        _currentImageType!,
        _multiSelectionMode,
    _advancedFilter));

    // stopwatch.stop();
    // print('[Logic] Time taken to execute method: ${stopwatch.elapsed}');
  }

  void refreshGameViewImages(List<GameView> gameViews) {
    for (GameView g in gameViews) {
      refreshGameViewImage(g);
    }
  }

  void refreshGameViewImage(GameView g) {
    String? gameImage = GameTools.getGameImagePath(g.game, _currentImageType!);
    g.gameImagePath = gameImage;
  }

  Future<List<GameView>> _generateGameViews(List<Game> games) async {
    List<GameView> gameViews = [];

    for (int i = 0; i < games.length; ++i) {
      Game g = games[i];
      GameTools.handleGameExecutableErrorsForGame(g);
      String? gameImage = GameTools.getGameImagePath(g, _currentImageType!);
      bool hasGameConfig = await FileTools.existsFile("${g.path}/gameminer_config.json");
      gameViews.add(GameView(g, gameImage, false, false, false, hasGameConfig));
    }
    return gameViews;
  }

  refresh(BuildContext context) {
    if (!modified) {
      _gameRepository.invalidateGamesCache();
      loadData();
    } else {
      showSimpleDialog(context, tr("data_not_saved_refresh_caption"), tr('data_not_saved_refresh'), true, true, () async {
        _gameRepository.invalidateGamesCache();
        loadData();
      });
    }
  }

  List<String> getAvailableCompatToolDisplayNames() {
    return CompatToolTools.getAvailableCompatToolDisplayNames(_availableCompatTools);
  }

  String getCompatToolDisplayNameFromCode(String code) {
    return CompatToolTools.getCompatToolDisplayNameFromCode(code, _availableCompatTools);
  }

  String getCompatToolCodeFromDisplayName(String displayName) {
    return CompatToolTools.getCompatToolCodeFromDisplayName(displayName, _availableCompatTools);
  }

  void _applyNameProcessing(GameExecutable ge) {
    UserSettings cus = _settings.getCurrentUserSettings()!;

    if (cus.executableNameProcessRemoveExtension) {
      ge.name = p.basenameWithoutExtension(ge.name);
    }

    switch (cus.executableNameProcessTextProcessingOption) {
      case ExecutableNameProcesTextProcessingOption.titleCase:
        ge.name = ge.name.toTitleCase();
        break;
      case ExecutableNameProcesTextProcessingOption.capitalized:
        ge.name = ge.name.toCapitalized();
        break;
      case ExecutableNameProcesTextProcessingOption.upperCase:
        ge.name = ge.name.toUpperCase();
        break;
      case ExecutableNameProcesTextProcessingOption.lowerCase:
        ge.name = ge.name.toLowerCase();
        break;
      default:
        break;
    }
  }

  swapExeAdding(GameView gv, GameExecutable ge) {
    ge.added = !ge.added;
    gv.modified = true;

    if (ge.added) {
      //ge.appId = SteamTools.generateAppId("${ge.startDir}/${ge.relativeExePath}");
      ge.fillProtonMappingData(_currentUserSettings.defaultCompatTool, "", "250");
      _applyNameProcessing(ge);
      //_globalStats.MoveGameByStatus(uge, VMGameAddedStatus.Added);
    } else {
      //ge.appId = 0;
      ge.clearCompatToolMappingData();
      //_globalStats.MoveGameByStatus(uge, VMGameAddedStatus.NonAdded);
    }

    GameTools.handleGameExecutableErrorsForGame(gv.game);

    _refreshGameCountFromGameViews(_sortedFilteredGames);

    notifyDataChanged();
  }

  void swapExpansionStateForItem(int index) {
    _sortedFilteredGames[index].isExpanded = !_sortedFilteredGames[index].isExpanded;
    emit(GamesFoldingDataChanged(
        _sortedFilteredGames,
        getAvailableCompatToolDisplayNames(),
        _nonAddedGamesCount,
        _addedGamesCount,
        _fullyAddedGamesCount,
        _addedExternalCount,
        _ssdFreeSizeInBytes,
        _sdCardFreeInBytes,
        _ssdTotalSizeInBytes,
        _sdCardTotalInBytes,
        _sortIndex,
        _sortDirectionIndex,
        searchText,
        _currentImageType!,
        _multiSelectionMode,
        _advancedFilter));
  }

  Future<void> trySave() async {
    var gamesWithChangesAndNoErrors = _gameViews.where((element) => element.modified);

    //There is no data to save
    if (gamesWithChangesAndNoErrors.isEmpty) {
      EasyLoading.showToast(tr("no_changes_nothing_to_save")); //Nothing to save
      return;
    }

    if (await SteamTools.isSteamRunning()) {
      emit(SteamDetected(() {
        _saveData(_baseGames);
        _postSaveWork();
      }));
    } else {
      await _saveData(_baseGames);
      _postSaveWork();
    }
  }

  void _postSaveWork() {
    var gamesWithChangesAndNoErrors = _gameViews.where((element) => element.modified);

    //Reset all game changes
    for (GameView gv in gamesWithChangesAndNoErrors) {
      gv.modified = false;
    }

    //This is needed because when a game has an error with proton. It is reset to none but not saved
    _refreshGameCountFromGameViews(_sortedFilteredGames);

    notifyDataChanged();
  }

  /*void saveData(Settings settings, {showInfo = true}) async {
    if (showInfo) {
      EasyLoading.show(status: tr("saving_games"));
    }

    String homeFolder = FileTools.getHomeFolder();
    String shortcutsPath = "$homeFolder/.steam/steam/userdata/${_settings.currentUserId}/config/shortcuts.vdf";

    if(settings.backupsEnabled) {
      await FileTools.saveFileSecure<List<Game>>(shortcutsPath, _baseGames, <String,dynamic>{}, (String path, List<Game> games, Map<String,dynamic> extraParams) async {
        return _gameRepository.saveGames(path, games);
      }, settings.maxBackupsCount);
    }
    else
    {
      await _gameRepository.saveGames(shortcutsPath,_baseGames);
    }

    saveGameMinerDataAppidMappings(_baseGames);
    await saveCompatToolMappings(settings);

    if (showInfo) {
      EasyLoading.showSuccess(tr("data_saved"));
    }
  }*/

  Future<void> _saveData(List<Game> games, {showInfo = true}) async {
    if (showInfo) {
      EasyLoading.show(status: tr("saving_games"));
    }

    String homeFolder = FileTools.getHomeFolder();
    String shortcutsPath = "$homeFolder/.steam/steam/userdata/${_settings.currentUserId}/config/shortcuts.vdf";

    //Save shortcuts
    await _gameRepository.saveGames(shortcutsPath, games, _currentUserSettings.backupsEnabled, _currentUserSettings.maxBackupsCount);

    saveGameMinerDataAppidMappings(_baseGames);

    if (showInfo) {
      EasyLoading.showToast(tr("data_saved"));
    }
  }

  void setCompatToolDataFor(GameView gv, GameExecutable uge, String value) {
    //assert(value!=null);

    if (value == CompatToolTools.notAssigned || value == CompatToolTools.notInUseCode) {
      uge.clearCompatToolMappingData();
    } else {
      uge.fillProtonMappingData(getCompatToolCodeFromDisplayName(value), "", "250");
    }

    gv.modified = true;

    GameTools.handleGameExecutableErrorsForGame(gv.game);
    _refreshGameCountFromGameViews(_sortedFilteredGames);

    notifyDataChanged();
  }

  void tryDeleteSelected() async {
    if (_gameViews.where((o) => o.selected).isEmpty) {
      EasyLoading.showToast(tr("no_action_no_games_selected"));
      return;
    }

    int gameViewsToDeleteCount = _gameViews.where((element) => element.selected).length;

    if (await SteamTools.isSteamRunning()) {
      emit(SteamDetected(() {
        emit(DeleteSelectedClicked(gameViewsToDeleteCount));
      }));
    } else {
      emit(DeleteSelectedClicked(gameViewsToDeleteCount));
    }
  }

  void tryDeleteGame(Game game) async {
    if (await SteamTools.isSteamRunning()) {
      emit(SteamDetected(() {
        emit(DeleteGameClicked(game));
      }));
    } else {
      emit(DeleteGameClicked(game));
    }
  }

  Future<void> deleteSelectedGames(bool deleteImages, bool deleteCompatData, bool deleteShaderData) async {
    EasyLoading.show(status: tr("deleting_games"));

    List<GameView> gameViewsToDelete = _gameViews.where((element) => element.selected).toList();
    //We are going to remove items for gameViews so, we get a copy to do not invalidate iterators
    List<GameView> copyGameViews = List.from(gameViewsToDelete);

    int i = 0;
    bool error = false;
    while (i < copyGameViews.length && !error) {
      error = !await deleteGame(copyGameViews[i].game, deleteImages, deleteCompatData, deleteShaderData, showNotifications: false, refreshUi: false);
      ++i;
    }

    if (error) {
      EasyLoading.showError(tr("all_games_couldnt_be_deleted"));
    } else {
      EasyLoading.showToast(tr("selected_data_games_was_deleted"));
    }
  }

  //Returns if action was succesfully executed
  Future<bool> deleteGame(Game game, bool deleteImages, bool deleteCompatData, bool deleteShaderData,
      {bool showNotifications = true, bool refreshUi = true}) async {
    try {
      print("Deleting game -> ${game.name}");

      await Directory(game.path).delete(recursive: true);

      _baseGames.removeWhere((element) => element.path == game.path);
      _gameViews.removeWhere((element) => element.game.path == game.path);
      _filteredGames.removeWhere((element) => element.game.path == game.path);
      _sortedFilteredGames.removeWhere((element) => element.game.path == game.path);

      //Persist new shortcuts file (TODO: split data saved to just save what is needed instead of everything everytime)
      await _saveData(_baseGames, showInfo: false);

      if (deleteImages) {
        await GameTools.deleteGameImages(game, _settings.currentUserId);
      }
      if (deleteCompatData || deleteShaderData) {
        SteamConfigRepository scr = GetIt.I<SteamConfigRepository>();
        List<String> paths = scr.getConfig().libraryFolders.map((e) => e.path).toList();
        AppsStorageRepository asr = GetIt.I<AppsStorageRepository>();
        var appsStorage = await asr.load(_settings.currentUserId, paths);
        await GameTools.deleteGameData(game, appsStorage, deleteCompatData, deleteShaderData);

        //Force a reload when returning to cleaner
        GetIt.I<AppsStorageRepository>().invalidateCache();
        /*appsStorage = await GetIt.I<AppsStorageRepository>().load(_settings.currentUserId, paths);
        print(appsStorage);*/
      }

      if (showNotifications) EasyLoading.showToast(tr("selected_data_was_deleted", args: [game.name]));

      await _refreshStorageSize();
      _refreshGameCountFromGameViews(_sortedFilteredGames);

      if (refreshUi) notifyDataChanged();

      return true;
    } catch (e) {
      if (showNotifications) EasyLoading.showError(tr('game_couldnt_be_deleted', args: [game.name]));
      print(e.toString());
    }

    return false;
  }

  Future<void> tryRenameGame(BuildContext context,  Game game, String newName) async {
    if (game.hasErrors()) {
      showSimpleDialog(context, tr('warning'), tr('cant_rename_with_errors'), true, false, null);
      return;
    }

    if (await SteamTools.isSteamRunning()) {
      emit(SteamDetected(() {
        emit(RenameGameClicked(game, newName));
      }));
    } else {
      emit(RenameGameClicked(game, newName));
    }
  }

  Future<void> renameGame(Game game, String newName) async {
    try {
      var oldPath = game.path;
      var containerFolder = p.dirname(game.path);

      game.name = newName;
      game.path = p.join(containerFolder, game.name);

      //When a game is renamed we must rename the shortcuts too
      String baseSteamFolder = SteamTools.getSteamBaseFolder();
      String shortcutsPath = "$baseSteamFolder/userdata/${_settings.currentUserId}/config/shortcuts.vdf";

      if (_currentUserSettings.backupsEnabled) {
        await FileTools.saveFileSecure<List<Game>>(shortcutsPath, [game], <String, dynamic>{'userId': _settings.currentUserId},
            (String path, List<Game> games, Map<String, dynamic> extraParams) async {
          return await _gameRepository.saveGame(path, extraParams['userId'], games[0]);
        }, _currentUserSettings.maxBackupsCount);
      } else {
        await _gameRepository.saveGame(shortcutsPath, _settings.currentUserId, game);
      }

      await Directory(oldPath).rename(game.path);

      notifyDataChanged();

      EasyLoading.showToast(tr("game_renamed"));
    } catch (e) {
      EasyLoading.showError(tr("game_couldnt_be_renamed", args: [game.name]));
      print(e);
    }
  }

  Future<void> importSelectedGamesConfig() async {
    EasyLoading.show(status: tr("importing_games"));

    List<GameView> gameViewsToExport = _gameViews.where((element) => element.selected).toList();

    int i = 0;
    bool error = false;
    while (i < gameViewsToExport.length) {
      bool success = await importGameConfig(gameViewsToExport[i], showNotifications: false, refreshUi: false);
      if (!success) error = true;
      ++i;
    }

    if (error) {
      EasyLoading.showError(tr("all_games_couldnt_be_imported"));
    } else {
      EasyLoading.showToast(tr("selected_games_were_imported"));
    }

    notifyDataChanged();
  }

  //Returns true if everything went ok
  Future<bool> importGameConfig(GameView gv, {showNotifications = true, refreshUi = true}) async {
    print("Importing game ${gv.game.name}");

    GameExportedData? ged = await GameTools.importGame(gv.game);
    if (ged == null) {
      if (showNotifications) EasyLoading.showToast(tr("config_does_not_exist"));
      return true;
    }

    if (showNotifications) EasyLoading.showInfo(tr("importing_game_config"));

    bool modified = false;
    for (GameExecutable ge in gv.game.exeFileEntries) {
      GameExecutableExportedData? foundGe = ged!.executables.firstWhereOrNull((element) => element.executableRelativePath == ge.relativeExePath);
      if (foundGe != null) {
        ge.name = foundGe.executableName;
        ge.launchOptions = foundGe.executableOptions;
        ge.added = true;
        //ge.appId=SteamTools.generateAppId(p.joinAll([ge.startDir,ge.relativeExePath])); //Se generara el mismo?
        ge.fillProtonMappingData(foundGe.compatToolCode, "", "250");
        //ge.dataFromConfigFile = true; //Mark as configured by config file

        //Import and load art if it exists
        await GameTools.importShortcutArt(gv.game.path, ge, _settings.currentUserId);
        ge.images = await GameTools.getGameExecutableImages(ge.appId, _settings.currentUserId);

        modified = true;
      }
    }

    //Set the new active image depending on the current view
    refreshGameViewImage(gv);

    gv.modified = modified;

    //Recheck errors for the imported game
    if (gv.modified) {
      GameTools.handleGameExecutableErrorsForGame(gv.game);
    }

    if (refreshUi) notifyDataChanged();

    if (showNotifications) EasyLoading.showToast(tr("game_was_imported"));

    return true;
  }

  void foldAll() {
    for (GameView gv in _gameViews) {
      gv.isExpanded = false;
    }

    notifyDataChanged();
  }

  List<GameView> sortByName(List<GameView> gvs, {SortDirection? direction}) {
    SortDirection sd = _sortDirectionIndex == 0 ? SortDirection.Asc : SortDirection.Desc;

    if (sd == SortDirection.Asc) {
      gvs.sort((a, b) => a.game.name.toLowerCase().compareTo(b.game.name.toLowerCase()));
    } else {
      gvs.sort((a, b) => b.game.name.toLowerCase().compareTo(a.game.name.toLowerCase()));
    }

    return gvs;
  }

  void swapSortDirecion() {
    _sortDirectionIndex = ++_sortDirectionIndex % 2;
    _sortedFilteredGames = sortFilteredByCurrent();

    notifyDataChanged();
  }

  void sortFilteredByName({SortDirection? direction}) {
    _sortIndex = 0;

    _sortedFilteredGames = sortByName([..._filteredGames]);

    notifyDataChanged();
  }

  List<GameView> sortByWithErrors(List<GameView> gvs, {SortDirection? direction}) {
    SortDirection sd = _sortDirectionIndex == 0 ? SortDirection.Asc : SortDirection.Desc;

    if (sd == SortDirection.Asc) {
      gvs.sort((a, b) {
        int aVal = a.game.hasErrors()
            ? 2
            : a.modified
                ? 1
                : 0;
        int bVal = b.game.hasErrors()
            ? 2
            : b.modified
                ? 1
                : 0;
        return aVal.compareTo(bVal);
      });
    } else {
      gvs.sort((a, b) {
        int aVal = a.game.hasErrors()
            ? 2
            : a.modified
                ? 1
                : 0;
        int bVal = b.game.hasErrors()
            ? 2
            : b.modified
                ? 1
                : 0;
        return bVal.compareTo(aVal);
      });
    }

    return gvs;
  }

  void sortFilteredByDate() {
    _sortIndex = 4;
    _sortedFilteredGames = sortByDate([..._filteredGames]);
    notifyDataChanged();
  }

  void sortFilteredByWithErrors() {
    _sortIndex = 3;
    _sortedFilteredGames = sortByWithErrors([..._filteredGames]);
    notifyDataChanged();
  }

  List<GameView> sortByStatus(List<GameView> gvs) {
    var gameCategories = categorizeGamesByStatus(gvs);
    List<GameView> notAdded = gameCategories['notAdded']!;
    List<GameView> added = gameCategories['added']!;
    List<GameView> fullyAdded = gameCategories['fullyAdded']!;
    List<GameView> addedExternal = gameCategories['addedExternal']!;
    notAdded.sort((a, b) => a.game.name.toLowerCase().compareTo(b.game.name.toLowerCase()));
    added.sort((a, b) => a.game.name.toLowerCase().compareTo(b.game.name.toLowerCase()));
    fullyAdded.sort((a, b) => a.game.name.toLowerCase().compareTo(b.game.name.toLowerCase()));
    addedExternal.sort((a, b) => a.game.name.toLowerCase().compareTo(b.game.name.toLowerCase()));

    List<GameView> finalList = [];

    SortDirection sortDirection = _sortDirectionIndex == 0 ? SortDirection.Asc : SortDirection.Desc;

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

    assert(gvs.length == finalList.length);

    return finalList;
  }

  void sortFilteredByStatus() {
    _sortIndex = 2;

    _sortedFilteredGames = sortByStatus([..._filteredGames]);

    notifyDataChanged();
  }

  List<GameView> sortBySize(List<GameView> gvs, {SortDirection? direction}) {
    SortDirection sortDirection = _sortDirectionIndex == 0 ? SortDirection.Asc : SortDirection.Desc;

    if (sortDirection == SortDirection.Asc) {
      gvs.sort((a, b) => a.game.gameSize.compareTo(b.game.gameSize));
    } else {
      gvs.sort((a, b) => b.game.gameSize.compareTo(a.game.gameSize));
    }

    return gvs;
  }

  List<GameView> sortByDate(List<GameView> gvs) {
    SortDirection sortDirection = _sortDirectionIndex == 0 ? SortDirection.Asc : SortDirection.Desc;

    if (sortDirection == SortDirection.Asc) {
      gvs.sort((a, b) => a.game.creationDate.compareTo(b.game.creationDate));
    } else {
      gvs.sort((a, b) => b.game.creationDate.compareTo(a.game.creationDate));
    }

    return gvs;
  }

  void sortFilteredBySize({SortDirection? direction}) {
    _sortIndex = 1;

    _sortedFilteredGames = sortBySize([..._filteredGames], direction: direction);

    notifyDataChanged();
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

  void _refreshGameCountFromGameViews(List<GameView> gameViews) {
    List<Game> games = gameViews.map<Game>((e) => e.game).toList();
    _refreshGameCount(games);
  }

  void _refreshGameCount(List<Game> games) {
    var data = Stats.getGameStatusStats(games);
    _nonAddedGamesCount = data["notAdded"]!;
    _addedGamesCount = data["added"]!;
    _fullyAddedGamesCount = data["fullyAdded"]!;
    _addedExternalCount = data["addedExternal"]!;
  }

  int getSortIndex() {
    return _sortIndex;
  }

  int getSortDirectionIndex() {
    return _sortDirectionIndex;
  }

  List<GameView> sortByCurrent(List<GameView> gvs) {
    if (_sortIndex == 0) {
      return sortByName(gvs);
    } else if (_sortIndex == 1) {
      return sortBySize(gvs);
    } else if (_sortIndex == 2) {
      return sortByStatus(gvs);
    } else if (_sortIndex == 3) {
      return sortByWithErrors(gvs);
    } else if (_sortIndex == 4) {
      return sortByDate(gvs);
    }
    throw Exception("No sort state is active so, can't sort by current");
  }

  List<GameView> sortFilteredByCurrent() {
    return sortByCurrent([..._filteredGames]);
  }

  void setAdvancedFilter(AdvancedFilter advancedFilter) {
    _advancedFilter = advancedFilter;
    _applyCurrentAdvancedFilter();
    notifyDataChanged();
  }

  void _applyCurrentAdvancedFilter() {
    _filteredGames = filterGamesByName(_gameViews, _searchText);
    _filteredGames = filterGamesByChanges(_filteredGames, _advancedFilter.showChanges);
    _filteredGames = filterGamesByStatus(_filteredGames, _advancedFilter.showStatusRed, _advancedFilter.showStatusOrange, _advancedFilter.showStatusGreen, _advancedFilter.showStatusBlue);
    _filteredGames = filterGamesByConfiguration(_filteredGames, _advancedFilter.showConfiguration);
    _filteredGames = filterGamesByError(_filteredGames, _advancedFilter.showErrors);
    _filteredGames = filterGamesByImages(_filteredGames, _advancedFilter.showImages);
    _filteredGames = filterGamesBySearchPaths(_filteredGames, _advancedFilter.searchPaths);

    if(_advancedFilter.compatToolFilterActive) {
      _filteredGames = filterGamesByCompatTool(_filteredGames, _advancedFilter.compatToolCode);
    }

    _sortedFilteredGames = sortFilteredByCurrent();

    _refreshGameCountFromGameViews(_sortedFilteredGames);

    notifyDataChanged();
  }

  //region Filters
  searchTermChanged(String term) {
    _searchText = term;
    _applyCurrentAdvancedFilter();
    notifyDataChanged();
  }

  AdvancedFilter getAdvancedFilter() { return _advancedFilter; }

  List<GameView> filterGamesByName(List<GameView> gameViews, String searchTerm) {
    _searchText = searchTerm;

    searchTerm = searchTerm.toLowerCase();
    return gameViews.where((element) => element.game.name.toLowerCase().contains(searchTerm)).toList();
  }

  List<GameView> filterGamesByStatus(List<GameView> gameViews,  bool showRed, bool showOrange, bool showGreen, bool showBlue) {
    List<GameView> gvs = gameViews.where((element) {
      GameStatus status = GameTools.getGameStatus(element.game);

      if(showRed && status == GameStatus.NonAdded) {
        return true;
      } else if(showOrange && status == GameStatus.Added) {
        return true;
      } else if(showGreen && status == GameStatus.FullyAdded) {
        return true;
      } else if(showBlue && status == GameStatus.AddedExternal) {
        return true;
      }

      return false;
    }).toList();

    return gvs;
  }

  List<GameView> filterGamesBySearchPaths(List<GameView> gameViews, List<String> searchPaths) {
    if(searchPaths.isEmpty) {
      return gameViews.where((gameView) => _advancedFilter.showStatusBlue && gameView.game.isExternal).toList();
    }

    List<GameView> gvs = gameViews.where((gameView) {
      return searchPaths.firstWhereOrNull((searchPath) {
        String searchPathWithSeparator = searchPath+p.separator;
        return gameView.game.path.startsWith(searchPathWithSeparator) || (_advancedFilter.showStatusBlue && gameView.game.isExternal);
      })!=null;
    }).toList();

    return gvs;
  }

  List<GameView> filterGamesByImages(List<GameView> gameViews, int showWithImages) {
    //Both
    if(showWithImages == 2) return gameViews;

    //With images
    if(showWithImages == 0) {
      return gameViews.where((element) =>GameTools.doesGameHasImages(element.game)).toList();
    }
    else {
      //With no changes
      return gameViews.where((element) => !GameTools.doesGameHasImages(element.game)).toList();
    }
  }

  List<GameView> filterGamesByChanges(List<GameView> gameViews, int showChanges) {
    //Both
    if(showChanges == 2) return gameViews;

    //With changes
    if(showChanges == 0) {
      return gameViews.where((element) => element.modified).toList();
    }
    else {
      //With no changes
      return gameViews.where((element) => !element.modified).toList();
    }

  }

  List<GameView> filterGamesByError(List<GameView> gameViews, int showError) {
    if(showError ==2 ) return gameViews;

    //With errors
    if(showError == 0) {
      return gameViews.where((element) =>  element.game.hasErrors()).toList();
    }
    else {
      //With no errors
      return gameViews.where((element) =>  !element.game.hasErrors()).toList();
    }
  }

  List<GameView> filterGamesByConfiguration(List<GameView> gameViews, int showConfiguration) {
    if(showConfiguration ==2 ) return gameViews;

    //With errors
    if(showConfiguration == 0) {
      return gameViews.where((element) =>  element.hasConfig).toList();
    }
    else {
      //With no errors
      return gameViews.where((element) =>  !element.hasConfig).toList();
    }
  }

  List<GameView> filterGamesByCompatTool(List<GameView> filteredGames, String compatToolCode) {
    List<GameView> filteredGameView = [];
    for(GameView g in filteredGames) {
      GameExecutable? ge = g.game.exeFileEntries.firstWhereOrNull((element) => element.added && element.compatToolCode == compatToolCode);
      if(ge!=null) {
        filteredGameView.add(g);
      }
    }

    return filteredGameView;
  }
/*
  void setFilterRedStatus(bool value) {
    _advancedFilter.showStatusRed = value;
  }
  void setFilterOrangeStatus(bool value) {
    _advancedFilter.showStatusOrange = value;
  }
  void setFilterGreenStatus(bool value) {
    _advancedFilter.showStatusGreen = value;
  }void setFilterBlueStatus(bool value) {
    _advancedFilter.showStatusBlue = value;
  }
  void setFilterSearchPaths(List<String> paths) {
    _advancedFilter.searchPaths = paths;
  }
  void setFilterWithErrors(bool value) {
    _advancedFilter.showErrors = value;
  }
  void setFilterWithNoErrors(bool value) {
    _advancedFilter.showErrors = value;
  }
  void setFilterWithChanges(bool value) {
    _advancedFilter.showChanges = value;
  }
  void setFilterWithNoChanges(bool value) {
    _advancedFilter.showChanges = value;
  }
  void setFilterWithImages(bool value) {
    _advancedFilter.showImages = value;
  }
  void setFilterWithNoImages(bool value) {
    _advancedFilter.showImages = value;
  }
  void setFilterWithConfiguration(bool value) {
    _advancedFilter.showConfiguration = value;
  }
  void setFilterWithNoConfiguration(bool value) {
    _advancedFilter.showConfiguration = value;
  }*/

  //endregion

  void openFolder(Game game) async {
    String path = StringTools.removeQuotes(game.path); // external ones are not touched so they can come with this
    bool b = await launchUrl(Uri.parse("file:$path"));

    if (!b || !Directory(path).existsSync()) {
      EasyLoading.showError(tr("folder_not_exists"));
    }
  }

  void saveGameMinerDataAppidMappings(List<Game> baseGames) async {
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

    repo.update(gmd);
    await repo.save(_currentUserSettings.backupsEnabled, _currentUserSettings.maxBackupsCount);
  }

  Future<void> exportSelectedGames() async {
    EasyLoading.show(status: tr("exporting_games"));

    List<GameView> gameViewsToExport = _gameViews.where((element) => element.selected).toList();

    int i = 0;
    bool error = false;
    while (i < gameViewsToExport.length && !error) {
      error = !await exportGame(gameViewsToExport[i], showNotifications: false, refreshUi: false);
      ++i;
    }

    if (error) {
      EasyLoading.showError(tr("all_games_couldnt_be_exported"));
    } else {
      EasyLoading.showToast(tr("selected_games_were_exported"));
    }

    notifyDataChanged();
  }

  Future<bool> exportGame(GameView gv, {showNotifications: true, emit, refreshUi = true}) async {
    String exportPath = "${gv.game.path}/gameminer_config.json";
    if (showNotifications) {
      EasyLoading.show(status: tr("exporting_game_config", args: [exportPath]));
    }
    bool success = await GameTools.exportGame(gv.game, _settings.currentUserId);
    if (success) {
      gv.hasConfig = true;
    }

    if (showNotifications) {
      EasyLoading.showToast(tr("game_config_exported", args: [exportPath]));
    }

    if (refreshUi) notifyDataChanged();

    return success;
  }

  Future<void> deleteSelectedGameConfigs() async {
    EasyLoading.show(status: tr("deleting_games_configs"));

    List<GameView> gameViewsToExport = _gameViews.where((element) => element.selected).toList();

    int i = 0;
    bool success = true;
    while (i < gameViewsToExport.length) {
      bool retval = await deleteGameConfig(gameViewsToExport[i], showNotifications: false, refreshUi: false);
      if (!retval) success = false;

      ++i;
    }

    if (!success) {
      EasyLoading.showError(tr("games_config_deleted_error"));
    } else {
      EasyLoading.showToast(tr("games_config_deleted"));
    }

    notifyDataChanged();
  }

  Future<bool> deleteGameConfig(GameView gv, {showNotifications: true, emit, refreshUi = true}) async {
    String exportPath = "${gv.game.path}/gameminer_config.json";
    if (showNotifications) {
      EasyLoading.show(status: tr("deleting_game_config", args: [exportPath]));
    }
    bool success = await GameTools.deleteGameConfig(gv.game);
    if (success) {
      gv.hasConfig = false;
    }

    if (showNotifications) {
      if (success) {
        EasyLoading.showToast(tr("game_config_deleted", args: [exportPath]));
      } else {
        EasyLoading.showError(tr("game_config_deleted_error", args: [exportPath]));
      }
    }

    if (refreshUi) notifyDataChanged();

    return success;
  }

  void notifyDataChanged() {
    emit(GamesDataChanged(
        _sortedFilteredGames,
        getAvailableCompatToolDisplayNames(),
        _nonAddedGamesCount,
        _addedGamesCount,
        _fullyAddedGamesCount,
        _addedExternalCount,
        _ssdFreeSizeInBytes,
        _sdCardFreeInBytes,
        _ssdTotalSizeInBytes,
        _sdCardTotalInBytes,
        _sortIndex,
        _sortDirectionIndex,
        searchText,
        _currentImageType!,
        _multiSelectionMode,
        _advancedFilter));
  }

  void setViewType(GameExecutableImageType geit) {
    _currentImageType = geit;
    refreshGameViewImages(_gameViews);
    notifyDataChanged();
  }

  GameExecutableImageType getCurrentImageType() {
    return _currentImageType!;
  }

  void cycleViewType() {
    var enumIndex = _currentImageType!.index;
    setViewType(GameExecutableImageType.values[(enumIndex + 1) % GameExecutableImageType.values.length]);
  }

  void swapGameViewSelected(GameView gameView) {
    gameView.selected = !gameView.selected;
    notifyDataChanged();
  }

  void selectAll() {
    for (GameView gv in _filteredGames) {
      gv.selected = true;
    }
    notifyDataChanged();
  }

  void selectNone() {
    for (GameView gv in _filteredGames) {
      gv.selected = false;
    }

    notifyDataChanged();
  }

  void changeSelectedGamesCompatTool(String protonName) {
    var selectedGames = _gameViews.where((element)  =>element.selected);

    String compatToolCode = CompatToolTools.getCompatToolCodeFromDisplayName(protonName, _availableCompatTools);
    for(GameView gv in selectedGames) {
      for(GameExecutable ge in gv.game.exeFileEntries) {
        if(ge.added) {
          ge.compatToolCode = compatToolCode;
          gv.modified = true;
        }
      }
    }

    _applyCurrentAdvancedFilter();

    notifyDataChanged();
  }






}
