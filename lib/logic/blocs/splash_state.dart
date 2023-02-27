part of 'splash_cubit.dart';

@immutable
abstract class SplashState {}

class SplashInitial extends SplashState {}

class GameMinerUpdateFound extends SplashState {
  final Release release;
  final String currentGMVersion;
  GameMinerUpdateFound(this.release, this.currentGMVersion);
}

class ShowSteamUsersDialog extends SplashState {
  final String caption;
  final List<SteamUser> users;
  ShowSteamUsersDialog(this.caption, this.users);
}

class UserAutoLogged extends SplashState {
  final SteamUser user;
  UserAutoLogged(this.user);
}

class SplashWorkDone extends SplashState {

}

class UpdateDownloadingPercentageUpdated extends SplashState {
  String percent;
  UpdateDownloadingPercentageUpdated(this.percent);
}

class UpdateDownloadComplete extends SplashState {
}