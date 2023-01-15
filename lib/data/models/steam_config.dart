class SteamUser {
  late final String accountName;
  late final String personName;
  late final String steamId;

  SteamUser(this.accountName,this.personName, this.steamId);

  SteamUser.fromJson(Map<String, dynamic> json) {
    accountName = json['accountName'];
    personName = json['personName'];
    steamId = json['steamId'];
  }

  Map<String, dynamic> toJson() {
    return {'accountName': accountName, 'personName': personName,  'steamId':steamId};
  }

}

class LibraryFolderApp {
  String appId;
  String unknownField;

  LibraryFolderApp(this.appId, this.unknownField);
}

class LibraryFolder {
  late final String path;
  late final List<LibraryFolderApp> installedApps;

  LibraryFolder(this.path, this.installedApps);
}

class SteamConfig {
  final List<SteamUser> steamUsers;
  final List<LibraryFolder> libraryFolders;

  SteamConfig(this.steamUsers, this.libraryFolders);
}