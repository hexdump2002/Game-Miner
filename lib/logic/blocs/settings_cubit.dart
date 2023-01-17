import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:game_miner/data/repositories/compat_tools_repository.dart';
import 'package:game_miner/data/repositories/games_repository.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';

import '../../data/models/compat_tool.dart';
import '../../data/models/compat_tool_mapping.dart';
import '../../data/models/settings.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  late UserSettings _currentUserSettings ; //Settings after modifications
  late UserSettings _oldCurrentUserSettings; //Settings we got when we entered
  late String _currentUserId;

  List<CompatTool> _availableCompatTools = [];

  SettingsCubit() : super(SettingsInitial(UserSettings())) {
    SettingsRepository repo = GetIt.I<SettingsRepository>();
    _currentUserId = repo.getSettings().currentUserId;
    _currentUserSettings = repo.getSettingsForCurrentUser()!;
    _oldCurrentUserSettings = _currentUserSettings.clone();

    emit(SettingsLoaded(_currentUserSettings));
  }

  Future<List<CompatTool>> initialize() async {
     Future<List<CompatTool>> compatTools =  GetIt.I<CompatToolsRepository>().loadCompatTools();
     compatTools.then((value) => _availableCompatTools = value);
     return compatTools;
  }


  UserSettings getUserSettings() { return _currentUserSettings;}

  void refresh() {
    emit(SettingsChangedState(_currentUserSettings));
  }

  List<String> getAvailableCompatToolDisplayNames() {
    List<String> ctn = _availableCompatTools.map<String>( (e) => e.displayName).toList();
    ctn.insert(0, "None");
    return ctn;
  }

  String getDefaultCompatToolDisplayNameFromCode() {
      return getCompatToolDisplayNameFromCode(_currentUserSettings.defaultCompatTool);
  }

  String getCompatToolDisplayNameFromCode(String code) {
    if(code == "None") return "None";
    return _availableCompatTools.firstWhere((element) => element.code == code).displayName;
  }

  String getCompatToolCodeFromDisplayName(String displayName) {
    if(displayName == "None") return "None";
    return _availableCompatTools.firstWhere((element) => element.displayName == displayName).code;
  }

  void setDefaultCompatToolFromName(String value) {
    _currentUserSettings.defaultCompatTool =  getCompatToolCodeFromDisplayName(value);
  }


  void save({bool showMessages=true}) {
    if(showMessages) EasyLoading.show(status: "saving_settings");

    SettingsRepository repo = GetIt.I<SettingsRepository>();
    //Super hacky, this should be inmutable, blah, blah. Just fire up the event
    repo.update(repo.getSettings());
    repo.save();

    if(showMessages) EasyLoading.showSuccess(tr("settings_saved"));

    //Request a reload next time i
    if(!_areSettingsPathEqual(_currentUserSettings, _oldCurrentUserSettings)) {
      GetIt.I<GamesRepository>().invalidateGamesCache();
    }

    //Leave the needed backups
    String homeFolder = FileTools.getHomeFolder();

    int currentBackups = _currentUserSettings.backupsEnabled ? _currentUserSettings.maxBackupsCount : 0;

    FileTools.clampBackupsToCount("$homeFolder/.local/share/Steam/userdata/${_currentUserId}/config/shortcuts.vdf", currentBackups);
    FileTools.clampBackupsToCount("$homeFolder/.local/share/Steam/config/config.vdf", currentBackups);

    emit(SettingsSaved(_currentUserSettings));
  }

  /*bool existsConfig() {
    Directory appFolder = Directory.current;
    return File("${appFolder.path}/$_configFilePath").existsSync();
  }*/

  bool _areSettingsPathEqual(UserSettings a, UserSettings b)
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
      bool existed = _currentUserSettings.searchPaths.contains(selectedDirectory);
      if(existed)
      {
        EasyLoading.showError(tr("path_duplicated"));
      }
      else {
        _currentUserSettings.searchPaths.add(selectedDirectory);
        emit(SearchPathsChanged(_currentUserSettings));
      }
    } else {
      // User canceled the picker
    }
  }

  removePath(String e) {
    _currentUserSettings.searchPaths.remove(e);
    emit(SearchPathsChanged(_currentUserSettings));
  }

  void setDarkThemeState(bool state) {
    _currentUserSettings.darkTheme = state;
    emit(GeneralOptionsChanged(_currentUserSettings));
  }

  void setEnableBackups(bool value) {
    _currentUserSettings.backupsEnabled = value;
    emit(GeneralOptionsChanged(_currentUserSettings));
  }

  void setMaxBackupCount(double value) {
    _currentUserSettings.maxBackupsCount = value.toInt();
    emit(GeneralOptionsChanged(_currentUserSettings));
  }




/*  bool getDarkThemeState() {
    return _settings.darkTheme;
  }*/

}
