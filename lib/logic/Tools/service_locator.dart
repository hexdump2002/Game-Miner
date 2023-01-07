import 'package:game_miner/data/data_providers/compat_tools_data_provider.dart';
import 'package:game_miner/data/data_providers/compat_tools_mapping_data_provider.dart';
import 'package:game_miner/data/data_providers/settings_data_provider.dart';
import 'package:game_miner/data/data_providers/steam_apps_data_provider.dart';
import 'package:game_miner/data/data_providers/steam_shortcuts_data_provider.dart';
import 'package:game_miner/data/repositories/compat_tools_mapping_repository.dart';
import 'package:game_miner/data/repositories/compat_tools_repository.dart';
import 'package:game_miner/data/repositories/games_repository.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/data/repositories/apps_storage_repository.dart';
import 'package:get_it/get_it.dart';

import '../../data/data_providers/app_storage_data_provider.dart';
import '../../data/data_providers/steam_users_data_provider.dart';
import '../../data/data_providers/user_library_games_data_provider.dart';
import '../../data/models/steam_user.dart';
import '../../data/repositories/steam_user_repository.dart';

final serviceLocator = GetIt.I;

Future<void> setupServiceLocator() async {
  SteamUsersDataProvider sudp = SteamUsersDataProvider();
  List<SteamUser> users = await sudp.loadUsers();
  if (users.isEmpty) throw Exception("No Steam users were found");

  //Data providers
  serviceLocator.registerLazySingleton<CompatToolsDataProvider>(() => CompatToolsDataProvider());
  serviceLocator.registerLazySingleton<CompatToolsMappingDataProvider>(() => CompatToolsMappingDataProvider());
  serviceLocator.registerLazySingleton<SteamShortcutDataProvider>(() => SteamShortcutDataProvider());
  serviceLocator.registerLazySingleton<UserLibraryGamesDataProvider>(() => UserLibraryGamesDataProvider());
  serviceLocator.registerLazySingleton<SteamAppsDataProvider>(() => SteamAppsDataProvider());
  serviceLocator.registerLazySingleton<SettingsDataProvider>(() => SettingsDataProvider());
  serviceLocator.registerLazySingleton<AppsStorageDataProvider>(() => AppsStorageDataProvider());
  serviceLocator.registerSingleton<SteamUsersDataProvider>(sudp);

  //Repositories
  serviceLocator.registerLazySingleton<CompatToolsRepository>(() => CompatToolsRepository());
  serviceLocator.registerLazySingleton<CompatToolsMappipngRepository>(()=>CompatToolsMappipngRepository());
  serviceLocator.registerLazySingleton<GamesRepository>(() => GamesRepository());
  serviceLocator.registerLazySingleton<AppsStorageRepository>(() => AppsStorageRepository());
  serviceLocator.registerLazySingleton<SteamUserRepository>(() => SteamUserRepository());
  serviceLocator.registerLazySingleton<SettingsRepository>(() => SettingsRepository());
}