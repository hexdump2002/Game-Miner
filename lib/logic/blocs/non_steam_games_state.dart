part of 'non_steam_games_cubit.dart';

@immutable
abstract class NonSteamGamesBaseState {}

//class InitialState extends NonSteamGamesBaseState {}

class RetrievingGameData extends NonSteamGamesBaseState{}

class GamesDataRetrieved extends NonSteamGamesBaseState{
  final List<UserGame> games;

  GamesDataRetrieved(this.games);
}
