
import 'package:bloc/bloc.dart';
import 'package:game_miner/data/models/app_storage.dart';
import 'package:game_miner/data/repositories/apps_storage_repository.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';

import '../../data/models/steam_app.dart';

part 'game_data_mgr_state.dart';


enum StorageType { ShaderCache, CompatData}
enum GameType {Steam, NonSteam}

class AppDataStorageEntry {
  String appId;
  String name;
  int size;
  bool selected;
  StorageType storageType;
  GameType gameType;

  AppDataStorageEntry(this.appId, this.name, this.size, this.selected, this.storageType, this.gameType);

}

class GameDataMgrCubit extends Cubit<GameDataMgrState> {
  List<AppDataStorageEntry> _appDataStorageEntries = [];

  GameDataMgrCubit() : super(GameDataMgrInitial()) {
    initialize();
  }

  void initialize() async {
    var appsStorage =  await GetIt.I<AppsStorageRepository>().load(GetIt.I<SettingsRepository>().getSettings().currentUserId);

    for(AppStorage as in appsStorage)  {
      if(as.shaderCacheSize>=0) {
        _appDataStorageEntries.add(AppDataStorageEntry(as.appId, as.name, as.shaderCacheSize, false, StorageType.ShaderCache, as.isSteamApp? GameType.Steam:GameType.NonSteam));
      }
      if(as.compatDataSize>=0) {
        _appDataStorageEntries.add(AppDataStorageEntry(as.appId, as.name, as.compatDataSize, false, StorageType.CompatData, as.isSteamApp? GameType.Steam:GameType.NonSteam));
      }
    }

    emit(AppDataStorageLoaded(_appDataStorageEntries));
  }

  void setSelectedState(AppDataStorageEntry adse, bool value) {
    adse.selected  = value;
    emit(AppDataStorageChanged(_appDataStorageEntries));
  }

}




