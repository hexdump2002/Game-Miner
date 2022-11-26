import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

import '../../data/user_game.dart';
import '../Tools/file_tools.dart';

part 'non_steam_games_state.dart';

class NonSteamGamesCubit extends Cubit<NonSteamGamesBaseState> {

  NonSteamGamesCubit() : super(RetrievingGames());

  void findGames(List<String> searchPaths) async {
    emit(RetrievingGames());


    final List<UserGame> userGames = [];

    for(String searchPath in searchPaths) {
      List<String> gamesPath = await FileTools.getFolderFilesAsync(searchPath,retrieveRelativePaths: false, recursive: false);
      List<UserGame> ugs = gamesPath.map<UserGame>( (e) => UserGame(e) ).toList();

      userGames.addAll(ugs);

      //Find exe files
      for(UserGame ug in ugs) {
        List<String> exeFiles = await FileTools.getFolderFilesAsync(ug.path, retrieveRelativePaths: true, recursive: true, regExFilter: r".*\.exe$");
        ug.addExeFiles(exeFiles);
      }
    }

    await Future.delayed(Duration(seconds: 3));

    emit(GamesRetrieved(userGames));

  }
}
