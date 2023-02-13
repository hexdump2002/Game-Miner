part of 'game_mgr_cubit.dart';

@immutable
abstract class GameMgrBaseState {}

class IninitalState extends GameMgrBaseState {}

class RetrievingGameData extends GameMgrBaseState {}

//All states emiting all the data. This is not performant. We need to use smaller events to re-create as less widgets as we could
class BaseDataChanged extends GameMgrBaseState {
  final List<GameView> games;
  final List<String> availableProntonNames;
  final int notAddedGamesCount;
  final int addedGamesCount;
  final int fullyAddedGamesCount;
  final int addedExternal;
  final int freeSSDSpace;
  final int freeSDCardSpace;
  final int totalSSDSpace;
  final int totalSDCardSpace;
  final int sortIndex;
  final int sortDirectionIndex;
  final String searchText;
  final GameExecutableImageType gameExecutableImageType;
  final bool multiSelectionMode;

  BaseDataChanged(
      this.games,
      this.availableProntonNames,
      this.notAddedGamesCount,
      this.addedGamesCount,
      this.fullyAddedGamesCount,
      this.addedExternal,
      this.freeSSDSpace,
      this.freeSDCardSpace,
      this.totalSSDSpace,
      this.totalSDCardSpace,
      this.sortIndex,
      this.sortDirectionIndex,
      this.searchText,
      this.gameExecutableImageType,
      this.multiSelectionMode);
}

class GamesDataRetrieved extends BaseDataChanged {
  GamesDataRetrieved(
      List<GameView> games,
      List<String> availableProntonNames,
      int nonAddedGamesCount,
      int addedGamesCount,
      int fullyAddedGamesCount,
      int addedExternal,
      int freeSSDSpace,
      int freeSDCardSpace,
      int totalSSDSpace,
      int totalSDCardSpace,
      int sortIndex,
      int sortDirectionIndex,
      String searchText,
      GameExecutableImageType gameExecutableImageType,
      bool multiSelectionMode)
      : super(games, availableProntonNames, nonAddedGamesCount, addedGamesCount, fullyAddedGamesCount, addedExternal, freeSSDSpace, freeSDCardSpace,
            totalSSDSpace, totalSDCardSpace, sortIndex, sortDirectionIndex, searchText, gameExecutableImageType, multiSelectionMode);
}

class GamesDataChanged extends BaseDataChanged {
  GamesDataChanged(
      List<GameView> games,
      List<String> availableProntonNames,
      int nonAddedGamesCount,
      int addedGamesCount,
      int fullyAddedGamesCount,
      int addedExternal,
      int freeSSDSpace,
      int freeSDCardSpace,
      int totalSSDSpace,
      int totalSDCardSpace,
      int sortIndex,
      int sortDirectionIndex,
      String searchText,
      GameExecutableImageType gameExecutableImageType,
      bool multiSelectionMode)
      : super(games, availableProntonNames, nonAddedGamesCount, addedGamesCount, fullyAddedGamesCount, addedExternal, freeSSDSpace, freeSDCardSpace,
      totalSSDSpace, totalSDCardSpace, sortIndex, sortDirectionIndex, searchText, gameExecutableImageType, multiSelectionMode);
}

class GamesFoldingDataChanged extends BaseDataChanged {
  GamesFoldingDataChanged(
      List<GameView> games,
      List<String> availableProntonNames,
      int nonAddedGamesCount,
      int addedGamesCount,
      int fullyAddedGamesCount,
      int addedExternal,
      int freeSSDSpace,
      int freeSDCardSpace,
      int totalSSDSpace,
      int totalSDCardSpace,
      int sortIndex,
      int sortDirectionIndex,
      String searchText,
      GameExecutableImageType gameExecutableImageType,
      bool multiSelectionMode)
      : super(games, availableProntonNames, nonAddedGamesCount, addedGamesCount, fullyAddedGamesCount, addedExternal, freeSSDSpace, freeSDCardSpace,
      totalSSDSpace, totalSDCardSpace, sortIndex, sortDirectionIndex, searchText, gameExecutableImageType, multiSelectionMode);
}

class SearchTermChanged extends BaseDataChanged {
  SearchTermChanged(
      List<GameView> games,
      List<String> availableProntonNames,
      int nonAddedGamesCount,
      int addedGamesCount,
      int fullyAddedGamesCount,
      int addedExternal,
      int freeSSDSpace,
      int freeSDCardSpace,
      int totalSSDSpace,
      int totalSDCardSpace,
      int sortIndex,
      int sortDirectionIndex,
      String searchText,
      GameExecutableImageType gameExecutableImageType,
      bool multiSelectionMode)
      : super(games, availableProntonNames, nonAddedGamesCount, addedGamesCount, fullyAddedGamesCount, addedExternal, freeSSDSpace, freeSDCardSpace,
      totalSSDSpace, totalSDCardSpace, sortIndex, sortDirectionIndex, searchText, gameExecutableImageType, multiSelectionMode);
}

class DeleteGameClicked extends GameMgrBaseState {
  Game game;

  DeleteGameClicked(this.game);
}

class RenameGameClicked extends GameMgrBaseState {
  Game game;

  RenameGameClicked(this.game);
}

class SteamDetected extends GameMgrBaseState {
  VoidCallback okAction;

  SteamDetected(this.okAction);
}

class GameExecutableDataSet extends GameMgrBaseState {
  String name;
  String arguments;
  String compatToolDisplayName;

  GameExecutableDataSet(this.name, this.arguments, this.compatToolDisplayName);
}

class DeleteSelectedClicked extends GameMgrBaseState {
  DeleteSelectedClicked();
}