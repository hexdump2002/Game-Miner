import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'global_state.dart';

class GlobalCubit extends Cubit<GlobalState> {
  GlobalCubit() : super(GlobalInitial());


}
