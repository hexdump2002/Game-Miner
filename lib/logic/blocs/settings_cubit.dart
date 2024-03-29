import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:game_miner/data/repositories/compat_tools_repository.dart';
import 'package:game_miner/data/repositories/games_repository.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/logic/Tools/compat_tool_tools.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';
import 'package:game_miner/presentation/pages/view_image_type_common.dart';
import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';

import '../../data/models/compat_tool.dart';
import '../../data/models/settings.dart';
import '../Tools/steam_tools.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  late UserSettings _currentUserSettings; //Settings after modifications
  late UserSettings _oldUserSettings; //Settings we got when we entered
  late String _currentUserId;
  bool _modified = false;

  bool get modified => _modified;

  List<CompatTool> _availableCompatTools = [];

  SettingsCubit() : super(SettingsInitial(UserSettings(), false)) {
    SettingsRepository repo = GetIt.I<SettingsRepository>();
    _currentUserId = repo.load().currentUserId;
    _oldUserSettings = repo.getSettingsForCurrentUser()!;
    _currentUserSettings = _oldUserSettings.clone();

    emit(SettingsLoaded(_currentUserSettings, _modified));
  }

  Future<List<CompatTool>> initialize() async {
    Future<List<CompatTool>> compatTools = GetIt.I<CompatToolsRepository>().loadCompatTools();
    compatTools.then((value) => _availableCompatTools = value);
    return compatTools;
  }

  UserSettings getUserSettings() {
    return _currentUserSettings;
  }

  List<String> getAvailableCompatToolDisplayNames() {
    return CompatToolTools.getAvailableCompatToolDisplayNames(_availableCompatTools);
  }

  String getDefaultCompatToolDisplayNameFromCode() {
    return getCompatToolDisplayNameFromCode(_currentUserSettings.defaultCompatTool);
  }

  String getCompatToolDisplayNameFromCode(String code) {
    return CompatToolTools.getCompatToolDisplayNameFromCode(code, _availableCompatTools);
  }

  String getCompatToolCodeFromDisplayName(String displayName) {
    return CompatToolTools.getCompatToolCodeFromDisplayName(displayName, _availableCompatTools);
  }

  void setDefaultCompatToolFromName(String value) {
    _currentUserSettings.defaultCompatTool = getCompatToolCodeFromDisplayName(value);
    _modified = true;
    emit(GeneralOptionsChanged(_currentUserSettings, _modified));
  }

  void save({bool showMessages = true}) {
    if (showMessages) EasyLoading.show(status: "saving_settings");

    SettingsRepository repo = GetIt.I<SettingsRepository>();

    //Check if our search paths and the one we have in filter are in sync
    //Removed will be removed from filter and newly added will be added with showing = true 
    
    //filter == null means that no filter has been saved into configuration
    if(_currentUserSettings.filter!=null) {
      //Add new ones (Because we added to the filter they will be active in advanced filter dialog)
      List<String> newPaths = _currentUserSettings.searchPaths.where((element) => !_currentUserSettings.filter!.searchPaths.contains(element)).toList();
      _currentUserSettings.filter!.searchPaths.addAll(newPaths);

      //Remove the ones that are not in searchpath anymore
      List<String> removedPaths = _currentUserSettings.filter!.searchPaths.where((element) => !_currentUserSettings.searchPaths.contains(element)).toList();
      _currentUserSettings.filter!.searchPaths.removeWhere((element) => removedPaths.contains(element));
    }



    //Super hacky, this should be inmutable, blah, blah. Just fire up the event
    repo.updateUserSettings(_currentUserId, _currentUserSettings);
    repo.save();

    if (showMessages) EasyLoading.showToast(tr("settings_saved"));

    //Request a reload next time i
    if (!_areSettingsPathEqual(_currentUserSettings, _oldUserSettings)) {
      GetIt.I<GamesRepository>().invalidateGamesCache();
    }

    //Leave the needed backups
    String homeFolder = FileTools.getHomeFolder();

    int currentBackups = _currentUserSettings.backupsEnabled ? _currentUserSettings.maxBackupsCount : 0;

    FileTools.clampBackupsToCount("${SteamTools.getSteamBaseFolder()}/userdata/${_currentUserId}/config/shortcuts.vdf", currentBackups);
    FileTools.clampBackupsToCount("${SteamTools.getSteamBaseFolder()}/config/config.vdf", currentBackups);

    //Force a reload for every other using getSettings() get the fresh data
    //repo.load(forceLoad: true);

    _modified = false;
    emit(SettingsSaved(_currentUserSettings, _modified));
  }

  bool _areSettingsPathEqual(UserSettings a, UserSettings b) {
    List<String> listA = a.searchPaths;
    List<String> listB = b.searchPaths;

    if (listA.length != listB.length) return false;

    bool equal = true;
    int i = 0;
    while (equal && i < listA.length) {
      if (listB.contains(listB[i])) equal = false;
    }

    return equal;
  }

  pickPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      bool existed = _currentUserSettings.searchPaths.contains(selectedDirectory);
      if (existed) {
        EasyLoading.showError(tr("path_duplicated"));
      } else {
        _currentUserSettings.searchPaths.add(selectedDirectory);
        _modified = true;
        emit(SearchPathsChanged(_currentUserSettings, _modified));
      }
    } else {
      // User canceled the picker
    }
  }

  removePath(String e) {
    _currentUserSettings.searchPaths.remove(e);
    _modified = true;
    emit(SearchPathsChanged(_currentUserSettings, _modified));
  }

  void setDarkThemeState(bool state) {
    _currentUserSettings.darkTheme = state;
    _modified = true;
    emit(GeneralOptionsChanged(_currentUserSettings, _modified));
  }

  void setEnableBackups(bool value) {
    _currentUserSettings.backupsEnabled = value;
    _modified = true;
    emit(GeneralOptionsChanged(_currentUserSettings, _modified));
  }

  void setMaxBackupCount(double value) {
    _currentUserSettings.maxBackupsCount = value.toInt();
    _modified = true;
    emit(GeneralOptionsChanged(_currentUserSettings, _modified));
  }

  void setCloseSteamAtStartUp(bool value) {
    _currentUserSettings.closeSteamAtStartUp = value;
    _modified = true;
    emit(GeneralOptionsChanged(_currentUserSettings, _modified));
  }

  setDefaultGameManagerView(String viewTypeString) {
    int index = viewTypesStr.indexWhere((element) => element == viewTypeString);
    _currentUserSettings.defaultGameManagerView = index;
    _modified = true;
    emit(GeneralOptionsChanged(_currentUserSettings, _modified));
  }

  void setExecutableNameProcessRemoveExtension(bool value) {
    _currentUserSettings.executableNameProcessRemoveExtension = value;
    _modified = true;
    emit(GeneralOptionsChanged(_currentUserSettings, _modified));
  }

  setDefaultNameProcessTextProcessingOption(ExecutableNameProcesTextProcessingOption executableNameProcesTextProcessingOption) {
    _currentUserSettings.executableNameProcessTextProcessingOption = executableNameProcesTextProcessingOption;
    _modified = true;
    emit(GeneralOptionsChanged(_currentUserSettings, _modified));
  }


  void addGameMinerDesktopIcons() async {
    bool success =
    await FileTools.createAppShortcutIcons("packages/game_miner/appassets/icon.png", "packages/game_miner/appassets/GameMiner.desktop");
    if (success) {
      EasyLoading.showToast(tr("desktop_icons_added"));
      return;
    }

    EasyLoading.showToast(tr("desktop_icons_add_error"));
  }

  void removeGameMinerDesktopIcons() async{
    bool success = await FileTools.removeAppShortcutIcons();
    if (success) {
      EasyLoading.showToast(tr("desktop_icons_removed"));
      return;
    }

    EasyLoading.showToast(tr("desktop_icons_remove_error"));
  }

/*  bool getDarkThemeState() {
    return _settings.darkTheme;
  }*/
}
