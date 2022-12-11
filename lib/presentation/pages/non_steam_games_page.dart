import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:steamdeck_toolbox/logic/Tools/file_tools.dart';
import 'package:steamdeck_toolbox/logic/Tools/vdf_tools.dart';
import 'package:steamdeck_toolbox/logic/blocs/non_steam_games_cubit.dart';
import 'package:steamdeck_toolbox/logic/blocs/settings_cubit.dart';

import '../../data/user_game.dart';

class NonSteamGamesPage extends StatefulWidget {
  const NonSteamGamesPage({Key? key}) : super(key: key);

  @override
  State<NonSteamGamesPage> createState() => _NonSteamGamesPageState();
}

class _NonSteamGamesPageState extends State<NonSteamGamesPage> {
  late final NonSteamGamesCubit _nsgpBloc;

  late final SettingsCubit _settingsBloc;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _nsgpBloc = BlocProvider.of<NonSteamGamesCubit>(context);
    _settingsBloc = BlocProvider.of<SettingsCubit>(context);
    _nsgpBloc.loadData(_settingsBloc.getSettings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Non Steam Games Manager"),
        actions: [
          IconButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _nsgpBloc.saveData(_settingsBloc.getSettings());
              } else {
                print("There are errors in the form. Fix them!");
              }
            },
            icon: Icon(Icons.save),
            tooltip: "Save",
          ),
          IconButton(
            onPressed: () {
              _nsgpBloc.sortByName();
            },
            icon: Icon(Icons.receipt),
            tooltip: "Sort By Name",
          ),
          IconButton(
            onPressed: () {
              _nsgpBloc.sortByProtonAssigned();
            },
            icon: Icon(Icons.stars),
            tooltip: "Sort By Proton Assigned",
          ),
          IconButton(
            onPressed: () {
              _nsgpBloc.sortBySteamAdded();
            },
            icon: Icon(Icons.grade),
            tooltip: "Sort By Added",
          ),
          IconButton(
            onPressed: () {
              _nsgpBloc.refresh(_settingsBloc.getSettings());
            },
            icon: Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: Icon(Icons.settings),
            tooltip: "Settings",
          ),
        ],
      ),
      body: Container(
          alignment: Alignment.center,
          child: BlocConsumer<SettingsCubit, SettingsState>(listener: (
            context,
            state,
          ) {
            //print("[SetttingsCubit Consumer] State -> $state");
            if (state is SettingsSaved) {
              _nsgpBloc.refresh(state.settings);
            }
            else if(state is SettingsLoaded) {
              _nsgpBloc.refresh(state.settings);
            }
          }, builder: (context, settingsState) {
            return BlocBuilder<NonSteamGamesCubit, NonSteamGamesBaseState>(builder: (context, nsgState) {
              //print("[NonSteamGamesCubit Builder] State -> $nsgState");
              return Align(alignment: Alignment.topCenter, child: _buildListOfGames(context, nsgState));
            });
          })),
    );
  }

  Widget _buildListOfGames(BuildContext context, NonSteamGamesBaseState nsgState) {
    if (nsgState is RetrievingGameData) {
      EasyLoading.show(status:"Loading Games");
      return Container();
    } else if (nsgState is GamesDataRetrieved) {
      EasyLoading.dismiss();
      return SingleChildScrollView(
          child: _createGameCards(context, (nsgState as GamesDataRetrieved).games, (nsgState as GamesDataRetrieved).availableProntonNames));
    } else if (nsgState is GamesDataChanged) {
      EasyLoading.dismiss();
      return SingleChildScrollView(
          child: _createGameCards(context, (nsgState as GamesDataChanged).games, (nsgState as GamesDataChanged).availableProntonNames));
    } else if (nsgState is GamesFoldingDataChanged) {
      EasyLoading.dismiss();
      GamesFoldingDataChanged foldingDataChanged = nsgState as GamesFoldingDataChanged;
      return SingleChildScrollView(
          child: _createGameCards(context, (nsgState as GamesFoldingDataChanged).games, (nsgState as GamesFoldingDataChanged).availableProntonNames));
    }
    /*else if (settingsState is SearchPathsChanged) {
      _nsgpBloc.loadData(settingsState.searchPaths);
      return Container();
    }*/
    else {
      print("[Warning] Unknown state");
      return Container();
    }

    throw Exception("Unknown state type");
  }

  Widget _createGameCards(BuildContext context, List<VMUserGame> games, List<String> availableProntons) {
    List<ExpansionPanel> widgets = games.map<ExpansionPanel>((VMUserGame game) {
      var gameAddedData = _nsgpBloc.isProtonAssignedForGame(game);
      var anyExeAdded = gameAddedData[0];
      var anyExeAddedAndProtonAssigned = gameAddedData[1];
      return ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return ListTile(
            title: Row(
              children: [
                Expanded(child: Text(game.userGame.name, style: Theme.of(context).textTheme.headline5, textAlign: TextAlign.left)),
                _getExeCurrentStateIcon(anyExeAdded, anyExeAddedAndProtonAssigned)
              ],
            ),
          );
        },
        body: _buildGameTile(context, game.userGame, availableProntons),
        isExpanded: game.foldingState,
      );
    }).toList();

    return Form(
      key: _formKey,
      child: ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            _nsgpBloc.swapExpansionStateForItem(index);
          },
          children: widgets),
    );
  }

  Widget _buildGameTile(BuildContext context, UserGame ug, List<String> availableProtons) {
    List<Widget> gameItems = [];

    List<UserGameExe> gameExePaths = ug.exeFileEntries;

    for (UserGameExe uge in gameExePaths) {
      bool added = uge.added;
      gameItems.add(Padding(
        padding: const EdgeInsets.fromLTRB(64, 0, 0, 0),
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
                      _nsgpBloc.swapExeAdding(uge, _settingsBloc.getSettings().defaultProtonCode);
                    }),
                //activeTrackColor: Colors.lightGreenAccent,
                //activeColor: Colors.green,
                //IconButton(onPressed: uge.added ? () => true: null, icon: Icon(Icons.settings))
              ])
            ]),
            if (uge.added) _buildGameExeForm(uge, availableProtons)
          ],
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: gameItems,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  Widget _buildGameExeForm(UserGameExe uge, List<String> availableProntons) {
    return Container(
      color: Color.fromARGB(255, 230, 230, 230),
      margin: EdgeInsets.fromLTRB(16, 8, 128, 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              initialValue: uge.name,
              decoration: const InputDecoration(labelText: "Name"),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (value) => {uge.name = value!},
              /*onSaved: (value) => {
                uge.name = value!
              },*/
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
            DropdownButtonFormField<String>(
                items: availableProntons.map<DropdownMenuItem<String>>((String e) {
                  return DropdownMenuItem<String>(value: e, child: Text(e));
                }).toList(),
                value: _settingsBloc.getProtonNameForCode(uge.protonCode),
                onChanged: (String? value) => _nsgpBloc.setProtonDataFor(uge, value!),
                decoration: const InputDecoration(labelText: "Proton"))
          ],
        ),
      ),
    );
  }

  Widget _getExeCurrentStateIcon(bool anyExeAdded, bool anyExeAddedAndProtonAssigned) {
    if(anyExeAddedAndProtonAssigned) return  const Icon(Icons.thumb_up, color:Colors.green);

    if(anyExeAdded) return  const Icon(Icons.check_circle, color:Colors.orangeAccent);

    return  const Icon(Icons.error_outline, color:Colors.red);

  }

  /*Widget _waitingForGamesToBeRetrieved(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircularProgressIndicator(),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Loading Games"),
        )
      ],
    );
  }*/
}
