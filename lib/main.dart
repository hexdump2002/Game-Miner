import 'package:flutter/material.dart';
import 'package:steamdeck_toolbox/logic/blocs/non_steam_games_cubit.dart';
import 'package:steamdeck_toolbox/presentation/pages/non_steam_games_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        home:  BlocProvider(
          create: (context) => NonSteamGamesCubit(),
          child: NonSteamGamesPage(),
        )
    );
  }
}
