import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:game_miner/logic/blocs/settings_cubit.dart';
import 'package:game_miner/presentation/pages/game_mgr_page.dart';
import 'package:game_miner/presentation/pages/settings_page.dart';

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
