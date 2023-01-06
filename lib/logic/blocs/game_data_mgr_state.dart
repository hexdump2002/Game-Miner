part of 'game_data_mgr_cubit.dart';

@immutable
abstract class GameDataMgrState {}

class GameDataMgrInitial extends GameDataMgrState {}

class SteamAppsLoaded extends GameDataMgrState{
  late final List<SteamApp> steamApps;
  SteamAppsLoaded(this.steamApps);
}
