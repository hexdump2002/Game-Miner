class AppStorage {
  String appId;
  int shaderCacheSize;
  int compatDataSize;
  String name;
  String installdir;
  bool isSteamApp;

  AppStorage(this.appId, this.name, this.installdir, this.shaderCacheSize, this.compatDataSize, this.isSteamApp);
}