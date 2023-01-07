import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:game_miner/data/repositories/compat_tools_repository.dart';
import 'package:game_miner/data/repositories/games_repository.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';

import '../../data/models/compat_tool.dart';
import '../../data/models/compat_tool_mapping.dart';
import '../../data/models/settings.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  late Settings _settings ; //Settings after modifications
  late Settings _oldSettings; //Settings we got when we entered

  List<CompatTool> _availableCompatTools = [];

  SettingsCubit() : super(SettingsInitial(Settings("NO NUMBER"))) {
    SettingsRepository repo = GetIt.I<SettingsRepository>();
    _settings = repo.getSettings();
    _oldSettings = _settings.clone();
    emit(SettingsLoaded(_settings));
  }

  Future<List<CompatTool>> initialize() async {
     Future<List<CompatTool>> compatTools =  GetIt.I<CompatToolsRepository>().loadCompatTools();
     compatTools.then((value) => _availableCompatTools = value);
     return compatTools;
  }


  Settings getSettings() { return _settings;}

  void refresh() {
    emit(SettingsChangedState(_settings));
  }

  List<String> getAvailableCompatToolDisplayNames() {
    List<String> ctn = _availableCompatTools.map<String>( (e) => e.displayName).toList();
    ctn.insert(0, "None");
    return ctn;
  }

  String getCompatToolDisplayNameFromCode(String code) {
    if(code == "None") return "None";
    return _availableCompatTools.firstWhere((element) => element.code == code).displayName;
  }

  String getCompatToolCodeFromDisplayName(String displayName) {
    if(displayName == "None") return "None";
    return _availableCompatTools.firstWhere((element) => element.displayName == displayName).code;
  }


  void save({bool showMessages=true}) {
    if(showMessages) EasyLoading.show(status: "saving_settings");

    SettingsRepository repo = GetIt.I<SettingsRepository>();
    repo.save();

    if(showMessages) EasyLoading.showSuccess(tr("settings_saved"));

    //Request a reload next time i
    if(!_areSettingsPathEqual(_settings, _oldSettings)) {
      GetIt.I<GamesRepository>().invalidateGamesCache();
    }

    emit(SettingsSaved(_settings));
  }

  /*bool existsConfig() {
    Directory appFolder = Directory.current;
    return File("${appFolder.path}/$_configFilePath").existsSync();
  }*/

  bool _areSettingsPathEqual(Settings a, Settings b)
  {
    List<String> listA = a.searchPaths;
    List<String> listB = b.searchPaths;

    if(listA.length != listB.length) return false;

    bool equal = true;
    int i = 0;
    while(equal && i<listA.length) {
      if(listB.contains(listB[i])) equal = false;
    }

    return equal;
  }

  pickPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      bool existed = _settings.searchPaths.contains(selectedDirectory);
      if(existed)
      {
        EasyLoading.showError(tr("path_duplicated"));
      }
      else {
        _settings.searchPaths.add(selectedDirectory);
        emit(SearchPathsChanged(_settings));
      }
    } else {
      // User canceled the picker
    }
  }

  removePath(String e) {
    _settings.searchPaths.remove(e);
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
