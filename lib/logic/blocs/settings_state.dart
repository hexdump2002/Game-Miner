part of 'settings_cubit.dart';

@immutable
abstract class SettingsState {
  final UserSettings settings;
  final bool modified;
  SettingsState(this.settings, this.modified);
}

class SettingsInitial extends SettingsState {
  SettingsInitial(UserSettings settings, bool modified) : super(settings, modified);
}

class SettingsChangedState extends SettingsState{
  SettingsChangedState(UserSettings settings, bool modified) : super(settings, modified);
}

class SearchPathsChanged extends SettingsState {
  SearchPathsChanged(UserSettings settings, bool modified) : super(settings, modified);
}

class SettingsLoaded extends SettingsState {
  SettingsLoaded(UserSettings settings, bool modified) : super(settings, modified);
}


class SettingsSaved extends SettingsState {
  SettingsSaved(UserSettings settings, bool modified) : super(settings, modified);
}

class SettingsThemeChanged extends SettingsState {
  SettingsThemeChanged(UserSettings settings, bool modified) : super(settings, modified);
}

class GeneralOptionsChanged extends SettingsState {
  GeneralOptionsChanged(UserSettings settings, bool modified) : super(settings, modified);
}