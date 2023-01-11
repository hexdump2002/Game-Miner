import '../../logic/Tools/file_tools.dart';
import '../models/game.dart';

class UserLibraryGamesDataProvider {

  Future<List<Game>> loadGames(List<String> searchPaths) async {
    final List<Game> userGames = [];

    for (String searchPath in searchPaths) {
      List<String> gamesPath = await FileTools.getFolderFilesAsync(searchPath, retrieveRelativePaths: false, recursive: false, onlyFolders: true);
      List<Game> ugs = gamesPath.map<Game>((e) => Game.fromPath(e)).toList();

      userGames.addAll(ugs);

      //Find exe files
      for (Game ug in ugs) {
        List<String> exeFiles = await FileTools.getFolderFilesAsync(ug.path,
            retrieveRelativePaths: false, recursive: true, regExFilter: r".*\.(exe|sh|bat)$", regExCaseSensitive: false);
        ug.addExeFiles(exeFiles);
      }
    }

    return userGames;
  }

}