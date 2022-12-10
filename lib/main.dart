import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:steamdeck_toolbox/logic/Tools/steam_tools.dart';
import 'package:steamdeck_toolbox/logic/blocs/non_steam_games_cubit.dart';
import 'package:steamdeck_toolbox/logic/blocs/settings_cubit.dart';
import 'package:steamdeck_toolbox/presentation/pages/non_steam_games_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:steamdeck_toolbox/presentation/pages/settings_page.dart';

late SettingsCubit _settingsCubit;

void main() async {
  //Close steam client
  //SteamTools.closeSteamClient();

  EasyLoading.init();

  _settingsCubit = SettingsCubit();
  await _settingsCubit.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _settingsCubit,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: "/",
        routes: _buildRoutes(),
        builder: EasyLoading.init(),
      ),
    );
  }

  _buildRoutes() {
    return {
      '/': (context) =>
          BlocProvider(
            create: (context) => NonSteamGamesCubit(_settingsCubit),
            child: const NonSteamGamesPage(),
          ),
      // When navigating to the "/second" route, build the SecondScreen widget.
      '/settings': (context) =>
          SettingsPage(),
    };
  }
}
