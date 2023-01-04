class Settings {


  List<String> searchPaths = [];

  String defaultCompatTool = "None";
  late String currentUserId;
  bool darkTheme = false;

  Settings(this.currentUserId);

  Settings.fromJson(Map<String, dynamic> json) {
    searchPaths = json['searchPaths'].map<String>((e) => e as String).toList();
    defaultCompatTool = json['defaultCompatTool'];
    darkTheme = json['darkTheme'];
  }

  Map<String, dynamic> toJson() {
    return {'searchPaths': searchPaths, 'defaultCompatTool': defaultCompatTool,  'darkTheme':darkTheme};
  }

  Settings clone() {
    return Settings.fromJson(toJson());
  }
}
