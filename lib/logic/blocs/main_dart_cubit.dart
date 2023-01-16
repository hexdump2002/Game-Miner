import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/data/repositories/steam_config_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';

import '../../data/models/settings.dart';
import '../../data/models/steam_config.dart';

part 'main_dart_state.dart';

class MainPageCubit extends Cubit<MainPageState> {
  int _selectecIndex = 0;

  set selectedIndex(int val) {
    _selectecIndex = val;
    SteamUser su = getSteamUser();
    emit(SelectedPageIndexChanged(su, _selectecIndex));
  }

  int get selectedIndex => _selectecIndex;

  MainPageCubit(SteamUser su) : super(MainPageInitial(su));

  //Fix move to wherever it may be
  static SteamUser getSteamUser() {
    SettingsRepository sr = GetIt.I<SettingsRepository>();
    SteamConfigRepository scr = GetIt.I<SteamConfigRepository>();
    Settings settings = sr.getSettings();
    SteamConfig sc = scr.getConfig();
    SteamUser su = sc.steamUsers.firstWhere((element) => element.steamId32 == settings.currentUserId);
    return su;
  }

  void changeUser(BuildContext context, SteamUser steamUser) {
    SettingsRepository sr = GetIt.I<SettingsRepository>();
    Settings settings = sr.getSettings();
    settings.currentUserId = steamUser.steamId32;
    sr.update(settings);
    sr.save();

    showPlatformDialog(context: context,
      builder: (context) =>
          BasicDialogAlert(title: const Text("Restart"),
              content: const Text("After changing users Game miner needs to be restarted. Press Ok, and relaunch Game Miner"),actions: [  BasicDialogAction(
                title: const Text("OK"),
                onPressed: () {
                  exit(0);
                },
      )]
    ));
  }
}
