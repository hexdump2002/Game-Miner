enum StorageType { ShaderCache, CompatData }
enum GameType { Steam, NonSteam }

class AppStorage {
  String appId;
  int size;
  StorageType storageType;
  String name;
  String installdir;
  GameType gameType;
  bool isUnknown;

  AppStorage(this.appId, this.name, this.installdir,this.storageType, this.size, this.gameType, this.isUnknown);
}