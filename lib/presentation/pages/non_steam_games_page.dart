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
  late final NonSteamGamesCubit _bloc;

  @override
  void initState() {
    _bloc = BlocProvider.of<NonSteamGamesCubit>(context);
    _bloc.loadData(["/home/hexdump/Downloads/Games/"]);
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
                children: [Expanded(child: SingleChildScrollView(child: _buildListOfGames(context, state))), _buildBottomBar(context)],
              );
            },
          ),
        ));
  }

  Widget _buildListOfGames(BuildContext context, NonSteamGamesBaseState state) {
    if (state is RetrievingGameData) {
      return _waitingForGamesToBeRetrieved(context);
    } else if (state is GamesDataRetrieved) {
      return _createGameCards(context, (state as GamesDataRetrieved).games);
    } else if (state is GamesDataChanged) {
      return _createGameCards(context, (state as GamesDataChanged).games);
    } else if (state is GamesFoldingDataChanged) {
      GamesFoldingDataChanged foldingDataChanged = state as GamesFoldingDataChanged;
      return _createGameCards(context, (state as GamesFoldingDataChanged).games);
    }

    throw Exception("Unknown state type");
  }

  Widget _buildBottomBar(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(child: Text("Apply"), onPressed: () => {print("pressed!")}),
      )
    ]);
  }

  Widget _createGameCards(BuildContext context, List<VMUserGame> games) {
    List<ExpansionPanel> widgets = games.map<ExpansionPanel>((VMUserGame game) {
      return ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return ListTile(
            title: Text(game.userGame.name, style: Theme.of(context).textTheme.headline4, textAlign: TextAlign.left),
          );
        },
        body: _buildGameTile(context, game.userGame),
        isExpanded: game.foldingState,
      );
    }).toList();

    return ExpansionPanelList(
        expansionCallback: (int index, bool isExpanded) {
          _bloc.swapExpansionStateForItem(index);
        },
        children: widgets);
  }

  Widget _buildGameTile(BuildContext context, UserGame ug) {
    List<Widget> gameItems = [];

    List<UserGameExe> gameExePaths = ug.exeFileEntries;

    for (UserGameExe uge in gameExePaths) {
      bool added = uge.added;
      gameItems.add(Padding(
        padding: const EdgeInsets.fromLTRB(64, 8, 0, 8),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: Text(uge.relativeExePath, style: Theme.of(context).textTheme.headline6, textAlign: TextAlign.left),
              ),
              Row(children: [
                Switch(
                  value: uge.added,
                  onChanged: (value) {
                    _bloc.swapExeAdding(uge);
                    }),
                  //activeTrackColor: Colors.lightGreenAccent,
                  //activeColor: Colors.green,
                //IconButton(onPressed: uge.added ? () => true: null, icon: Icon(Icons.settings))
              ])
            ]),
            if (uge.added) _buildGameExeForm(uge)
          ],
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: gameItems,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  Widget _buildGameExeForm(UserGameExe uge) {
    var protons = ["Proton GE", "Proton XE", "Proton ME"];

    return Container(
      color: Color.fromARGB(255, 230, 230, 230),
      margin: EdgeInsets.fromLTRB(16, 8, 128, 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          child: Column(
            children: [
              TextFormField(
                initialValue: uge.name,
                decoration: const InputDecoration(labelText: "Name"),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                  items: protons.map<DropdownMenuItem<String>>((String e) {
                    return DropdownMenuItem<String>(value: e, child: Text(e));
                  }).toList(),
                  onChanged: (String? value) => print("cambio combo de protones a valor $value"),
                  decoration: const InputDecoration(labelText: "Proton"))
            ],
          ),
        ),
      ),
    );
  }

  Widget _waitingForGamesToBeRetrieved(BuildContext context) {
    return const CircularProgressIndicator();
  }
}
