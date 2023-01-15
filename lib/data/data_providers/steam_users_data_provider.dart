/*import 'package:game_miner/data/models/steam_user.dart';

import '../../logic/Tools/file_tools.dart';



class SteamUsersDataProvider {
  Future<List<SteamUser>> loadUsers() async {
    String homeFolder = FileTools.getHomeFolder();
    //String path = "$homeFolder/.local/Steam/steam/userdata";
    String path = "$homeFolder/.local/share/Steam/userdata"; //Changed because of flatpak

    //Todo, check for empty folder
    var folders = await FileTools.getFolderFilesAsync(path, retrieveRelativePaths: true, recursive: false, regExFilter: "", onlyFolders: true);

    if (folders.isEmpty) throw Exception("It seems steam does not exist or it is not properly configuredd");

    return folders.map<SteamUser>((e) => SteamUser(e, "No name")).toList();
  }
}
*/