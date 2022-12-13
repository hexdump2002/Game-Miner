part of 'non_steam_games_cubit.dart';

@immutable
abstract class NonSteamGamesBaseState {}

class IninitalState extends NonSteamGamesBaseState{}

class RetrievingGameData extends NonSteamGamesBaseState{}

class GamesDataRetrieved extends NonSteamGamesBaseState{
  final List<VMUserGame> games;
  final List<String> availableProntonNames;
  final GlobalStats globalStats;

  GamesDataRetrieved(this.games, this.availableProntonNames, this.globalStats);
}

class GamesDataChanged extends NonSteamGamesBaseState{
  final List<VMUserGame> games;
  final List<String> availableProntonNames;
  final GlobalStats globalStats;

  GamesDataChanged(this.games, this.availableProntonNames, this.globalStats);
}

class GamesFoldingDataChanged extends NonSteamGamesBaseState{
  final List<VMUserGame> games;
  final List<String> availableProntonNames;
  final GlobalStats globalStats;

  GamesFoldingDataChanged(this.games, this.availableProntonNames, this.globalStats);
}