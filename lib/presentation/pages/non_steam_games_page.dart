import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:expandable/expandable.dart';
import 'package:game_miner/data/Stats.dart';
import 'package:game_miner/data/game_folder_stats.dart';
import 'package:game_miner/logic/Tools/StringTools.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';
import 'package:game_miner/logic/Tools/vdf_tools.dart';
import 'package:game_miner/logic/blocs/non_steam_games_cubit.dart';
import 'package:game_miner/logic/blocs/settings_cubit.dart';
import 'package:game_miner/main.dart';

import '../../data/user_game.dart';
import '../../logic/Tools/VMGameTools.dart';

class NonSteamGamesPage extends StatefulWidget {
  const NonSteamGamesPage({Key? key}) : super(key: key);

  @override
  State<NonSteamGamesPage> createState() => _NonSteamGamesPageState();
}

class _NonSteamGamesPageState extends State<NonSteamGamesPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
  }

  NonSteamGamesCubit _nsCubit(context) =>  BlocProvider.of<NonSteamGamesCubit>(context);
  SettingsCubit _settingsCubit(context) =>  BlocProvider.of<SettingsCubit>(context);
  Settings _settings(context) =>  BlocProvider.of<SettingsCubit>(context).getSettings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Game Manager"),
        actions: [
          BlocBuilder<NonSteamGamesCubit, NonSteamGamesBaseState>(
            builder: (context, nsgState) {
              return Row(children: [
                ToggleButtons(
                    direction: Axis.horizontal,
                    onPressed: (int index) {
                      var nsgpBloc = _nsCubit(context);
                      if (index == 0) {
                        nsgpBloc.sortByName();
                      } else if (index == 1) {
                        nsgpBloc.sortByStatus();
                      } else if (index == 2) {
                        nsgpBloc.sortBySize();
                      }
                    },
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    borderColor: Colors.blue,
                    selectedBorderColor: Colors.blue[200],
                    selectedColor: Colors.white,
                    fillColor: Colors.blue[300],
                    color: Colors.blue[300],
                    isSelected: _nsCubit(context).getSortStates(),
                    children: [
                      Tooltip(message: tr("sort_by_name"), child: const Icon(Icons.receipt)),
                      Tooltip(message: tr("sort_by_status"), child: const Icon(Icons.stars)),
                      Tooltip(message: tr("sort_by_size"), child: const Icon(Icons.storage))
                    ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                  child: ToggleButtons(
                      direction: Axis.horizontal,
                      onPressed: (int index) {
                        index == 0 ? _nsCubit(context).setSortDirection(SortDirection.Asc) : _nsCubit(context).setSortDirection(SortDirection.Desc);
                      },
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      borderColor: Colors.blue,
                      selectedBorderColor: Colors.blue[200],
                      selectedColor: Colors.white,
                      fillColor: Colors.blue[300],
                      color: Colors.blue[300],
                      isSelected: _nsCubit(context).getSortDirectionStates(),
                      children: [
                        Tooltip(message: tr("descending"), child: const Icon(Icons.south)),
                        Tooltip(message: tr("ascending"), child: const Icon(Icons.north))
                      ]),
                ),
                IconButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _nsCubit(context).saveData(_settings(context));
                    } else {
                      print("There are errors in the form. Fix them!");
                    }
                  },
                  icon: Icon(Icons.save),
                  tooltip: tr("save"),
                ),
                IconButton(
                  onPressed: () {
                    _nsCubit(context).foldAll();
                  },
                  icon: const Icon(Icons.unfold_less),
                  tooltip: tr("fold_all"),
                ),
                IconButton(
                  onPressed: () {
                    _nsCubit(context).refresh(_settings(context));
                  },
                  icon: Icon(Icons.refresh),
                  tooltip: tr("refresh"),
                ),
                /*IconButton(
                  onPressed: () async  {
                    var nsCubit = _nsCubit(context);
                    var settings = _settings(context);
                    bool? gameListDirtyDyn = await Navigator.pushNamed(context, '/settings') as bool;
                    if(gameListDirtyDyn!=null && gameListDirtyDyn) {
                      nsCubit.refresh(settings);
                    }
                  },
                  icon: const Icon(Icons.settings),
                  tooltip: tr("settings"),
                ),*/
                /*IconButton(
                  onPressed: () => null /*_nsgpBloc.showInfo()*/,
                  icon: Icon(Icons.info),
                  tooltip: "Settings",
                )*/
              ]);
            },
          ),
        ],
      ),
      body: Container(
          alignment: Alignment.center,
          child: BlocConsumer<SettingsCubit, SettingsState>(listener: (
            context,
            state,
          ) {
            if (state is SettingsSaved) {
              BlocProvider.of<NonSteamGamesCubit>(context).refresh(BlocProvider.of<SettingsCubit>(context).getSettings());
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
    CustomTheme themeExtension = Theme.of(context).extension<CustomTheme>()!;

    if (nsgState is RetrievingGameData) {
      EasyLoading.show(status: tr("loading_games"));
      return [Container()];
    } else if (nsgState is GamesDataRetrieved) {
      EasyLoading.dismiss();
      return [
        Expanded(
          child: Align(
              alignment: Alignment.topCenter,
              child: _createGameCards(context, nsgState, themeExtension)),
        ),
        _buildInfoBar(context, nsgState, themeExtension)
      ];
    } else if (nsgState is GamesDataChanged) {
      GamesDataChanged gdr = nsgState as GamesDataChanged;
      return [
        Expanded(
          child: Align(
              alignment: Alignment.topCenter,
              child: _createGameCards(context, nsgState, themeExtension)),
        ),
        _buildInfoBar(context, nsgState, themeExtension)
      ];
    } else if (nsgState is GamesFoldingDataChanged) {
      EasyLoading.dismiss();
      return [
        Expanded(
          child: Align(
              alignment: Alignment.topCenter,
              child: _createGameCards(context, nsgState, themeExtension)),
        ),
        _buildInfoBar(context, nsgState, themeExtension)
      ];
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

  Widget _createGameCards(BuildContext context, BaseDataChanged state, CustomTheme themeExtension) {
    var games = state.games;

    return Form(
        key: _formKey,
        child: ListView.builder(
            itemCount: games.length,
            itemBuilder: (BuildContext context, int index) {
              var game = games[index];
              return ExpandablePanel(
                controller: ExpandableController(initialExpanded:game.foldingState)..addListener(() => _nsCubit(context).swapExpansionStateForItem(index)),
                header: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(game.userGame.name, style: Theme.of(context).textTheme.headline5, textAlign: TextAlign.left)),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 24, 0),
                              child: game.userGame.isExternal ? null : Text(StringTools.bytesToStorageUnity(game.userGame.gameSize)),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 24, 0),
                              child: _getExeCurrentStateIcon(VMGameTools.getGameStatus(game)),
                            ),
                            IconButton(
                              onPressed: () {
                                _nsCubit(context).renameGame(context, game);
                              },
                              icon: Icon(Icons.edit),
                              tooltip: tr("rename_game"),
                            ),
                            IconButton(
                              onPressed: () {
                                _nsCubit(context).deleteGame(context, game);
                              },
                              icon: Icon(Icons.delete),
                              tooltip: tr("delete"),
                            ),
                          ],
                        ),
                        if (game.foldingState)
                          Text(
                            "${game.userGame.path}",
                            textAlign: TextAlign.left,
                            style: TextStyle(color: themeExtension.gameCardHeaderPath, fontSize: 13),
                          )
                      ],
                    ),
                  ),  expanded: Container(padding:EdgeInsets.fromLTRB(0, 16, 0, 16), margin: EdgeInsets.fromLTRB(16, 16, 16, 16), decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), color: Colors.black12
              ), child: _buildGameTile(context, themeExtension, game.userGame, state.availableProntonNames)),
                  collapsed: Container(),

              );
                }));
  }

/*Widget _createGameCards(BuildContext context, BaseDataChanged state, CustomTheme themeExtension) {

    List<ExpansionPanel> widgets = state.games.map<ExpansionPanel>((VMUserGame game) {
      var gameAddedStatus = VMGameTools.getGameStatus(game);

      return ExpansionPanel(
        canTapOnHeader: true,
        headerBuilder: (BuildContext context, bool isExpanded) {
          return ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(game.userGame.name, style: Theme.of(context).textTheme.headline5, textAlign: TextAlign.left)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 24, 0),
                      child: game.userGame.isExternal ? null : Text(StringTools.bytesToStorageUnity(game.userGame.gameSize)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 24, 0),
                      child: _getExeCurrentStateIcon(gameAddedStatus),
                    ),
                    IconButton(
                      onPressed: () {
                        _nsgpBloc.renameGame(context, game);
                      },
                      icon: Icon(Icons.edit),
                      tooltip: tr("rename_game"),
                    ),
                    IconButton(
                      onPressed: () {
                        _nsgpBloc.deleteGame(context, game);
                      },
                      icon: Icon(Icons.delete),
                      tooltip: tr("delete"),
                    ),
                  ],
                ),
                if(game.foldingState) Text("${game.userGame.path}",textAlign: TextAlign.left, style: TextStyle(color:themeExtension.gameCardHeaderPath, fontSize: 13),)
              ],
            ),
          );
        },
        body: _buildGameTile(context, themeExtension,  game.userGame, state.availableProntonNames),
        isExpanded: game.foldingState,
      );
    }).toList();

    return Form(
      key: _formKey,
      child: ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            _nsgpBloc.swapExpansionStateForItem(index);
          },
          children: widgets,),
    );
  }*/

  Widget _buildGameTile(BuildContext context, CustomTheme themeExtension, UserGame ug, List<String> availableProtons) {
    List<Widget> gameItems = [];

    List<UserGameExe> gameExePaths = ug.exeFileEntries;

    if (ug.exeFileEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        child: Container(
            decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.all(Radius.circular(40))),
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(tr("folder_no_contains_exe"), style: TextStyle(color: Colors.white, fontSize: 20), textAlign: TextAlign.center)),
      );
    }

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
                      _nsCubit(context).swapExeAdding(uge, _settings(context).defaultProtonCode);
                    }),
                //activeTrackColor: Colors.lightGreenAccent,
                //activeColor: Colors.green,
                //IconButton(onPressed: uge.added ? () => true: null, icon: Icon(Icons.settings))
              ])
            ]),
            if (uge.added) _buildGameExeForm(uge, themeExtension, availableProtons)
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

  Widget _buildGameExeForm(UserGameExe uge, CustomTheme themeExtension, List<String> availableProntons) {
    return Container(
      color: themeExtension.gameCardExeOptionsBg,
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
                  return tr("please_enter_text");
                }
                return null;
              },
            ),
            DropdownButtonFormField<String>(
                items: availableProntons.map<DropdownMenuItem<String>>((String e) {
                  return DropdownMenuItem<String>(value: e, child: Text(e));
                }).toList(),
                value: _settingsCubit(context).getProtonNameForCode(uge.protonCode),
                onChanged: (String? value) => _nsCubit(context).setProtonDataFor(uge, value!),
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
    else if (gameAddedStatus == VMGameAddedStatus.NonAdded)
      color = Colors.red;
    else {
      color = Colors.blue.shade200;
    }

    Container c = Container(height: 15, width: 15, color: color);

    return c;
  }

  Widget _buildInfoBar(BuildContext context, BaseDataChanged state, CustomTheme themeExtension) {
    return Container(
        color: themeExtension.infoBarBgColor,
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "${state.notAddedGamesCount + state.addedGamesCount + state.fullyAddedGamesCount} " + tr("discovered_games"),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Container(height: 15, width: 15, color: Colors.red),
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Text(
                state.notAddedGamesCount.toString(),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Container(height: 15, width: 15, color: Colors.orange),
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Text(
                state.addedGamesCount.toString(),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Container(height: 15, width: 15, color: Colors.green),
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Text(
                state.fullyAddedGamesCount.toString(),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Container(height: 15, width: 15, color: Colors.blue.shade200),
            Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text(
                  state.addedExternal.toString(),
                  style: TextStyle(color: Colors.white),
                )),
            Tooltip(
              message: "Free SD Card Space",
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8, 0),
                child: Row(
                  children: [
                    Icon(Icons.sd_card),
                    Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 0, 0),
                      child: Text(
                        "${StringTools.bytesToStorageUnity(state.freeSDCardSpace)} / ${StringTools.bytesToStorageUnity(state.totalSDCardSpace)}",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Tooltip(
              message: "Free SSD Space",
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8, 0),
                child: Row(
                  children: [
                    Icon(Icons.storage),
                    Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 0, 0),
                      child: Text(
                        "${StringTools.bytesToStorageUnity(state.freeSSDSpace)} / ${StringTools.bytesToStorageUnity(state.totalSSDSpace)}",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
