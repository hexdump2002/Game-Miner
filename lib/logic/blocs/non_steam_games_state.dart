part of 'non_steam_games_cubit.dart';

@immutable
abstract class NonSteamGamesBaseState {}

class RetrievingGameData extends NonSteamGamesBaseState{}

class GamesDataRetrieved extends NonSteamGamesBaseState{
  final List<VMUserGame> games;

  GamesDataRetrieved(this.games);
}

class GamesDataChanged extends NonSteamGamesBaseState{
  final List<VMUserGame> games;

  GamesDataChanged(this.games);
}

class GamesFoldingDataChanged extends NonSteamGamesBaseState{
  final List<VMUserGame> games;
  GamesFoldingDataChanged(this.games);
}