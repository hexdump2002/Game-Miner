
class GameExecutableExportedData {
  late final String compatToolCode;
  late final String executableName;
  late final String executableOptions;
  late final String executableRelativePath;

  GameExecutableExportedData(this.compatToolCode, this.executableRelativePath, this.executableName, this.executableOptions);

  GameExecutableExportedData.fromJson(Map<String, dynamic> json) {
    compatToolCode = json['compatToolCode'];
    executableName = json['executableName'];
    executableRelativePath= json['executableRelativePath'];
    executableOptions = json['executableOptions'];
  }

  Map<String, dynamic> toJson() {
    return {
      'compatToolCode': compatToolCode,
      'executableName': executableName,
      'executableOptions': executableOptions,
      'executableRelativePath':executableRelativePath
    };
  }
}

class GameExportedData {
  late List<GameExecutableExportedData> executables;

  GameExportedData(this.executables);

  GameExportedData.fromJson(Map<String, dynamic> json) {
    executables = json['executables'].map<GameExecutableExportedData>((jsonMap)=> GameExecutableExportedData.fromJson(jsonMap)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'executables': executables,
    };
  }
}