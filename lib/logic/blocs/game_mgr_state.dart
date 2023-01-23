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
  final List<bool> sortStates;
  final List<bool> sortDirectionStates;


  BaseDataChanged(this.games, this.availableProntonNames, this.notAddedGamesCount, this.addedGamesCount, this.fullyAddedGamesCount, this.addedExternal,this.freeSSDSpace,
      this.freeSDCardSpace, this.totalSSDSpace, this.totalSDCardSpace, this.sortStates, this.sortDirectionStates);
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
      List<bool> sortStates,
      List<bool> sortDirectionStates)
      : super(
      games,
      availableProntonNames,
      nonAddedGamesCount,
      addedGamesCount,
      fullyAddedGamesCount,
      addedExternal,
      freeSSDSpace,
      freeSDCardSpace,
      totalSSDSpace,
      totalSDCardSpace,
      sortStates,
      sortDirectionStates);
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
      List<bool> sortStates,
      List<bool> sortDirectionStates)
      : super(
      games,
      availableProntonNames,
      nonAddedGamesCount,
      addedGamesCount,
      fullyAddedGamesCount,
      addedExternal,
      freeSSDSpace,
      freeSDCardSpace,
      totalSSDSpace,
      totalSDCardSpace,
      sortStates,
      sortDirectionStates);
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
      List<bool> sortStates,
      List<bool> sortDirectionStates)
      : super(
      games,
      availableProntonNames,
      nonAddedGamesCount,
      addedGamesCount,
      fullyAddedGamesCount,
      addedExternal,
      freeSSDSpace,
      freeSDCardSpace,
      totalSSDSpace,
      totalSDCardSpace,
      sortStates,
      sortDirectionStates);
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
      List<bool> sortStates,
      List<bool> sortDirectionStates)
      : super(
      games,
      availableProntonNames,
      nonAddedGamesCount,
      addedGamesCount,
      fullyAddedGamesCount,
      addedExternal,
      freeSSDSpace,
      freeSDCardSpace,
      totalSSDSpace,
      totalSDCardSpace,
      sortStates,
      sortDirectionStates);
}

