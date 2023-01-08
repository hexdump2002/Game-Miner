import 'package:bloc/bloc.dart';
import 'package:game_miner/data/models/app_storage.dart';
import 'package:game_miner/data/repositories/apps_storage_repository.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';

import '../../data/models/steam_app.dart';

part 'game_data_mgr_state.dart';

enum StorageType { ShaderCache, CompatData }

enum GameType { Steam, NonSteam }

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

  GameDataMgrCubit() : super(GameDataMgrInitial()) {
    initialize();
  }

  void initialize() async {
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
    emit(AppDataStorageLoaded(_filteredDataStorageEntries,ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
  }

  void setSelectedState(AppDataStorageEntry adse, bool value) {
    adse.selected = value;
    StorageStats ss = _getStorageStats();
    emit(AppDataStorageChanged(_filteredDataStorageEntries,ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
  }

  void filterByName(String searchTerm) {
    searchTerm = searchTerm.toLowerCase();
    _filteredDataStorageEntries = _appDataStorageEntries.where((element) => element.name.toLowerCase().contains(searchTerm)).toList();
    StorageStats ss = _getStorageStats();
    emit(AppDataStorageLoaded(_filteredDataStorageEntries,ss.compatFolderCount, ss.shaderDataFolderCount, ss.compatSize, ss.shaderDataSize));
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

    return StorageStats(compatSize,compatFolderCount, shaderDataSize,shaderDataFolderCount);
  }
}
