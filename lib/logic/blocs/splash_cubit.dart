import 'dart:async';
import 'dart:async';
import 'dart:io';

import 'package:posix/posix.dart' as posix;
import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:game_miner/data/repositories/compat_tools_repository.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../data/models/app_storage.dart';
import '../../data/models/settings.dart';
import '../../data/models/steam_config.dart';
import '../../data/repositories/apps_storage_repository.dart';
import '../../data/repositories/game_miner_data_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/steam_config_repository.dart';
import '../Tools/github_updater.dart';
import '../Tools/steam_tools.dart';
import 'package:path/path.dart' as p;

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());
  GithubUpdater _ghu = GithubUpdater("hexdump2002", "game-miner-public");
  Stopwatch stopwatch = Stopwatch();

  //Returns if we can go to main after this is executed
  Future<void> initDependencies() async {
    //Add app icons if needed
    await FileTools.createAppShortcutIcons("packages/game_miner/appassets/icon.png", "packages/game_miner/appassets/GameMiner.desktop");

    String configFolder = p.join(FileTools.getConfigFolder());
    bool existsConfigFolder = await FileTools.existsFile(configFolder);
    if (!existsConfigFolder) {
      await Directory(configFolder).create(recursive: true);
    }

    await GetIt.I<GameMinerDataRepository>().load();
    bool existsUpdate = await _checkForUpdates();
    if(!existsUpdate) await checkForUsers();
  }

  Future<bool> _checkForUpdates() async {
    Release? r = await _ghu.checkForUpdates();

    if (r != null) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version;
      emit(GameMinerUpdateFound(r, packageInfo.version));
      return true;
    }

    return false;
  }

  Future<void> checkForUsers() async {
    SteamConfigRepository scr = GetIt.I<SteamConfigRepository>();
    SteamConfig sc = await scr.load();

    if (sc.steamUsers.isEmpty) throw const NotFoundException("No steam users logged found in the system. Aborting...");
    if (sc.libraryFolders.isEmpty) throw const NotFoundException("No steam  library folders found in the system. Aborting...");

    SettingsRepository sr = GetIt.I<SettingsRepository>();
    Settings settings = sr.load();

    if (settings.currentUserId.isEmpty) {
      if (sc.steamUsers.length == 1) {
        emit(UserAutoLogged(sc.steamUsers[0]));
      } else {
        emit(ShowSteamUsersDialog(tr('select_user'), sc.steamUsers));
      }
    } else {
      emit(UserAutoLogged(sc.steamUsers.firstWhere((element) => element.steamId32 == settings.currentUserId)));
    }
  }

  void finalizeSetup(BuildContext context, SteamUser steamUser) async {
    SettingsRepository sr = GetIt.I<SettingsRepository>();
    Settings settings = sr.load();

    //Update settings if needed
    if (settings.currentUserId.isEmpty || settings.currentUserId != steamUser.steamId32) {
      settings.currentUserId = steamUser.steamId32;
      settings.setUserSettings(settings.currentUserId, UserSettings());
      sr.update(settings);
      sr.save();
    }

    //Close steam client
    if (settings.getCurrentUserSettings()!.closeSteamAtStartUp) {
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

    //Be sure we wait for 3 secs at splash page
    await Future.delayed(Duration(seconds: 4) - stopwatch.elapsed);

    //Navigator.pushReplacementNamed(context, "/main");
    emit(SplashWorkDone());
  }

  void downloadUpdate(Release release) {
    String path = p.join(Directory.current.path, 'GameMiner_newversion.AppImage');
    _ghu.downLoadRelease(release, path,
        (normalizedProgress) async{
      EasyLoading.showProgress(normalizedProgress, status:"Downloading Update. Progress: ${(normalizedProgress * 100).toStringAsFixed(0)}%");
      if(normalizedProgress>=1) {
        /*File f = File(path);
        posix.chmod(path,"755");
        File blah = await f.copy(p.join(Directory.current.path,"GameMiner.AppImage"));
        print("====> $blah");*/
        EasyLoading.dismiss();

        emit(UpdateDownloadComplete());

        /*f = File(path);
        f.delete();*/
    }});
  }
}
