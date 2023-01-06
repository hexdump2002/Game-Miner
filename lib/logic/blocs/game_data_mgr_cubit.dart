import 'package:bloc/bloc.dart';
import 'package:game_miner/data/repositories/steam_apps_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';

import '../../data/models/steam_app.dart';

part 'game_data_mgr_state.dart';

class GameDataMgrCubit extends Cubit<GameDataMgrState> {
  List<SteamApp> _steamApps = [];

  GameDataMgrCubit() : super(GameDataMgrInitial()) {
    initialize();
  }

  void initialize() async {
    _steamApps =  await GetIt.I<SteamAppsRepository>().load();

    emit(SteamAppsLoaded(_steamApps));
  }

}


