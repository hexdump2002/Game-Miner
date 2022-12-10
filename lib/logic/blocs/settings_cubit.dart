import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:meta/meta.dart';
import 'package:steamdeck_toolbox/logic/Tools/steam_tools.dart';

part 'settings_state.dart';

class ProtonVersion {
  late String protonCode;
  late String protonName;

  ProtonVersion(this.protonCode, this.protonName);

  ProtonVersion.fromJson(Map<String, dynamic> json) {
    protonCode = json['code'];
    protonName = json['name'];
  }

  Map<String, dynamic> toJson() {
    return {'code': protonCode, 'name': protonName};
  }
}

class Settings {
  List<String> searchPaths = [];
  late List<ProtonVersion> builtInProtons;
  final List<ProtonVersion> availableProtons = [];
  String defaultProtonCode = "None";
  late String currentUserId;

  Settings();

  Settings.fromJson(Map<String, dynamic> json) {
    searchPaths = json['searchPaths'].map<String>((e) => e as String).toList();
    defaultProtonCode = json['defaultProtonCode'];
    builtInProtons = json['builtinProtons'].map<ProtonVersion>((e) {
      return ProtonVersion(e['code'],e['name']);
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {'searchPaths': searchPaths, 'defaultProtonCode': defaultProtonCode, 'builtinProtons': builtInProtons};
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  late Settings _settings;
  final String _configFilePath = "settings.cfg";

  SettingsCubit() : super(SettingsInitial());

  Future<void> initialize() async {
    List<ProtonVersion> availableProtons = [];

    List<String> externalProtons = await SteamTools.loadExternalProtons();
    var externalProtonVersions = externalProtons.map((e) => ProtonVersion(e, e)).toList();
    availableProtons.addAll(externalProtonVersions);

    if (!existsConfig()) {
      _settings = Settings();
      _settings.builtInProtons = [
        ProtonVersion("proton_experimental", "Proton Experimental"),
        ProtonVersion("proton_7", "Proton 7.0-5"),
        ProtonVersion("proton_63", "Proton 6.3-8"),
        ProtonVersion("proton_513", "Proton 5.13-6"),
        ProtonVersion("proton_5", "Proton 5.0-10"),
        ProtonVersion("proton_411", "Proton 4.11-13"),
        ProtonVersion("proton_42", "Proton 4.2-9"),
        ProtonVersion("proton_316", "Proton 3.16-9"),
        ProtonVersion("proton_37", "Proton 3.7-8"),
        ProtonVersion("proton_hotfix", "Proton Hotfix"),
        ProtonVersion("steamlinuxruntime", "Steam Linux Runtime")
      ];

      _settings.defaultProtonCode = "None";
      save();

      availableProtons.addAll(_settings.builtInProtons);
      _settings.availableProtons.addAll(availableProtons);
      emit(SettingsLoaded(_settings));
    } else {
      load(availableProtons);
    }

    _settings.currentUserId = await SteamTools.getUserId();
  }

  void refresh() {
    emit(SearchPathsChanged(_settings.searchPaths));
  }

  List<String> getAvailableProtonNames() {
    var availableProtonNames = _settings.availableProtons.map((e) => e.protonName).toList();
    availableProtonNames.sort();
    availableProtonNames.insert(0,"None");

    return availableProtonNames;
  }

  void load(List<ProtonVersion> externalProtons) {
    Directory appFolder = Directory.current;
    String fullPath = "${appFolder.path}/$_configFilePath";
    var file = File(fullPath)..openSync();
    String json = file.readAsStringSync();
    _settings = Settings.fromJson(jsonDecode(json));
    _settings.availableProtons.addAll(externalProtons);
    _settings.availableProtons.addAll(_settings.builtInProtons);

    if (_settings.defaultProtonCode!="None" && _settings.availableProtons.firstWhereOrNull((element) => element.protonCode == _settings.defaultProtonCode) == null) {
      throw Exception("The default configured proton is not valid");
    }

    emit(SettingsLoaded(_settings));
  }

  void save() {
    EasyLoading.show(status: "Saving Settings");
    String json = jsonEncode(_settings);
    Directory appFolder = Directory.current;
    String fullPath = "${appFolder.path}/$_configFilePath";
    File(fullPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(json);
    EasyLoading.showSuccess("Settings saved");
    emit(SettingsSaved(_settings));
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

  String getProtonNameForCode(String protonCode) {
    if(protonCode == "None") return "None";

    return _settings.availableProtons.firstWhere((e) => e.protonCode == protonCode).protonName;
  }

  String getProtonCodeFromName(String protonName) {
    if(protonName == "None") return "None";

    return _settings.availableProtons.firstWhere((e) => e.protonName == protonName).protonCode;
  }

}
