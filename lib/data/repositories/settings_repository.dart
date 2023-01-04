import 'dart:async';

import 'package:game_miner/data/data_providers/settings_data_provider.dart';
import 'package:get_it/get_it.dart';

import '../models/settings.dart';

class SettingsRepository {
  final SettingsDataProvider _settingsDataProvider = GetIt.I<SettingsDataProvider>();
  Settings? _settings;

  //Open an stream of changes to config
  final _controller = StreamController<Settings>();
  Stream<Settings> get settings => _controller.stream;

  Settings? loadSettings(String userId) {
    if(_settings == null) {
      _settings = _settingsDataProvider.loadSettings(userId);
      _settings!.currentUserId = userId;
      _addToStream(_settings!);
    }

    //Return a copy of the settings
    return Settings.fromJson(_settings!.toJson());
  }

  Settings getSettings() {
    if(settings == null) {
      throw Exception("Settings are null because they hasn't been loaded. Aborting...");
    }
    return _settings!;
  }

  void update(Settings settings) {
    _settings = settings;
  }

  void save() {
    _settingsDataProvider.saveSettings(_settings!);
    _addToStream(_settings!);
  }

  /*Settings loadAndSaveDefault(String currentUserId) {
    _settings = Settings(currentUserId);
    save();

    return Settings.fromJson(_settings!.toJson());
  }*/

  Settings getSettingsForCurrentUser() {
    if(_settings == null) {
      throw Exception("Settings has not been initialized. Aborting");
    }
    return Settings.fromJson(_settings!.toJson());
  }

  void _addToStream(Settings settings) => _controller.sink.add(settings);
}