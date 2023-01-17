part of 'splash_cubit.dart';

@immutable
abstract class SplashState {}

class SplashInitial extends SplashState {}


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