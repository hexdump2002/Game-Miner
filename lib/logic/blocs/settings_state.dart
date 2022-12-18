part of 'settings_cubit.dart';

@immutable
abstract class SettingsState {
}

class SettingsInitial extends SettingsState {}

class SettingsChangedState extends SettingsState{
  final Settings settings;
  SettingsChangedState(this.settings);
}

class SearchPathsChanged extends SettingsState {
  final Settings settings;
  SearchPathsChanged(this.settings) ;
}

class SettingsLoaded extends SettingsState {
  final Settings settings;
  SettingsLoaded(this.settings);
}


class SettingsSaved extends SettingsState {
  final Settings settings;
  SettingsSaved(this.settings);
}

class SettingsThemeChanged extends SettingsState {
  final Settings settings;
  SettingsThemeChanged(this.settings);
}

class GeneralOptionsChanged extends SettingsState {
  final Settings settings;
  GeneralOptionsChanged(this.settings);
}