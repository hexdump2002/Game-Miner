class SteamUser {
  late final String accountName;
  late final String personName;
  late final String steamId64;
  late final String steamId32;
  String? _avatarHash;
  String? _avatarUrlMedium;
  String? _avatarUrlSmall;

  set avatarHash(value) {
    _avatarHash = value;
    _avatarUrlMedium ="https://avatars.akamai.steamstatic.com/${_avatarHash}_medium.jpg";
    _avatarUrlSmall= "https://avatars.akamai.steamstatic.com/${_avatarHash}.jpg";
  }

  get avatarHash => _avatarHash;
  get avatarUrlMedium => _avatarUrlMedium;
  get avatarUrlSmall => _avatarUrlSmall;

  SteamUser(this.accountName,this.personName, this.steamId64) {
    steamId32 = (int.parse(steamId64) - 76561197960265728).toString();
  }

  SteamUser.fromJson(Map<String, dynamic> json) {
    accountName = json['accountName'];
    personName = json['personName'];
    steamId64 = json['steamId'];
    steamId32 = (int.parse(steamId64) - 76561197960265728).toString();
  }

  Map<String, dynamic> toJson() {
    return {'accountName': accountName, 'personName': personName,  'steamId64':steamId64, 'steamId32':steamId32};
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