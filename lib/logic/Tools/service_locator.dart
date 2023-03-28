import 'dart:io';

import 'package:game_miner/data/data_providers/compat_tools_data_provider.dart';
import 'package:game_miner/data/data_providers/compat_tools_mapping_data_provider.dart';
import 'package:game_miner/data/data_providers/game_miner_data_provider.dart';
import 'package:game_miner/data/data_providers/game_stats_provider.dart';
import 'package:game_miner/data/data_providers/settings_data_provider.dart';
import 'package:game_miner/data/data_providers/steam_apps_data_provider.dart';
import 'package:game_miner/data/data_providers/steam_config_data_provider.dart';
import 'package:game_miner/data/data_providers/steam_shortcuts_data_provider.dart';
import 'package:game_miner/data/repositories/compat_tools_repository.dart';
import 'package:game_miner/data/repositories/game_miner_data_repository.dart';
import 'package:game_miner/data/repositories/games_repository.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/data/repositories/apps_storage_repository.dart';
import 'package:get_it/get_it.dart';

import '../../data/data_providers/app_storage_data_provider.dart';
import '../../data/data_providers/steam_users_data_provider.dart';
import '../../data/data_providers/user_library_games_data_provider.dart';
import '../../data/models/steam_user.dart';
import '../../data/repositories/steam_config_repository.dart';
import '../../data/repositories/steam_user_repository.dart';
import 'package:path/path.dart' as p;

import 'file_tools.dart';
final serviceLocator = GetIt.I;

void setupServiceLocator()  {
  String configFolder = FileTools.getConfigFolder();
  String gameMinerAbsolutePath = p.join(configFolder,"game_miner.json");

  //Data providers
  serviceLocator.registerLazySingleton<CompatToolsDataProvider>(() => CompatToolsDataProvider());
  serviceLocator.registerLazySingleton<CompatToolsMappingDataProvider>(() => CompatToolsMappingDataProvider());
  serviceLocator.registerLazySingleton<SteamShortcutDataProvider>(() => SteamShortcutDataProvider());
  serviceLocator.registerLazySingleton<UserLibraryGamesDataProvider>(() => UserLibraryGamesDataProvider());
  serviceLocator.registerLazySingleton<SteamAppsDataProvider>(() => SteamAppsDataProvider());
  serviceLocator.registerLazySingleton<SettingsDataProvider>(() => SettingsDataProvider());
  serviceLocator.registerLazySingleton<AppsStorageDataProvider>(() => AppsStorageDataProvider());
  serviceLocator.registerLazySingleton<GameMinerDataProvider>(() => GameMinerDataProvider());
  serviceLocator.registerLazySingleton<GameStatsProvider>(() => GameStatsProvider());
  serviceLocator.registerLazySingleton<SteamConfigDataProvider>(() => SteamConfigDataProvider());
  //serviceLocator.registerLazySingleton<SteamUsersDataProvider>(()=>SteamUsersDataProvider());

  //Repositories
  serviceLocator.registerLazySingleton<CompatToolsRepository>(() => CompatToolsRepository());
  serviceLocator.registerLazySingleton<GamesRepository>(() => GamesRepository());
  serviceLocator.registerLazySingleton<AppsStorageRepository>(() => AppsStorageRepository());
  //serviceLocator.registerLazySingleton<SteamUserRepository>(() => SteamUserRepository());
  serviceLocator.registerLazySingleton<SettingsRepository>(() => SettingsRepository());
  serviceLocator.registerLazySingleton<GameMinerDataRepository>(() => GameMinerDataRepository(gameMinerAbsolutePath));
  serviceLocator.registerLazySingleton<SteamConfigRepository>(() => SteamConfigRepository());
}