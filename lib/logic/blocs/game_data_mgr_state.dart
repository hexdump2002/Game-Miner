part of 'game_data_mgr_cubit.dart';

@immutable
abstract class GameDataMgrState {
  final List<AppDataStorageEntry> steamApps;
  int compatDataFolderCount;
  int shaderDataFolderCount;
  int compatDataFoldersSize;
  int shaderDataFolderSize;
  int sortingTableIndex;
  bool sortingAscending;

  GameDataMgrState(this.steamApps, this.compatDataFolderCount, this.shaderDataFolderCount, this.compatDataFoldersSize, this.shaderDataFolderSize, this.sortingTableIndex,this.sortingAscending);
}

class GameDataMgrInitial extends GameDataMgrState {
  GameDataMgrInitial() : super([], 0, 0, 0, 0,2,true);
}

class AppDataStorageLoaded extends GameDataMgrState {
  AppDataStorageLoaded(
      List<AppDataStorageEntry> steamApps, int compatDataFolderCount, int shaderDataFolderCount, int compatDataFoldersSize, int shaderDataFolderSize, int sortingTableIndex, bool sortAscending)
      : super(steamApps, compatDataFolderCount, shaderDataFolderCount, compatDataFoldersSize, shaderDataFolderSize, sortingTableIndex, sortAscending);
}

class AppDataStorageChanged extends GameDataMgrState {
  AppDataStorageChanged(
      List<AppDataStorageEntry> steamApps, int compatDataFolderCount, int shaderDataFolderCount, int compatDataFoldersSize, int shaderDataFolderSize, int sortingTableIndex, bool sortAscending)
      : super(steamApps, compatDataFolderCount, shaderDataFolderCount, compatDataFoldersSize, shaderDataFolderSize, sortingTableIndex,sortAscending);
}
