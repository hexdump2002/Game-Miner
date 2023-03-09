import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:game_miner/data/models/app_storage.dart';
import 'package:game_miner/data/repositories/apps_storage_repository.dart';
import 'package:game_miner/data/repositories/game_miner_data_repository.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/data/repositories/steam_config_repository.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';
import 'package:game_miner/logic/Tools/string_tools.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

import '../../data/models/game_miner_data.dart';
import '../../data/models/steam_app.dart';
import '../Tools/steam_tools.dart';

part 'game_data_mgr_state.dart';

class AppDataStorageEntry {
  AppStorage appStorage;
  bool selected;
  String? iconImagePath;
  AppDataStorageEntry(this.appStorage, this.selected, this.iconImagePath);
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
  int _sortingColumnIndex = 1;
  bool _sortAscending = true;

  GameDataMgrCubit() : super(GameDataMgrInitial()) {
  }

  void initialize() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    EasyLoading.show(status: tr("loading_data"));
    _appDataStorageEntries.clear();
    _filteredDataStorageEntries.clear();

    _searchPath = "${SteamTools.getSteamBaseFolder()}/steamapps";

    var currentUserId = GetIt.I<SettingsRepository>().getSettings().currentUserId;

    var gmd = GetIt.I<GameMinerDataRepository>().getGameMinerData();
    var steamConfig = GetIt.I<SteamConfigRepository>().getConfig();
    List<String> paths = steamConfig.libraryFolders.map((e) => e.path).toList();
    var appsStorage = await GetIt.I<AppsStorageRepository>().load(currentUserId, paths);

    String steamBaserFolder = SteamTools.getSteamBaseFolder();
    String nonSteamGamesiconFolder = path.join(steamBaserFolder,"userdata/$currentUserId/config/grid");
    String steamGamesIconFolder = path.join(steamBaserFolder,"appcache/librarycache");

    //TODO: Update through repository
    for (AppStorage as in appsStorage) {
      String name = as.name;
      //Try to resolve unknown game name from database
      if(as.isUnknown) {
        if(gmd.appsIdToName.containsKey(as.appId)) {
          as.name = gmd.appsIdToName[as.appId]!;
        }
        else {
          as.name = "Unknown";
        }
      }

      if(as.appId =="0") {
        print("YHA");
      }

      //Get Image. We can't use games repository because there can be data left for deleted games
      var icons = await FileTools.getFolderFilesAsync(nonSteamGamesiconFolder, recursive: false, regExFilter: "\^${as.appId}_icon.*");
      if(icons!= null && icons.isEmpty) {
        icons = await FileTools.getFolderFilesAsync(steamGamesIconFolder, recursive: false, regExFilter: "\^${as.appId}_icon.*");
      }

      _appDataStorageEntries.add(AppDataStorageEntry(as, false, icons!=null && icons.isNotEmpty ? icons.first : null));
    }

    _filteredDataStorageEntries.addAll(_appDataStorageEntries);
    sortByName(_sortingColumnIndex, true,false);
    StorageStats ss = _getStorageStats();
    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize,_sortingColumnIndex,_sortAscending));

    EasyLoading.dismiss();
  }


  void setSelectedState(AppDataStorageEntry adse, bool value) {
    adse.selected = value;
    StorageStats ss = _getStorageStats();
    emit(AppDataStorageChanged(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize,_sortingColumnIndex,_sortAscending));
  }

  void filterByName(String searchTerm) {
    searchTerm = searchTerm.toLowerCase();
    _filteredDataStorageEntries = _appDataStorageEntries.where((element) => element.appStorage.name.toLowerCase().contains(searchTerm)).toList();
    StorageStats ss = _getStorageStats();
    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize,_sortingColumnIndex,_sortAscending));
    //sortFilteredGames();
  }

  StorageStats _getStorageStats() {
    int compatSize = 0;
    int compatFolderCount = 0;
    int shaderDataSize = 0;
    int shaderDataFolderCount = 0;
    for (AppDataStorageEntry ds in _appDataStorageEntries) {
      if (ds.appStorage.storageType == StorageType.CompatData) {
        ++compatFolderCount;
        compatSize += ds.appStorage.size;
      } else {
        ++shaderDataFolderCount;
        shaderDataSize += ds.appStorage.size;
      }
    }

    return StorageStats(compatSize, compatFolderCount, shaderDataSize, shaderDataFolderCount);
  }

  void deleteData(BuildContext context, AppDataStorageEntry e) {
    Color textColor = GetIt.I<SettingsRepository>().getSettings().getCurrentUserSettings()!.darkTheme ? Colors.white : Colors.black;
    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text(e.appStorage.storageType == StorageType.CompatData ? tr('delete_compat_data') : tr('delete_shader_data')),
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
              TextSpan(text: tr("going_to"), style: TextStyle(color:textColor)),
              TextSpan(text: tr("delete_capitals"), style: TextStyle(color: Colors.redAccent)),
              TextSpan(text: tr(e.appStorage.storageType == StorageType.CompatData ? "compat_data_deletion" : "shadercache_data_deletion", args: [e.appStorage.name]), style: TextStyle(color:textColor)),
              TextSpan(text: tr("warning_action_undone"), style: const TextStyle(color: Colors.red, fontSize: 18, height: 2))
            ]))),
          ],
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: Text("OK"),
            onPressed: () async {
              try {
                String folderStorageType = e.appStorage.storageType == StorageType.CompatData ? "compatdata" : "shadercache";
                String pathToDelete = "$_searchPath/$folderStorageType/${e.appStorage.appId}";
                await Directory(pathToDelete).delete(recursive: true);
                _removeItemFromLists(e);

                EasyLoading.showSuccess(tr(e.appStorage.storageType == StorageType.CompatData ? "compatdata_deleted" : "shadercache_deleted",
                    args: [StringTools.bytesToStorageUnity(e.appStorage.size)]));

                var ss = _getStorageStats();

                emit(AppDataStorageLoaded(
                    _filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize,_sortingColumnIndex,_sortAscending));
              } catch (e) {
                EasyLoading.showError(tr('data_couldnt_be_deleted'));
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

  void _removeItemFromLists(AppDataStorageEntry e) {
    _appDataStorageEntries.removeWhere((element) => element.appStorage.appId == e.appStorage.appId && element.appStorage.storageType == e.appStorage.storageType);
    _filteredDataStorageEntries.removeWhere((element) => element.appStorage.appId == e.appStorage.appId && element.appStorage.storageType == e.appStorage.storageType);
    GetIt.I<AppsStorageRepository>().remove(e.appStorage);
  }

  selectNone() {
    for (AppDataStorageEntry se in _appDataStorageEntries) {
      se.selected = false;
    }

    var ss = _getStorageStats();

    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize,_sortingColumnIndex,_sortAscending));
  }

  selectAll() {
    for (AppDataStorageEntry se in _appDataStorageEntries) {
      se.selected = true;
    }

    var ss = _getStorageStats();

    emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize,_sortingColumnIndex,_sortAscending));
  }

  void refresh() {
    GetIt.I<AppsStorageRepository>().invalidateCache();
    _loadData();
  }


  void sort(int columnIndex, bool ascending, {bool emitEvent:true}) {
    _sortingColumnIndex = columnIndex;
    _sortAscending = ascending;

    if (_sortingColumnIndex==2) {
      sortByName(_sortingColumnIndex, _sortAscending,emitEvent);
    } else if (_sortingColumnIndex==3) {
      sortBySize (_sortingColumnIndex, _sortAscending,emitEvent);
    } else if(_sortingColumnIndex==4){
      sortByStorageType(_sortingColumnIndex, _sortAscending,emitEvent);
    }
    else if(_sortingColumnIndex==5){
      sortBySteam(_sortingColumnIndex, _sortAscending,emitEvent);
    }
  }

  void sortByName(int columnIndex, bool ascending, bool emitEvent) {

    if (ascending) {
      _filteredDataStorageEntries.sort((a, b) => a.appStorage.name.toLowerCase().compareTo(b.appStorage.name.toLowerCase()));
    } else {
      _filteredDataStorageEntries.sort((a, b) => b.appStorage.name.toLowerCase().compareTo(a.appStorage.name.toLowerCase()));
    }

    var ss = _getStorageStats();

    if(emitEvent) {
      emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize,_sortingColumnIndex, _sortAscending));
    }
  }

  void sortByStorageType(int columnIndex, bool ascending, bool emitEvent) {

    if (ascending) {
      _filteredDataStorageEntries.sort((a, b) => a.appStorage.storageType.index.compareTo(b.appStorage.storageType.index));
    } else {
      _filteredDataStorageEntries.sort((a, b) => b.appStorage.storageType.index.compareTo(a.appStorage.storageType.index));
    }

    var ss = _getStorageStats();

    if(emitEvent) {
      emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize,_sortingColumnIndex, _sortAscending));
    }
  }

  void sortBySize(int columnIndex, bool ascending, bool emitEvent) {

    if (ascending) {
      _filteredDataStorageEntries.sort((a, b) => a.appStorage.size.compareTo(b.appStorage.size));
    } else {
      _filteredDataStorageEntries.sort((a, b) => b.appStorage.size.compareTo(a.appStorage.size));
    }

    var ss = _getStorageStats();

    if(emitEvent) {
      emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize,_sortingColumnIndex, _sortAscending));
    }
  }

  void sortBySteam(int columnIndex, bool ascending, bool emitEvent) {
    if (ascending) {
      _filteredDataStorageEntries.sort((a, b) => a.appStorage.gameType.index.compareTo(b.appStorage.gameType.index));
    } else {
      _filteredDataStorageEntries.sort((a, b) => b.appStorage.gameType.index.compareTo(a.appStorage.gameType.index));
    }

    var ss = _getStorageStats();

    if(emitEvent) {
      emit(AppDataStorageLoaded(_filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize,_sortingColumnIndex, _sortAscending));
    }
  }

  void deleteAll(BuildContext context) {
    var toDelete = _filteredDataStorageEntries.where((e) => e.selected == true).toList();
    if (toDelete.isEmpty) {
      EasyLoading.showToast(tr("shader_page_no_selected_items"));
      return;
    }

    Color textColor = GetIt.I<SettingsRepository>().getSettings().getCurrentUserSettings()!.darkTheme ? Colors.white : Colors.black;
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
              TextSpan(text: tr("going_to"),style: TextStyle(color:textColor)),
              TextSpan(text: tr("delete_capitals"), style: TextStyle(color: Colors.redAccent)),
              TextSpan(text: tr("delete_all_selected_text"),style: TextStyle(color:textColor)),
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
                  String folderStorageType = adse.appStorage.storageType == StorageType.CompatData ? "compatdata" : "shadercache";
                  String pathToDelete = "$_searchPath/$folderStorageType/${adse.appStorage.appId}";
                  await Directory(pathToDelete).delete(recursive: true);
                  _removeItemFromLists(adse);
                  deletedGames.add(adse);
                } catch (e) {
                  print("${adse.appStorage.name} can't be deleted");
                  errorDeleting = true;
                }
              }

              int deletedBytes = deletedGames.fold(0, (int value, element) => element.appStorage.size + value);

              if (errorDeleting) {
                EasyLoading.showError(tr("error_deleting_game_data", args: [StringTools.bytesToStorageUnity(deletedBytes)]));
              } else {
                EasyLoading.showError(tr("success_deleting_game_data", args: [StringTools.bytesToStorageUnity(deletedBytes)]));
              }

              var ss = _getStorageStats();
              emit(AppDataStorageLoaded(
                  _filteredDataStorageEntries, ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize,_sortingColumnIndex, _sortAscending));

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

  void openFolder(AppStorage appStorage/*String path*/) async {
    String dataType = appStorage.storageType == StorageType.CompatData ? "compatdata" : "shadercache";
    String path = "${SteamTools.getSteamBaseFolder()}/steamapps/$dataType/${appStorage.appId}";
    bool b = await launchUrl(Uri.parse("file:$path"));


    if(!b || !Directory(path).existsSync()) {
      EasyLoading.showError(tr("folder_not_exists"));
    }
  }


}
