class Settings {

  String currentUserId = "";
  Map<String, UserSettings> _userSettings = {};

  Settings();

  Settings.fromJson(Map<String, dynamic> json) {
    currentUserId = json['currentUserId'];

    Map<String,dynamic> userSettings = json['userSettings'];

    _userSettings = userSettings.map((key, value) => MapEntry(key, UserSettings.fromJson(value)));
  }

  Map<String, dynamic> toJson() {
    return {'currentUserId': currentUserId, 'userSettings': _userSettings};
  }

  UserSettings? getUserSettings(String userId) {
    return _userSettings[userId];
  }

  void setUserSettings(String userId, UserSettings settings) {
    _userSettings[userId]=settings;
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
  bool darkTheme = false;
  bool backupsEnabled = true;
  int maxBackupsCount = 5;

  UserSettings();

  UserSettings.fromJson(Map<String, dynamic> json) {
    searchPaths = json['searchPaths'].map<String>((e) => e as String).toList();
    defaultCompatTool = json['defaultCompatTool'];
    darkTheme = json['darkTheme'];
    backupsEnabled = json['backupsEnabled'];
    maxBackupsCount = json['maxBackupsCount'];
  }

  Map<String, dynamic> toJson() {
    return {'searchPaths': searchPaths, 'defaultCompatTool': defaultCompatTool,  'darkTheme':darkTheme, 'backupsEnabled': backupsEnabled, 'maxBackupsCount': maxBackupsCount};
  }

  UserSettings clone() {
    return UserSettings.fromJson(toJson());
  }
}
