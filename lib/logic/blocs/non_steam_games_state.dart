part of 'non_steam_games_cubit.dart';

@immutable
abstract class NonSteamGamesBaseState {}

class IninitalState extends NonSteamGamesBaseState {}

class RetrievingGameData extends NonSteamGamesBaseState {}

//All states emiting all the data. This is not performant. We need to use smaller events to re-create as less widgets as we could
class BaseDataChanged extends NonSteamGamesBaseState {
  final List<Game> games;
  final List<bool> gamesFoldingState;
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


  BaseDataChanged(this.games, this.gamesFoldingState, this.availableProntonNames, this.notAddedGamesCount, this.addedGamesCount, this.fullyAddedGamesCount, this.addedExternal,this.freeSSDSpace,
      this.freeSDCardSpace, this.totalSSDSpace, this.totalSDCardSpace, this.sortStates, this.sortDirectionStates);
}

class GamesDataRetrieved extends BaseDataChanged {
  GamesDataRetrieved( List<Game> games,
      List<bool> gamesFoldingState,
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
      gamesFoldingState,
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
      List<Game> games,
      List<bool> gamesFoldingState,
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
      gamesFoldingState,
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
      List<Game> games,
      List<bool> gamesFoldingState,
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
      gamesFoldingState,
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
