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

enum ExecutableNameProcesTextProcessingOption { noProcessing, capitalized, titleCase, upperCase, lowerCase }

class UserSettings {
  List<String> searchPaths = [];

  String defaultCompatTool = "not_assigned";
  bool darkTheme = true;
  bool backupsEnabled = true;
  int maxBackupsCount = 5;

  int defaultGameManagerView = 3; //Mid sized covers

  bool closeSteamAtStartUp = true;

  bool warnSteamOpenWhenSaving = true;

  bool executableNameProcessRemoveExtension = true;
  ExecutableNameProcesTextProcessingOption executableNameProcessTextProcessingOption = ExecutableNameProcesTextProcessingOption.noProcessing;

  UserSettings();

  UserSettings.fromJson(Map<String, dynamic> json) {
    searchPaths = json['searchPaths'].map<String>((e) => e as String).toList();
    defaultCompatTool = json['defaultCompatTool'];
    darkTheme = json['darkTheme'];
    closeSteamAtStartUp = json['closeSteamAtStartUp'];
    backupsEnabled = json['backupsEnabled'];
    maxBackupsCount = json['maxBackupsCount'];
    defaultGameManagerView = json['defaultGameManagerView'];

    //To provide compatibility with previous versions of config we have to check for config
    executableNameProcessRemoveExtension = json['executableNameProcessRemoveExtension'] ?? false;
    executableNameProcessTextProcessingOption = json['executableNameProcessTextProcessingOption'] != null
        ? ExecutableNameProcesTextProcessingOption.values[json['executableNameProcessTextProcessingOption']]
        : ExecutableNameProcesTextProcessingOption.noProcessing;

    //Backward compatibility
    if (defaultCompatTool == "None") defaultCompatTool = "not_assigned";
  }

  Map<String, dynamic> toJson() {
    assert(defaultCompatTool != "None");

    return {
      'searchPaths': searchPaths,
      'defaultCompatTool': defaultCompatTool,
      'darkTheme': darkTheme,
      'closeSteamAtStartUp': closeSteamAtStartUp,
      'backupsEnabled': backupsEnabled,
      'maxBackupsCount': maxBackupsCount,
      'defaultGameManagerView': defaultGameManagerView,
      'executableNameProcessTextProcessingOption': executableNameProcessTextProcessingOption.index,
      'executableNameProcessRemoveExtension': executableNameProcessRemoveExtension
    };
  }

  UserSettings clone() {
    return UserSettings.fromJson(toJson());
  }
}
