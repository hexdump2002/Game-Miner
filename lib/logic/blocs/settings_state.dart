part of 'settings_cubit.dart';

@immutable
abstract class SettingsState {
  final Settings settings;
  SettingsState(this.settings);
}

class SettingsInitial extends SettingsState {
  SettingsInitial(Settings settings) : super(settings);
}

class SettingsChangedState extends SettingsState{
  SettingsChangedState(Settings settings) : super(settings);
}

class SearchPathsChanged extends SettingsState {
  SearchPathsChanged(settings)  : super(settings);
}

class SettingsLoaded extends SettingsState {
  SettingsLoaded(Settings settings) : super(settings);
}


class SettingsSaved extends SettingsState {
  SettingsSaved(Settings settings) : super(settings);
}

class SettingsThemeChanged extends SettingsState {
  SettingsThemeChanged(Settings settings) : super(settings);
}

class GeneralOptionsChanged extends SettingsState {
  GeneralOptionsChanged(Settings settings) : super(settings);
}