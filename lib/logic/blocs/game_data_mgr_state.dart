part of 'game_data_mgr_cubit.dart';

@immutable
abstract class GameDataMgrState {
  final List<AppDataStorageEntry> steamApps;
  int compatDataFolderCount;
  int shaderDataFolderCount;
  int compatDataFoldersSize;
  int shaderDataFolderSize;

  GameDataMgrState(this.steamApps, this.compatDataFolderCount, this.shaderDataFolderCount, this.compatDataFoldersSize, this.shaderDataFolderSize);
}

class GameDataMgrInitial extends GameDataMgrState {
  GameDataMgrInitial() : super([], 0, 0, 0, 0);
}

class AppDataStorageLoaded extends GameDataMgrState {
  AppDataStorageLoaded(
      List<AppDataStorageEntry> steamApps, int compatDataFolderCount, int shaderDataFolderCount, int compatDataFoldersSize, int shaderDataFolderSize)
      : super(steamApps, compatDataFolderCount, shaderDataFolderCount, compatDataFoldersSize, shaderDataFolderSize);
}

class AppDataStorageChanged extends GameDataMgrState {
  AppDataStorageChanged(
      List<AppDataStorageEntry> steamApps, int compatDataFolderCount, int shaderDataFolderCount, int compatDataFoldersSize, int shaderDataFolderSize)
      : super(steamApps, compatDataFolderCount, shaderDataFolderCount, compatDataFoldersSize, shaderDataFolderSize);
}
