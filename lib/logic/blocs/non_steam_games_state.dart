part of 'non_steam_games_cubit.dart';

@immutable
abstract class NonSteamGamesBaseState {}

class IninitalState extends NonSteamGamesBaseState{}

class RetrievingGameData extends NonSteamGamesBaseState{}

class GamesDataRetrieved extends NonSteamGamesBaseState{
  final List<VMUserGame> games;
  final List<String> availableProntonNames;

  GamesDataRetrieved(this.games, this.availableProntonNames);
}

class GamesDataChanged extends NonSteamGamesBaseState{
  final List<VMUserGame> games;
  final List<String> availableProntonNames;

  GamesDataChanged(this.games, this.availableProntonNames);
}

class GamesFoldingDataChanged extends NonSteamGamesBaseState{
  final List<VMUserGame> games;
  final List<String> availableProntonNames;

  GamesFoldingDataChanged(this.games, this.availableProntonNames);
}