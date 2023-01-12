class Settings {


  List<String> searchPaths = [];

  String defaultCompatTool = "None";
  late String currentUserId;
  bool darkTheme = false;
  bool backupsEnabled = true;
  int maxBackupsCount = 5;

  Settings(this.currentUserId);

  Settings.fromJson(Map<String, dynamic> json) {
    searchPaths = json['searchPaths'].map<String>((e) => e as String).toList();
    defaultCompatTool = json['defaultCompatTool'];
    darkTheme = json['darkTheme'];
    backupsEnabled = json['backupsEnabled'];
    maxBackupsCount = json['maxBackupsCount'];
  }

  Map<String, dynamic> toJson() {
    return {'searchPaths': searchPaths, 'defaultCompatTool': defaultCompatTool,  'darkTheme':darkTheme, 'backupsEnabled': backupsEnabled, 'maxBackupsCount': maxBackupsCount};
  }

  Settings clone() {
    return Settings.fromJson(toJson());
  }
}
