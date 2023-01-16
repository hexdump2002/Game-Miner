part of 'settings_cubit.dart';

@immutable
abstract class SettingsState {
  final UserSettings settings;
  SettingsState(this.settings);
}

class SettingsInitial extends SettingsState {
  SettingsInitial(UserSettings settings) : super(settings);
}

class SettingsChangedState extends SettingsState{
  SettingsChangedState(UserSettings settings) : super(settings);
}

class SearchPathsChanged extends SettingsState {
  SearchPathsChanged(UserSettings settings)  : super(settings);
}

class SettingsLoaded extends SettingsState {
  SettingsLoaded(UserSettings settings) : super(settings);
}


class SettingsSaved extends SettingsState {
  SettingsSaved(UserSettings settings) : super(settings);
}

class SettingsThemeChanged extends SettingsState {
  SettingsThemeChanged(UserSettings settings) : super(settings);
}

class GeneralOptionsChanged extends SettingsState {
  GeneralOptionsChanged(UserSettings settings) : super(settings);
}