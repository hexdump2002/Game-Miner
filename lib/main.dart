import 'package:flutter/material.dart';
import 'package:steamdeck_toolbox/logic/blocs/non_steam_games_cubit.dart';
import 'package:steamdeck_toolbox/presentation/pages/non_steam_games_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:steamdeck_toolbox/presentation/pages/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: "/",
        routes: _buildRoutes(),
    );
  }

  _buildRoutes() {
    return {
      '/': (context) => BlocProvider(
        create: (context) => NonSteamGamesCubit(),
        child: const NonSteamGamesPage(),
      ),
    // When navigating to the "/second" route, build the SecondScreen widget.
    '/settings': (context) => SettingsPage(),
    };
  }
}
