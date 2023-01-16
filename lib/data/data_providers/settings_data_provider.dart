import 'dart:convert';
import 'dart:io';

import 'package:game_miner/logic/Tools/file_tools.dart';

import '../models/settings.dart';

class SettingsDataProvider {
  final String _configFilePath = "settings.cfg";

  Settings loadSettings() {

    Directory appFolder = Directory.current;
    String fullPath = "${appFolder.path}/$_configFilePath";

    Settings settings = Settings();

    var file = File(fullPath);
    if(!file.existsSync())
    {
      saveSettings(settings);
    }
    else {
      file.openSync();
      String json = file.readAsStringSync();
      settings = Settings.fromJson(jsonDecode(json));
    }

    return settings;

    //TODO: What should we do now with this?
    /*if (_settings.defaultProtonCode!="None" && _settings.availableProtons.firstWhereOrNull((element) => element.protonCode == _settings.defaultProtonCode) == null) {
      throw Exception("The default configured proton is not valid");
    }*/
  }

  void saveSettings(Settings settings) {
    String json = jsonEncode(settings);
    Directory appFolder = Directory.current;
    String fullPath = "${appFolder.path}/$_configFilePath";
    File(fullPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(json);
  }
}
