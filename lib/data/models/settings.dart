class Settings {

  String currentUserId = "";
  Map<String, UserSettings> _userSettings = {};

  Settings();

  Settings.fromJson(Map<String, dynamic> json) {
    currentUserId = json['currentUserId'];

    Map<String, dynamic> userSettings = json['userSettings'];

    _userSettings = userSettings.map((key, value) => MapEntry(key, UserSettings.fromJson(value)));
  }

  Map<String, dynamic> toJson() {
    return {'currentUserId': currentUserId, 'userSettings': _userSettings};
  }

  UserSettings? getUserSettings(String userId) {
    return _userSettings[userId];
  }

  void setUserSettings(String userId, UserSettings settings) {
    _userSettings[userId] = settings;
  }

  Settings clone() {
    return Settings.fromJson(toJson());
  }

  UserSettings? getCurrentUserSettings() {
    return getUserSettings(currentUserId);
  }

}

class UserSettings {

  List<String> searchPaths = [];

  String defaultCompatTool = "None";
  bool darkTheme = true;
  bool backupsEnabled = true;
  int maxBackupsCount = 5;

  int defaultGameManagerView = 3; //Mid sized covers

  bool closeSteamAtStartUp = true;

  bool warnSteamOpenWhenSaving = true;

  UserSettings();

  UserSettings.fromJson(Map<String, dynamic> json) {
    searchPaths = json['searchPaths'].map<String>((e) => e as String).toList();
    defaultCompatTool = json['defaultCompatTool'];
    darkTheme = json['darkTheme'];
    closeSteamAtStartUp = json['closeSteamAtStartUp'];
    backupsEnabled = json['backupsEnabled'];
    maxBackupsCount = json['maxBackupsCount'];
    defaultGameManagerView = json['defaultGameManagerView'];
  }

  Map<String, dynamic> toJson() {
    return {
      'searchPaths': searchPaths,
      'defaultCompatTool': defaultCompatTool,
      'darkTheme': darkTheme,
      'closeSteamAtStartUp': closeSteamAtStartUp,
      'backupsEnabled': backupsEnabled,
      'maxBackupsCount': maxBackupsCount,
      'defaultGameManagerView': defaultGameManagerView
    };
  }

  UserSettings clone() {
    return UserSettings.fromJson(toJson());
  }
}
