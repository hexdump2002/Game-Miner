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

  //TODO: Change for repository cache
  Settings load({bool forceLoad=false}) {
    if(_settings == null || forceLoad) {
      _settings = _settingsDataProvider.loadSettings();
      //_settings!.currentUserId = userId;
      _addToStream(_settings!);
    }

    //Return a copy of the settings
    return _settings!;
  }

  UserSettings? getSettingsForUser(String userId) {
    if(_settings == null) {
      throw Exception("Settings has not been initialized. Aborting");
    }
    return _settings!.getUserSettings(userId);
  }

  UserSettings? getSettingsForCurrentUser() {
    if(_settings == null) {
      throw Exception("Settings has not been initialized. Aborting");
    }
    return _settings!.getUserSettings(_settings!.currentUserId);
  }

  Settings getSettings() {
    if(_settings == null) {
      throw Exception("Settings are null because they hasn't been loaded. Aborting...");
    }
    return _settings!;
  }

  void updateUserSettings(String userId, UserSettings us) {
    if(_settings == null) {
      throw Exception("Settings has not been initialized. Aborting");
    }
    _settings!.setUserSettings(userId, us);
    _addToStream(_settings!);
  }
  void update(Settings settings) {
    _settings = settings;
    _addToStream(_settings!);
  }

  void updateByUser(String userId, UserSettings userSettings) {
      var userSettings = _settings!.getUserSettings(userId);
      if(userSettings == null) throw Exception("Can't update existing user settings. UserId was: ${userId}");

      _settings!.setUserSettings(userId,userSettings);
      _addToStream(_settings!);
  }

  void save() {
    _settingsDataProvider.saveSettings(_settings!);
  }

  void _addToStream(Settings settings) => _controller.sink.add(settings);
}