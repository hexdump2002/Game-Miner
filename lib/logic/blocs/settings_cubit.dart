import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';

import '../../data/models/compat_tool_mapping.dart';
import '../../data/models/settings.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  late Settings _settings;

  bool _gameListDirty = false;
  bool get isGameListDirty { return _gameListDirty;}


  SettingsCubit(String userId) : super(SettingsInitial()) {
    SettingsRepository repo = GetIt.I<SettingsRepository>();
    Settings? settings = repo.loadSettings(userId);

    save(showMessages: false);

    emit(SettingsLoaded(_settings));
  }


  Settings getSettings() { return _settings;}

  void refresh() {
    emit(SettingsChangedState(_settings));
  }


  void save({bool showMessages=true}) {
    if(showMessages) EasyLoading.show(status: "saving_settings");

    SettingsRepository repo = GetIt.I<SettingsRepository>();
    repo.save();

    if(showMessages) EasyLoading.showSuccess(tr("settings_saved"));

    emit(SettingsSaved(_settings));
  }

  /*bool existsConfig() {
    Directory appFolder = Directory.current;
    return File("${appFolder.path}/$_configFilePath").existsSync();
  }*/

  pickPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      _settings.searchPaths.add(selectedDirectory);
      _gameListDirty  = true;
      emit(SearchPathsChanged(_settings));
    } else {
      // User canceled the picker
    }
  }

  removePath(String e) {
    _settings.searchPaths.remove(e);
    _gameListDirty = true;
    emit(SearchPathsChanged(_settings));
  }

  void setDarkThemeState(bool state) {
    _settings.darkTheme = state;
    emit(GeneralOptionsChanged(_settings));
  }

/*  bool getDarkThemeState() {
    return _settings.darkTheme;
  }*/

}
