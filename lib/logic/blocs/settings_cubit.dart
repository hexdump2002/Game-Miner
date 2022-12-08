import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:meta/meta.dart';
import 'package:steamdeck_toolbox/logic/Tools/steam_tools.dart';

part 'settings_state.dart';

class Settings {
  List<String> searchPaths = [];
  late String defaultProton;
  late String currentUserId;

  Settings();

  Settings.fromJson(Map<String,dynamic> json) {
    searchPaths = json['searchPaths'].map<String>( (e) => e as String).toList();
    defaultProton = json['defaultProton'];
  }

  Map<String,dynamic> toJson() {
    return {
      'searchPaths': searchPaths,
      'defaultProton': defaultProton
    };
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  late Settings _settings;
  final String _configFilePath = "settings.cfg";

  late final List<String> _protons;

  SettingsCubit() : super(SettingsInitial());

  Future<void> initialize() async {
    _protons = await SteamTools.loadProtons();
    _protons.insert(0,"None");
    if (!existsConfig()) {
      _settings = Settings();
      _settings.defaultProton = _protons.first;
      save();
      emit(SearchPathsChanged(_settings.searchPaths));
    }
    else {
      load();
    }

    _settings.currentUserId = await SteamTools.getUserId();
  }

  void refresh() {
    emit(SearchPathsChanged(_settings.searchPaths));
  }

  List<String> getProtons() {
    return _protons;
  }

  void load() {
    Directory appFolder = Directory.current;
    String fullPath = "${appFolder.path}/$_configFilePath";
    var file =  File(fullPath)..openSync();
    String json = file.readAsStringSync();
    _settings = Settings.fromJson(jsonDecode(json));

    if(_protons.firstWhereOrNull((element) => element == _settings.defaultProton) == null) {
      throw Exception("The default configured proton is not valid");
    }

    emit(SearchPathsChanged(_settings.searchPaths));
  }

  void save() {
    EasyLoading.show(status: "Saving Settings");
    String json = jsonEncode(_settings);
    Directory appFolder = Directory.current;
    String fullPath = "${appFolder.path}/$_configFilePath";
    File(fullPath)..createSync(recursive: true)..writeAsStringSync(json);
    EasyLoading.showSuccess("Settings saved");
    emit(SettingsSaved(_settings.searchPaths));
  }

  bool existsConfig() {
    Directory appFolder = Directory.current;
    return File("${appFolder.path}/$_configFilePath").existsSync();
  }

  getSettings() {
    return _settings;
  }

  pickPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      _settings.searchPaths.add(selectedDirectory);
      emit(SearchPathsChanged(_settings.searchPaths));
    } else {
      // User canceled the picker
    }
  }

  removePath(String e) {
    _settings.searchPaths.remove(e);
    emit(SearchPathsChanged(_settings.searchPaths));
  }


}
