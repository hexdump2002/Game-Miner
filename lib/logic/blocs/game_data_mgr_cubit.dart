import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:game_miner/data/models/app_storage.dart';
import 'package:game_miner/data/repositories/apps_storage_repository.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';
import 'package:game_miner/logic/Tools/string_tools.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';

import '../../data/models/steam_app.dart';

part 'game_data_mgr_state.dart';

enum StorageType { ShaderCache, CompatData }

enum GameType { Steam, NonSteam }

enum SortBy { Name, Status }

enum SortDirection { Asc, Desc }

class AppDataStorageEntry {
  String appId;
  String name;
  int size;
  bool selected;
  StorageType storageType;
  GameType gameType;

  AppDataStorageEntry(this.appId, this.name, this.size, this.selected, this.storageType, this.gameType);
}

class StorageStats {
  final int compatSize;
  final int compatFolderCount;
  final int shaderDataSize;
  final int shaderDataFolderCount;

  StorageStats(this.compatSize, this.compatFolderCount, this.shaderDataSize, this.shaderDataFolderCount);
}

class GameDataMgrCubit extends Cubit<GameDataMgrState> {
  final List<AppDataStorageEntry> _appDataStorageEntries = [];
  List<AppDataStorageEntry> _filteredDataStorageEntries = [];
  String _searchPath = "";

  List<bool> _sortStates = [true, false, false];
  List<bool> _sortDirectionStates = [false, true];

  GameDataMgrCubit() : super(GameDataMgrInitial()) {
    initialize();
  }

  void initialize() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    EasyLoading.show(status: tr("loading_data"));
    _appDataStorageEntries.clear();
    _filteredDataStorageEntries.clear();

    String homeFolder = FileTools.getHomeFolder();
    _searchPath = "$homeFolder/.local/share/Steam/steamapps";

    var appsStorage = await GetIt.I<AppsStorageRepository>().load(GetIt.I<SettingsRepository>().getSettings().currentUserId);

    for (AppStorage as in appsStorage) {
      if (as.shaderCacheSize >= 0) {
        _appDataStorageEntries.add(AppDataStorageEntry(
            as.appId, as.name, as.shaderCacheSize, false, StorageType.ShaderCache, as.isSteamApp ? GameType.Steam : GameType.NonSteam));
      }
      if (as.compatDataSize >= 0) {
        _appDataStorageEntries.add(AppDataStorageEntry(
            as.appId, as.name, as.compatDataSize, false, StorageType.CompatData, as.isSteamApp ? GameType.Steam : GameType.NonSteam));
      }
    }

    _filteredDataStorageEntries.addAll(_appDataStorageEntries);
    StorageStats ss = _getStorageStats();
    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));

    EasyLoading.dismiss();
  }

  void setSelectedState(AppDataStorageEntry adse, bool value) {
    adse.selected = value;
    StorageStats ss = _getStorageStats();
    emit(AppDataStorageChanged(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
  }

  void filterByName(String searchTerm) {
    searchTerm = searchTerm.toLowerCase();
    _filteredDataStorageEntries = _appDataStorageEntries.where((element) => element.name.toLowerCase().contains(searchTerm)).toList();
    StorageStats ss = _getStorageStats();
    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
    //sortFilteredGames();
  }

  StorageStats _getStorageStats() {
    int compatSize = 0;
    int compatFolderCount = 0;
    int shaderDataSize = 0;
    int shaderDataFolderCount = 0;
    for (AppDataStorageEntry ds in _appDataStorageEntries) {
      if (ds.storageType == StorageType.CompatData) {
        ++compatFolderCount;
        compatSize += ds.size;
      } else {
        ++shaderDataFolderCount;
        shaderDataSize += ds.size;
      }
    }

    return StorageStats(compatSize, compatFolderCount, shaderDataSize, shaderDataFolderCount);
  }

  void deleteData(BuildContext context, AppDataStorageEntry e) {
    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text(e.storageType == StorageType.CompatData ? tr('delete_compat_data') : tr('delete_shader_data')),
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
              TextSpan(text: tr("going_to")),
              TextSpan(text: tr("delete_capitals"), style: TextStyle(color: Colors.redAccent)),
              TextSpan(text: tr(e.storageType == StorageType.CompatData ? "compat_data_deletion" : "shadercache_data_deletion", args: [e.name])),
              TextSpan(text: tr("warning_action_undone"), style: const TextStyle(color: Colors.red, fontSize: 18, height: 2))
            ]))),
          ],
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: Text("OK"),
            onPressed: () async {
              try {
                String folderStorageType = e.storageType == StorageType.CompatData ? "compatdata" : "shadercache";
                String pathToDelete = "$_searchPath/$folderStorageType/${e.appId}";
                await Directory(pathToDelete).delete(recursive: true);
                _appDataStorageEntries.removeWhere((element) => element.appId == e.appId && element.storageType == e.storageType);
                _filteredDataStorageEntries.removeWhere((element) => element.appId == e.appId && element.storageType == e.storageType);

                EasyLoading.showSuccess(tr(e.storageType == StorageType.CompatData ? "compatdata_deleted" : "shadercache_deleted",
                    args: [StringTools.bytesToStorageUnity(e.size)]));

                var ss = _getStorageStats();

                emit(AppDataStorageLoaded(
                    _filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
              } catch (e) {
                EasyLoading.showError(tr('data_couldnt_be_deleted'));
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

  selectNone() {
    for (AppDataStorageEntry se in _appDataStorageEntries) {
      se.selected = false;
    }

    var ss = _getStorageStats();

    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
  }

  selectAll() {
    for (AppDataStorageEntry se in _appDataStorageEntries) {
      se.selected = true;
    }

    var ss = _getStorageStats();

    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
  }

  void refresh() {
    GetIt.I<AppsStorageRepository>().invalidateCache();
    _loadData();
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
      sortByStorageType();
    } else {
      sortBySize();
    }

    var ss = _getStorageStats();
    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
  }

  void sortFilteredGames() {
    if (_sortStates[0]) {
      sortByName();
    } else if (_sortStates[1]) {
      sortByStorageType();
    } else {
      sortBySize();
    }

    var ss = _getStorageStats();
    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
  }

  void sortByName({SortDirection? direction}) {
    _sortStates = [true, false, false];

    SortDirection sd = _sortDirectionStates[0] ? SortDirection.Desc : SortDirection.Asc;

    if (sd == SortDirection.Asc) {
      _filteredDataStorageEntries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      _filteredDataStorageEntries.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }

    var ss = _getStorageStats();
    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
  }

  void sortByStorageType() {
    _sortStates = [false, true, false];

    SortDirection sd = _sortDirectionStates[0] ? SortDirection.Desc : SortDirection.Asc;

    if (sd == SortDirection.Asc) {
      _filteredDataStorageEntries.sort((a, b) => a.storageType.index.compareTo(b.storageType.index));
    } else {
      _filteredDataStorageEntries.sort((a, b) => b.storageType.index.compareTo(a.storageType.index));
    }

    var ss = _getStorageStats();
    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
  }

  void sortBySize() {
    _sortStates = [false, false, true];

    SortDirection sortDirection = _sortDirectionStates[0] ? SortDirection.Desc : SortDirection.Asc;

    if (sortDirection == SortDirection.Asc) {
      _filteredDataStorageEntries.sort((a, b) => a.size.compareTo(b.size));
    } else {
      _filteredDataStorageEntries.sort((a, b) => b.size.compareTo(a.size));
    }

    var ss = _getStorageStats();
    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
  }

  void deleteAll(BuildContext context) {
    var toDelete = _filteredDataStorageEntries.where((e) => e.selected == true).toList();
    if (toDelete.isEmpty) {
      EasyLoading.showToast(tr("shader_page_no_selected_items"), duration: Duration(seconds: 2));
    }

    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text(tr('delete_selected')),
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
              TextSpan(text: tr("going_to")),
              TextSpan(text: tr("delete_capitals"), style: TextStyle(color: Colors.redAccent)),
              TextSpan(text: tr("delete_all_selected_text")),
              TextSpan(text: tr("warning_action_undone"), style: const TextStyle(color: Colors.red, fontSize: 18, height: 2))
            ]))),
          ],
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: Text("OK"),
            onPressed: () async {
              List<AppDataStorageEntry> deletedGames = [];

              bool errorDeleting = false;
              for (AppDataStorageEntry adse in toDelete) {
                try {
                  String folderStorageType = adse.storageType == StorageType.CompatData ? "compatdata" : "shadercache";
                  String pathToDelete = "$_searchPath/$folderStorageType/${adse.appId}";
                  await Directory(pathToDelete).delete(recursive: true);
                  _filteredDataStorageEntries.remove(adse);
                  _appDataStorageEntries.remove(adse);
                  deletedGames.add(adse);
                } catch (e) {
                  print("${adse.name} can't be deleted");
                  errorDeleting = true;
                }
              }

              int deletedBytes = deletedGames.fold(0, (int value, element) => element.size + value);

              if (errorDeleting) {
                EasyLoading.showError(tr("error_deleting_game_data", args: [StringTools.bytesToStorageUnity(deletedBytes)]));
              } else {
                EasyLoading.showError(tr("success_deleting_game_data", args: [StringTools.bytesToStorageUnity(deletedBytes)]));
              }

              var ss = _getStorageStats();
              emit(AppDataStorageLoaded(
                  _filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));

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
}
