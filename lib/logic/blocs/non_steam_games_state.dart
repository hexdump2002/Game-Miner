part of 'non_steam_games_cubit.dart';

@immutable
abstract class NonSteamGamesBaseState {}

class IninitalState extends NonSteamGamesBaseState{}

class RetrievingGameData extends NonSteamGamesBaseState{}

class GamesDataRetrieved extends NonSteamGamesBaseState{
  final List<VMUserGame> games;
  final List<String> availableProntonList;

  GamesDataRetrieved(this.games, this.availableProntonList);
}

class GamesDataChanged extends NonSteamGamesBaseState{
  final List<VMUserGame> games;
  final List<String> availableProntonList;

  GamesDataChanged(this.games, this.availableProntonList);
}

class GamesFoldingDataChanged extends NonSteamGamesBaseState{
  final List<VMUserGame> games;
  final List<String> availableProntonList;

  GamesFoldingDataChanged(this.games, this.availableProntonList);
}