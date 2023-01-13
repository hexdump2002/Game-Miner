import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'main_dart_state.dart';

class MainPageCubit extends Cubit<MainPageState> {
  int _selectecIndex = 0;
  set selectedIndex(int val)  {
    _selectecIndex = val;
    emit(SelectedPageIndexChanged(_selectecIndex));
  }
  int get selectedIndex => _selectecIndex;

  MainPageCubit() : super(const MainPageInitial());
}
