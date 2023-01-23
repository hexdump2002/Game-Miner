import 'dart:async';
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:game_miner/data/repositories/compat_tools_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../data/models/app_storage.dart';
import '../../data/models/settings.dart';
import '../../data/models/steam_config.dart';
import '../../data/repositories/apps_storage_repository.dart';
import '../../data/repositories/game_miner_data_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/steam_config_repository.dart';
import '../Tools/service_locator.dart';
import '../Tools/steam_tools.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Stopwatch stopwatch = Stopwatch();

  //Returns if we can go to main after this is executed
  Future<void> initDependencies() async {
    stopwatch.start();

    await GetIt.I<GameMinerDataRepository>().load();

    SteamConfigRepository scr = GetIt.I<SteamConfigRepository>();
    SteamConfig sc = await scr.load();

    if (sc.steamUsers.isEmpty) throw const NotFoundException("No steam users logged found in the system. Aborting...");
    if (sc.libraryFolders.isEmpty) throw const NotFoundException("No steam  library folders found in the system. Aborting...");

    //Be sure we wait for 3 secs at splash page
    await Future.delayed( Duration(seconds: 0) - stopwatch.elapsed);

    SettingsRepository sr = GetIt.I<SettingsRepository>();
    Settings settings = sr.load();

    if(settings.currentUserId.isEmpty)
    {
      if(sc.steamUsers.length == 1) {
        emit(UserAutoLogged(sc.steamUsers[0]));
      }
      else {
        emit(ShowSteamUsersDialog("Select user", sc.steamUsers));
      }
    }
    else
    {
      emit(UserAutoLogged(sc.steamUsers.firstWhere((element) => element.steamId32 == settings.currentUserId)));
    }


  }

  void finalizeSetup(BuildContext context,SteamUser steamUser) async
  {
    SettingsRepository sr = GetIt.I<SettingsRepository>();
    Settings settings = sr.load();

    //Update settings if needed
    if(settings.currentUserId.isEmpty || settings.currentUserId != steamUser.steamId32) {
      settings.currentUserId=steamUser.steamId32;
      settings.setUserSettings(settings.currentUserId, UserSettings());
      sr.update(settings);
      sr.save();
    }

    //Close steam client
    if(settings.getCurrentUserSettings()!.closeSteamAtStartUp) {
      SteamTools.closeSteamClient();
    }

    SteamConfigRepository scr = GetIt.I<SteamConfigRepository>();
    List<String> paths = scr.getConfig().libraryFolders.map((e) => e.path).toList();
    AppsStorageRepository repo = GetIt.I<AppsStorageRepository>();
    List<AppStorage>? steamApps = await repo.load(settings.currentUserId, paths);

    GetIt.I<CompatToolsRepository>().loadCompatTools();

    /*SchedulerBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, "/main");
    });*/

    //Navigator.pushReplacementNamed(context, "/main");
    emit(SplashWorkDone());

  }

}
