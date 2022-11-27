import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:steamdeck_toolbox/logic/Tools/file_tools.dart';
import 'package:steamdeck_toolbox/logic/blocs/non_steam_games_cubit.dart';

import '../../data/user_game.dart';

class NonSteamGamesPage extends StatefulWidget {
  const NonSteamGamesPage({Key? key}) : super(key: key);

  @override
  State<NonSteamGamesPage> createState() => _NonSteamGamesPageState();
}

class _NonSteamGamesPageState extends State<NonSteamGamesPage> {
  @override
  void initState() {
    var bloc = BlocProvider.of<NonSteamGamesCubit>(context);
    bloc.loadData(["/home/hexdump/Downloads/Games/"]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text("Non Steam Games Manager"),
        ),
        body: Container(
          alignment: Alignment.center,
          child: BlocBuilder<NonSteamGamesCubit, NonSteamGamesBaseState>(
            builder: (context, state) {
              return Column(
                children: [Expanded(child: _buildListOfGames(context, state)), _buildBottomBar(context)],
              );
            },
          ),
        ));
  }

  Widget _buildListOfGames(BuildContext context, NonSteamGamesBaseState state) {
    if (state is RetrievingGameData) {
      return _waitingForGamesToBeRetrieved(context);
    } else {
      return _createGameCards(context, (state as GamesDataRetrieved).games);
    }
  }
  Widget _buildBottomBar(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(child: Text("Apply"), onPressed: () => { print("pressed!")}),
      )
    ]);
  }

  Widget _createGameCards(BuildContext context, List<UserGame> games) {
    List<Widget> widgets = [];
    for (UserGame ug in games) {
      widgets.add(_createGameCard(context, ug));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: widgets, crossAxisAlignment: CrossAxisAlignment.start),
    );
  }

  Widget _createGameCard(BuildContext context, UserGame ug) {
    List<Widget> gameItems = [
      Text(
        ug.name,
        style: Theme.of(context).textTheme.headline4,
        textAlign: TextAlign.left,
      )
    ];

    List<UserGameExe> gameExePaths = ug.exeFileEntries;

    for (UserGameExe uge in gameExePaths) {
      gameItems.add(Padding(
        padding: const EdgeInsets.fromLTRB(64, 8, 0, 8),
        child: Row(children: [
          Expanded(
            child: Text(uge.relativeExePath, style: Theme.of(context).textTheme.headline6, textAlign: TextAlign.left),
          ),
          Row(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
              child: ElevatedButton( child: uge.added? Text("Remove"): Text("Add"), onPressed: ()=> {print("pressed")}),
            ),
          ])
        ]),
      ));
    }

    return Card(
        child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: gameItems,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    ));
  }

  Widget _waitingForGamesToBeRetrieved(BuildContext context) {
    return const CircularProgressIndicator();
  }


}
