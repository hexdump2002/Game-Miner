part of 'main_dart_cubit.dart';

@immutable
abstract class MainPageState {
  final SteamUser steamUser;

  const MainPageState(this.steamUser);
}

class MainPageInitial extends MainPageState {
  const MainPageInitial(SteamUser user)  : super(user);
}

class SelectedPageIndexChanged extends MainPageState {
  final int selectedIndex;

  const SelectedPageIndexChanged( SteamUser user, this.selectedIndex) : super(user);
}

class MainStateUserChanged extends MainPageState {
  const MainStateUserChanged( SteamUser user) : super(user);
}
