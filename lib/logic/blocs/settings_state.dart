part of 'settings_cubit.dart';

@immutable
abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SearchPathsChanged extends SettingsState {
  late final  List<String> searchPaths;

  SearchPathsChanged(this.searchPaths);
}

class SettingsSaved extends SettingsState {
  late final  List<String> searchPaths;

  SettingsSaved(this.searchPaths);
}
