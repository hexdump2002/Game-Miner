class SteamApp {
  late String appId;
  late String universe;
  late String name;
  late String stateFlags;
  late String installdir;
  late String lastUpdated;
  late String sizeOnDisk;
  late String stagingSize;
  late String buildid;
  late String lastOwner;
  late String updateResult;
  late String bytesToDownload;
  late String bytesDownloaded;
  late String bytesToStage;
  late String bytesStaged;
  late String targetBuildID;
  late String autoUpdateBehavior;
  late String allowOtherDownloadsWhileRunning;
  late String scheduledAutoUpdate;
  late List<Depot> installedDepots= [];
  Map<String,dynamic> userConfig = {};
  Map<String,dynamic> mountedConfig = {};


  late bool hasShaderCache;
  late bool hasCompatData;
  late int shaderCacheSize;
  late int compatDataSize;



  SteamApp();

  factory SteamApp.FromMap(Map<String, dynamic> obj, bool hasShaderCache, bool hasCompatData, int shaderCacheSize, int compatDataSize) {

    SteamApp sa = SteamApp();

    sa.appId = obj["appid"] as String ?? "";
    sa.universe= obj["universe"] ?? "";
    sa.name=obj["name"] ?? "";
    sa.stateFlags=obj["stateflags"] ?? "";
    sa.installdir=obj["installdir"] ?? "";
    sa.lastUpdated=obj["lastupdated"] ?? "";
    sa.sizeOnDisk=obj["sizeondisk"] ?? "";
    sa.stagingSize=obj["stagingsize"] ?? "";
    sa.buildid=obj["buildid"] ?? "";
    sa.lastOwner=obj["lastowner"] ?? "";
    sa.updateResult=obj["updateresult"] ?? "";
    sa.bytesToDownload=obj["bytestodownload"] ?? "";
    sa.bytesDownloaded=obj["bytesdownloaded"] ?? "";
    sa.bytesToStage=obj["bytestostage"] ?? "";
    sa.bytesStaged=obj["bytesstaged"] ?? "";
    sa.targetBuildID=obj["targetbuildid"] ?? "";
    sa.autoUpdateBehavior=obj["autoupdatebehavior"] ?? "";
    sa.allowOtherDownloadsWhileRunning=obj["allowotherdownloadswhilerunning"] ?? "";
    sa.scheduledAutoUpdate=obj["scheduledautoupdate"] ?? "";

    _fillInstalledDepots(obj["installeddepots"],sa);

    sa.userConfig = obj["userconfig"];
    sa.mountedConfig = obj["mountedconfig"];
    sa.shaderCacheSize = shaderCacheSize;
    sa.compatDataSize = compatDataSize;
    sa.hasShaderCache = hasShaderCache;
    sa.hasCompatData = hasCompatData;

    return sa;
  }

  static void _fillInstalledDepots(Map<String, dynamic> installedDepotsObj, SteamApp sa) {
    for(String key in installedDepotsObj.keys) {
      String id = key;
      String manifest = installedDepotsObj[key]["manifest"] ?? "";
      String size = installedDepotsObj[key]["size"] ?? "";
      sa.installedDepots.add(Depot(id, manifest, size));
    }
  }
}

class Depot {
  String id;
  String manifest;
  String size;

  Depot(this.id,this.manifest,this.size);
}