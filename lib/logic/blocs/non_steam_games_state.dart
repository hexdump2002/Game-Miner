part of 'non_steam_games_cubit.dart';

@immutable
abstract class NonSteamGamesBaseState {}

//class InitialState extends NonSteamGamesBaseState {}

class RetrievingGames extends NonSteamGamesBaseState{}

class GamesRetrieved extends NonSteamGamesBaseState{
  final List<UserGame> games;

  GamesRetrieved(this.games);
}
