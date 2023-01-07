part of 'game_data_mgr_cubit.dart';

@immutable
abstract class GameDataMgrState {}

class GameDataMgrInitial extends GameDataMgrState {}

class AppDataStorageLoaded extends GameDataMgrState{
  late final List<AppDataStorageEntry> steamApps;
  AppDataStorageLoaded(this.steamApps);
}

class AppDataStorageChanged extends GameDataMgrState{
  late final List<AppDataStorageEntry> steamApps;
  AppDataStorageChanged(this.steamApps);
}
