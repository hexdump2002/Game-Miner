part of 'main_dart_cubit.dart';

@immutable
abstract class MainPageState {
  const MainPageState();
}

class MainPageInitial extends MainPageState {
  const MainPageInitial()  : super();
}

class SelectedPageIndexChanged extends MainPageState {
  final int selectedIndex;

  const SelectedPageIndexChanged( this.selectedIndex);
}
