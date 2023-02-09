import '../../logic/Tools/file_tools.dart';
import '../models/game.dart';

class UserLibraryGamesDataProvider {

  Future<List<Game>> loadGames(List<String> searchPaths) async {
    final List<Game> userGames = [];

    for (String searchPath in searchPaths) {
      List<String>? gamesPath = await FileTools.getFolderFilesAsync(searchPath, retrieveRelativePaths: false, recursive: false, onlyFolders: true);
      if(gamesPath!=null) {
        List<Game> ugs = gamesPath.map<Game>((e) => Game.fromPath(e)).toList();

        userGames.addAll(ugs);

        List<Game> gamesToRemove = [];
        //Find exe files
        for (Game ug in ugs) {
          List<String>? exeFiles = await FileTools.getFolderFilesAsync(ug.path,
              retrieveRelativePaths: false, recursive: true, regExFilter: r".*\.(exe|sh|bat)$", regExCaseSensitive: false);
          if(exeFiles!=null) {
            ug.addExeFiles(exeFiles);
          }
          else
          {
            //Add it to be Removed because its contents can't be read
            userGames.remove(ug);
          }
        }

        //Remove games with problems when were read

      }
    }

    return userGames;
  }

}