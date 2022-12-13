import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:steamdeck_toolbox/data/GlobalStats.dart';
import 'package:steamdeck_toolbox/data/game_folder_stats.dart';
import 'package:steamdeck_toolbox/logic/Tools/StringTools.dart';
import 'package:steamdeck_toolbox/logic/Tools/file_tools.dart';
import 'package:steamdeck_toolbox/logic/Tools/vdf_tools.dart';
import 'package:steamdeck_toolbox/logic/blocs/non_steam_games_cubit.dart';
import 'package:steamdeck_toolbox/logic/blocs/settings_cubit.dart';

import '../../data/user_game.dart';
import '../../logic/Tools/VMGameTools.dart';

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
              _nsgpBloc.sortByStatus();
            },
            icon: const Icon(Icons.stars),
            tooltip: "Sort By Status",
          ),
          IconButton(
            onPressed: () {
              _nsgpBloc.foldAll();
            },
            icon: const Icon(Icons.unfold_less),
            tooltip: "Sort By Status",
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
          IconButton(
            onPressed: () => null /*_nsgpBloc.showInfo()*/,
            icon: Icon(Icons.info),
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
            } else if (state is SettingsLoaded) {
              _nsgpBloc.refresh(state.settings);
            }
          }, builder: (context, settingsState) {
            return BlocBuilder<NonSteamGamesCubit, NonSteamGamesBaseState>(builder: (context, nsgState) {
              //print("[NonSteamGamesCubit Builder] State -> $nsgState");
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildDataScreen(context, nsgState),
              );
            });
          })),
    );
  }

  List<Widget> _buildDataScreen(BuildContext context, NonSteamGamesBaseState nsgState) {

    if (nsgState is RetrievingGameData) {
      EasyLoading.show(status: "Loading Games");
      return [Container()];
    } else if (nsgState is GamesDataRetrieved) {
      EasyLoading.dismiss();
      return [Expanded(
        child: Align(alignment: Alignment.topCenter,
          child: SingleChildScrollView(
              child: _createGameCards(context, nsgState.games, nsgState.availableProntonNames,nsgState.globalStats),
        )),
      ),_buildInfoBar(context,nsgState.globalStats)];
    } else if (nsgState is GamesDataChanged) {
      GamesDataChanged gdr = nsgState as GamesDataChanged;
      return [Expanded(
        child: Align(alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: _createGameCards(context, nsgState.games, nsgState.availableProntonNames,nsgState.globalStats),
            )),
      ),_buildInfoBar(context,nsgState.globalStats)];
    } else if (nsgState is GamesFoldingDataChanged) {
      EasyLoading.dismiss();
      return [Expanded(
        child: Align(alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: _createGameCards(context, nsgState.games, nsgState.availableProntonNames,nsgState.globalStats),
            )),
      ),_buildInfoBar(context,nsgState.globalStats)];
    }
    /*else if (settingsState is SearchPathsChanged) {
      _nsgpBloc.loadData(settingsState.searchPaths);
      return Container();
    }*/
    else {
      print("[Warning] Unknown state");
      return [Container()];
    }

    throw Exception("Unknown state type");
  }

  Widget _createGameCards(BuildContext context, List<VMUserGame> games, List<String> availableProntons, GlobalStats globalStats) {
    List<ExpansionPanel> widgets = games.map<ExpansionPanel>((VMUserGame game) {
      var gameAddedStatus = VMGameTools.getGameStatus(game);

      return ExpansionPanel(
        canTapOnHeader: true,
        headerBuilder: (BuildContext context, bool isExpanded) {
          return ListTile(
            title: Row(
              children: [
                Expanded(child: Text(game.userGame.name, style: Theme.of(context).textTheme.headline5, textAlign: TextAlign.left)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 24, 0),
                  child: _getExeCurrentStateIcon(gameAddedStatus),
                ),
                IconButton(
                  onPressed: () {
                    _nsgpBloc.renameGame(context, game);
                  },
                  icon: Icon(Icons.edit),
                  tooltip: "Rename",
                ),
                IconButton(
                  onPressed: () {
                    _nsgpBloc.deleteGame(context, game);
                  },
                  icon: Icon(Icons.delete),
                  tooltip: "Delete",
                ),
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

  Widget _getExeCurrentStateIcon(VMGameAddedStatus gameAddedStatus) {
    /*if(anyExeAddedAndProtonAssigned) return  const Icon(Icons.thumb_up, color:Colors.green);

    if(anyExeAdded) return  const Icon(Icons.check_circle, color:Colors.orangeAccent);

    return  const Icon(Icons.error_outline, color:Colors.red);*/
    Color color;
    if (gameAddedStatus == VMGameAddedStatus.FullyAdded)
      color = Colors.green;
    else if (gameAddedStatus == VMGameAddedStatus.Added)
      color = Colors.orangeAccent;
    else
      color = Colors.red;

    Container c = Container(height: 15, width: 15, color: color);

    return c;
  }

  Widget _buildInfoBar(BuildContext context, GlobalStats stats) {
    return Container(
        color: Colors.blueGrey,
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "${stats.getGameCount()} Registered Games",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Container(height: 15, width: 15, color: Colors.red),
            Padding(
              padding: EdgeInsets.fromLTRB(8,0,8,0),
              child: Text(
                stats.getNonAddedGameCount().toString(),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Container(height: 15, width: 15, color: Colors.orange),
            Padding(
              padding: EdgeInsets.fromLTRB(8,0,8,0),
              child: Text(
                stats.getAddedGameCount().toString(),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Container(height: 15, width: 15, color: Colors.green),
            Padding(
              padding: EdgeInsets.fromLTRB(8,0,8,0),
              child: Text(
                stats.getFullyAddedGameCount().toString(),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0,0,8,0),
              child: Row(
                children: [
                  Icon(Icons.sd_card),
                  Padding(
                    padding: EdgeInsets.fromLTRB(8,0,0,0),
                    child: Text(
                      "${StringTools.bytesToStorageUnity(stats.getSSDFreeSpace())} / ${StringTools.bytesToStorageUnity(stats.getSSDTotalSize())}",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0,0,8,0),
              child: Row(
                children:  [
                  Icon(Icons.storage),
                  Padding(
                    padding: EdgeInsets.fromLTRB(8,0,0,0),
                    child: Text("${StringTools.bytesToStorageUnity(stats.getSSDFreeSpace())} / ${StringTools.bytesToStorageUnity(stats.getSSDTotalSize())}",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ));
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
