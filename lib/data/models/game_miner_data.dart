class GameMinerData {
  Map<String,String> appsIdToName;

  GameMinerData(this.appsIdToName);

  factory GameMinerData.fromJson(Map<String, dynamic> json) {
    var appIdToName = Map<String,String>.from(json['appsIdMapping']) ;
    return GameMinerData(appIdToName);
  }

  Map<String, dynamic> toJson() {
    return {'appsIdMapping':appsIdToName};
  }
}