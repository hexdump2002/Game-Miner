import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter_popup_menu_button/menu_direction.dart';
import 'package:flutter_popup_menu_button/menu_icon.dart';
import 'package:flutter_popup_menu_button/menu_item.dart';
import 'package:flutter_popup_menu_button/popup_menu_button.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/logic/Tools/string_tools.dart';
import 'package:game_miner/logic/blocs/game_mgr_cubit.dart';
import 'package:game_miner/main.dart';
import 'package:game_miner/presentation/widgets/searchbar/searchbar_widget.dart';
import 'package:get_it/get_it.dart';
import 'package:collection/collection.dart';
import 'package:window_manager/window_manager.dart';
import '../../data/models/game_executable.dart';
import '../../data/models/game.dart';
import '../../data/models/settings.dart';
import '../../data/repositories/games_repository.dart';
import '../../logic/Tools/game_tools.dart';
import '../../logic/Tools/steam_tools.dart';

//WARNING: THIS CLASS USES A LOT OF NON BEST PRACTICES. FOR EXAMPLE: A CUBIT SHOULD BE PORTABLE AND THIS ONE RECEIVES A LOT OF BUILDCONTEXT
class GameMgrPage extends StatefulWidget {
  const GameMgrPage({Key? key}) : super(key: key);

  @override
  State<GameMgrPage> createState() => _GameMgrPageState();
}

class _GameMgrPageState extends State<GameMgrPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _genericTextController = TextEditingController();

  @override
  void initState() {
    _nsCubit(context).loadData();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  GameMgrCubit _nsCubit(context) => BlocProvider.of<GameMgrCubit>(context);
  final UserSettings _userSettings = GetIt.I<SettingsRepository>()!.getSettingsForCurrentUser()!;

  @override
  Widget build(BuildContext context) {
    final stopwatch = Stopwatch()..start();

    Widget widgets = Scaffold(
      appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text("Game Manager"),
          actions: [
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: SearchBar(_nsCubit(context).searchText, tr("search"), (term) => _nsCubit(context).filterGamesByName(term))),
            ),
            BlocBuilder<GameMgrCubit, GameMgrBaseState>(
              builder: (context, state) {
                return Row(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ToggleButtons(
                        direction: Axis.horizontal,
                        onPressed: (int index) {
                          var nsgpBloc = _nsCubit(context);
                          if (index == 0) {
                            nsgpBloc.sortFilteredByName();
                          } else if (index == 1) {
                            nsgpBloc.sortFilteredByStatus();
                          } else if (index == 2) {
                            nsgpBloc.sortFilteredBySize();
                          } else if (index == 3) {
                            nsgpBloc.sortFilteredByWithErrors();
                          }
                        },
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        /*selectedBorderColor: Colors.blue[700],
                        selectedColor: Colors.white,
                        fillColor: Colors.blue[200],
                        color: Colors.blue[400],*/
                        /*borderColor: Colors.blue,
                        selectedBorderColor: Colors.blue[200],
                        selectedColor: Colors.white,
                        fillColor: Colors.blue[300],
                        color: Colors.blue[300],*/
                        isSelected: _nsCubit(context).getSortStates(),
                        children: [
                          Tooltip(message: tr("sort_by_name"), child: const Icon(Icons.receipt)),
                          Tooltip(message: tr("sort_by_status"), child: const Icon(Icons.stars)),
                          Tooltip(message: tr("sort_by_size"), child: const Icon(Icons.storage)),
                          Tooltip(message: tr("sort_by_info"), child: const Icon(Icons.warning))
                        ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
                    child: ToggleButtons(
                        direction: Axis.horizontal,
                        onPressed: (int index) {
                          index == 0 ? _nsCubit(context).setSortDirection(SortDirection.Asc) : _nsCubit(context).setSortDirection(SortDirection.Desc);
                        },
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        /*borderColor: Colors.blue,
                        selectedBorderColor: Colors.blue[200],
                        selectedColor: Colors.white,
                        fillColor: Colors.blue[300],
                        color: Colors.blue[300],*/
                        isSelected: _nsCubit(context).getSortDirectionStates(),
                        children: [
                          Tooltip(message: tr("descending"), child: const Icon(Icons.south)),
                          Tooltip(message: tr("ascending"), child: const Icon(Icons.north))
                        ]),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _nsCubit(context).trySave();
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
                      _nsCubit(context).refresh(context);
                    },
                    icon: Icon(Icons.refresh),
                    tooltip: tr("refresh"),
                  ),
                ]);
              },
            )
          ]),
      body: ExpandableTheme(
          data: const ExpandableThemeData(hasIcon: false),
          child: Container(
              alignment: Alignment.center,
              child: BlocConsumer<GameMgrCubit, GameMgrBaseState>(listener: (context, state) {
                if (state is DeleteGameClicked) {
                  _deleteGame(context, state.game);
                } else if (state is SteamDetected) {
                  showSteamActiveWhenSaving(context, state.okAction);
                } else if (state is RenameGameClicked) {
                  _renameGame(context, state.game);
                }
              }, buildWhen: (previous, current) {
                return current is! DeleteGameClicked && current is! SteamDetected && current is! RenameGameClicked;
              }, builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildDataScreen(context, state),
                );
              }))),
    );

    stopwatch.stop();
    print('[UI] Time taken to execute method: ${stopwatch.elapsed}');

    return widgets;
  }

  List<Widget> _buildDataScreen(BuildContext context, GameMgrBaseState nsgState) {
    CustomTheme themeExtension = Theme.of(context).extension<CustomTheme>()!;

    if (nsgState is RetrievingGameData) {
      EasyLoading.show(status: tr("loading_games"));
      return [Container()];
    } else if (nsgState is GamesDataRetrieved) {
      EasyLoading.dismiss();
      return [
        Expanded(
          child: Align(alignment: Alignment.topCenter, child: _createGameCards(context, nsgState, themeExtension)),
        ),
        _buildInfoBar(context, nsgState, themeExtension)
      ];
    } else if (nsgState is GamesDataChanged) {
      GamesDataChanged gdr = nsgState as GamesDataChanged;
      return [
        Expanded(
          child: Align(alignment: Alignment.topCenter, child: _createGameCards(context, nsgState, themeExtension)),
        ),
        _buildInfoBar(context, nsgState, themeExtension)
      ];
    } else if (nsgState is GamesFoldingDataChanged) {
      EasyLoading.dismiss();
      return [
        Expanded(
          child: Align(alignment: Alignment.topCenter, child: _createGameCards(context, nsgState, themeExtension)),
        ),
        _buildInfoBar(context, nsgState, themeExtension)
      ];
    } else if (nsgState is SearchTermChanged) {
      return [
        Expanded(
          child: Align(alignment: Alignment.topCenter, child: _createGameCards(context, nsgState, themeExtension)),
        ),
        _buildInfoBar(context, nsgState, themeExtension)
      ];
    } else {
      //print("[Warning] Unknown state");
      return [Container()];
    }

    throw Exception("Unknown state type");
  }

  Widget _buildMenu(GameView gameView) {
    return !gameView.game.isExternal
        ? FlutterPopupMenuButton(
            direction: MenuDirection.left,
            decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(20)), color: Colors.white),
            popupMenuSize: const Size(200, 240),
            child: FlutterPopupMenuIcon(
              key: GlobalKey(),
              child: Icon(Icons.more_vert),
            ),
            children: [
              FlutterPopupMenuItem(
                  closeOnItemClick: true,
                  onTap: () => _nsCubit(context).openFolder(gameView.game),
                  child: ListTile(
                    leading: const Icon(Icons.folder, color: Colors.grey
                        //disabledColor: _userSettings.darkTheme ? Colors.grey.shade800 : Colors.grey.shade300,
                        ),
                    title: Text(
                      tr("open_folder"),
                      style: TextStyle(color: Colors.black),
                    ),
                  )),
              FlutterPopupMenuItem(
                  closeOnItemClick: true,
                  onTap: () => _nsCubit(context).tryRenameGame(context, gameView.game),
                  child: ListTile(
                    leading: Icon(Icons.edit, color: Colors.grey
                        //disabledColor: _userSettings.darkTheme ? Colors.grey.shade800 : Colors.grey.shade300,
                        ),
                    title: Text(tr("rename_game"), style: TextStyle(color: Colors.black)),
                  )),
              FlutterPopupMenuItem(
                  closeOnItemClick: true,
                  onTap: () => _nsCubit(context).tryDeleteGame(gameView.game),
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.grey),
                    title: Text(tr("delete_game"), style: TextStyle(color: Colors.black)),
                  )),
              FlutterPopupMenuItem(
                  closeOnItemClick: true,
                  onTap: () => _nsCubit(context).exportGame(gameView.game),
                  child: ListTile(
                    hoverColor: Colors.grey,
                    leading: Icon(Icons.import_export, color: Colors.grey),
                    title: Text(tr("export_config"), style: TextStyle(color: Colors.black)),
                  )),
              FlutterPopupMenuItem(
                  closeOnItemClick: true,
                  onTap: () => _resetGameToConfigFile(gameView),
                  child: ListTile(
                    hoverColor: Colors.grey,
                    leading: Icon(Icons.import_export, color: Colors.grey),
                    title: Text(tr("reset_to_config"), style: TextStyle(color: Colors.black)),
                  )),
            ],
          )
        : Icon(Icons.more_vert, color: _userSettings.darkTheme ? Colors.grey.shade700 : Colors.grey.shade300);
  }

  Widget _createGameCards(BuildContext context, BaseDataChanged state, CustomTheme themeExtension) {
    var gamesView = state.games;
    return Form(
        key: _formKey,
        child: ListView.builder(
            itemCount: gamesView.length,
            itemBuilder: (BuildContext context, int index) {
              var gameView = gamesView[index];
              return ExpandablePanel(
                controller: ExpandableController(initialExpanded: gameView.isExpanded)
                  ..addListener(() => _nsCubit(context).swapExpansionStateForItem(index)),
                header: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(gameView.game.name, style: Theme.of(context).textTheme.headline5, textAlign: TextAlign.left)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 24, 0),
                            child: gameView.game.isExternal ? null : Text(StringTools.bytesToStorageUnity(gameView.game.gameSize)),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                            child: _getExeCurrentStateIcon(GameTools.getGameStatus(gameView.game)),
                          ),
                          _getErrorsOrModifiedIcon(gameView),
                          _buildMenu(gameView)
                        ],
                      ),
                      if (gameView.isExpanded)
                        Text(
                          "${gameView.game.path}",
                          textAlign: TextAlign.left,
                          style: TextStyle(color: themeExtension.gameCardHeaderPath, fontSize: 13),
                        )
                    ],
                  ),
                ),
                expanded: Container(
                    padding: EdgeInsets.fromLTRB(0, 16, 0, 16),
                    margin: EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black12),
                    child: _buildGameTile(context, themeExtension, gameView, state.availableProntonNames)),
                collapsed: Container(),
              );
            }));
  }

  Widget _buildGameTile(BuildContext context, CustomTheme themeExtension, GameView gv, List<String> availableProtons) {
    List<Widget> gameItems = [];

    List<GameExecutable> gameExePaths = gv.game.exeFileEntries;

    if (gv.game.exeFileEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        child: Container(
            decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.all(Radius.circular(40))),
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(tr("folder_no_contains_exe"), style: TextStyle(color: Colors.white, fontSize: 20), textAlign: TextAlign.center)),
      );
    }

    for (GameExecutable uge in gameExePaths) {
      bool added = uge.added;
      bool error = uge.errors.isNotEmpty;
      gameItems.add(Padding(
        padding: const EdgeInsets.fromLTRB(38, 0, 0, 0),
        child: Column(
          children: [
            Row(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: Tooltip(
                    child: Icon(Icons.warning, color: error ? Colors.red : Color(0)), message: error ? _buildErrorTextForGameExecutable(uge) : ""),
              ),
              Expanded(
                child: Text(uge.relativeExePath, style: Theme.of(context).textTheme.headline6, textAlign: TextAlign.left),
              ),
              Row(children: [
                Switch(
                    value: uge.added,
                    onChanged: (value) {
                      _nsCubit(context).swapExeAdding(gv, uge);
                    }),
                //activeTrackColor: Colors.lightGreenAccent,
                //activeColor: Colors.green,
                //IconButton(onPressed: uge.added ? () => true: null, icon: Icon(Icons.settings))
              ])
            ]),
            if (uge.added) _buildGameExeForm(gv, uge, themeExtension, availableProtons)
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

  Widget _buildGameExeForm(GameView gv, GameExecutable uge, CustomTheme themeExtension, List<String> availableProntons) {
    bool hasCompatToolError = uge.hasErrorType(GameExecutableErrorType.InvalidProton);
    GameExecutableError? invalidProtonError = uge.errors.firstWhereOrNull((element) => element.type == GameExecutableErrorType.InvalidProton);
    if (invalidProtonError != null) {
      availableProntons = [invalidProtonError.data, ...availableProntons];
    }

    GameMgrCubit nsgc = _nsCubit(context);
    return Container(
      color: themeExtension.gameCardExeOptionsBg,
      margin: EdgeInsets.fromLTRB(32, 8, 128, 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              key: GlobalKey(), //TODO: fix This should be reusable not created one eachtime
              initialValue: uge.name,
              decoration: InputDecoration(labelText: tr("name")),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (value) {
                uge.name = value!;
                gv.modified = true;
                _nsCubit(context).notifyDataChanged();
              },
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
            TextFormField(
              initialValue: uge.launchOptions,
              decoration: InputDecoration(labelText: tr("launch_options")),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (value) {
                uge.launchOptions = value!;
                gv.modified = true;
                _nsCubit(context).notifyDataChanged();
              },
              /*onSaved: (value) => {
                uge.name = value!
              },
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return tr("please_enter_text");
                }
                return null;
              },*/
            ),
            DropdownButtonFormField<String>(
                items: availableProntons.map<DropdownMenuItem<String>>((String e) {
                  return DropdownMenuItem<String>(value: e, child: Text(e));
                }).toList(),
                value: invalidProtonError != null ? invalidProtonError.data : nsgc.getCompatToolDisplayNameFromCode(uge.compatToolCode),
                onChanged: (String? value) => nsgc.setCompatToolDataFor(gv, uge, value!),
                decoration: const InputDecoration(labelText: "Compat Tool"))
          ],
        ),
      ),
    );
  }

  Widget _getExeCurrentStateIcon(GameStatus gameAddedStatus) {
    Color color;
    if (gameAddedStatus == GameStatus.FullyAdded) {
      color = Colors.green;
    } else if (gameAddedStatus == GameStatus.Added) {
      color = Colors.orange;
    } else if (gameAddedStatus == GameStatus.NonAdded) {
      color = Colors.red;
    } else {
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
              message: tr("free_sd_card_space"),
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
              message: tr("free_ssd_space"),
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

  String _buildErrorTextForGameExecutable(GameExecutable uge) {
    String error = "";

    GameExecutableError? exeError = uge.errors.firstWhereOrNull((element) => element.type == GameExecutableErrorType.BrokenExecutable);
    if (exeError != null) {
      error += tr('broken_executable');
    }

    exeError = uge.errors.firstWhereOrNull((element) => element.type == GameExecutableErrorType.InvalidProton);
    if (exeError != null) {
      if (error.isNotEmpty) {
        error += "\n\n";
      }
      error += tr('invalid_compat_tool', args: [exeError.data]);
    }

    return error;
  }

  _getErrorsOrModifiedIcon(GameView gv) {
    Icon icon;
    String msg = "";
    bool hasErrors = gv.game.hasErrors();
    bool modified = gv.modified;

    if (hasErrors && modified) {
      icon = const Icon(Icons.save, color: Colors.red);
      msg = tr("game_modified");
    } else if (hasErrors) {
      icon = const Icon(Icons.warning, color: Colors.red);
      msg = tr("game_has_config_errors");
    } else if (modified) {
      icon = const Icon(Icons.save, color: Colors.orange);
      msg = tr("game_modified");
    } else {
      icon = const Icon(Icons.save, color: Color(0x00000000));
    }

    return Tooltip(
      message: msg,
      child: icon,
    );
  }

  void _deleteGame(BuildContext context, Game game) {
    var nsCubit = _nsCubit(context);
    showPlatformDialog(
      context: context,
      builder: (context) {
        bool deleteImages = true, deleteCompatData = true, deleteShaderData = true;
        return BasicDialogAlert(
          title: Row(children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 8.0, 0),
              child: Icon(Icons.warning, color: Colors.red),
            ),
            Text(tr('warning'))
          ]),
          content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                    text: TextSpan(children: [
                  TextSpan(text: tr("going_to"), style: TextStyle(color: Colors.black)),
                  TextSpan(text: tr("delete_capitals"), style: TextStyle(color: Colors.redAccent)),
                  TextSpan(text: tr("delete_game_dialog_text", args: ['${game.name}']), style: TextStyle(color: Colors.black)),
                  TextSpan(text: tr("warning_action_undone"), style: TextStyle(color: Colors.red, fontSize: 18, height: 2))
                ])),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                          child: CheckboxListTile(
                              dense: true,
                              title: Text(
                                "CompatData",
                                style: TextStyle(fontSize: 14),
                              ),
                              value: deleteCompatData,
                              onChanged: (value) => setState(() => deleteCompatData = value!))),
                      Expanded(
                          child: CheckboxListTile(
                              dense: true,
                              title: Text("ShaderData", style: TextStyle(fontSize: 14)),
                              value: deleteShaderData,
                              onChanged: (value) => setState(() => deleteShaderData = value!))),
                    ]),
                    Row(
                      children: [
                        Expanded(
                            child: CheckboxListTile(
                                dense: true,
                                title: Text("Images", style: TextStyle(fontSize: 14)),
                                value: deleteImages,
                                onChanged: (value) => setState(() => deleteImages = value!))),
                        Expanded(child: Container())
                      ],
                    )
                  ]),
                )
              ],
            );
          }),
          actions: <Widget>[
            BasicDialogAction(
              title: Text("OK"),
              onPressed: () async {
                nsCubit.deleteGame(game, deleteImages, deleteCompatData, deleteShaderData);
                Navigator.pop(context);
              },
            ),
            BasicDialogAction(
              title: Text(tr("cancel")),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _resetGameToConfigFile(GameView gv) async {
    var nsCubit = _nsCubit(context);
    showPlatformDialog(
      context: context,
      builder: (context) {
        return BasicDialogAlert(
          title: Row(children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 8.0, 0),
              child: Icon(Icons.warning, color: Colors.red),
            ),
            Text(tr('warning'))
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr("reset_to_config_dialog_text")),
              ]),

          actions: <Widget>[
            BasicDialogAction(
              title: Text("OK"),
              onPressed: ()  {
                nsCubit.resetConfig(gv);
                Navigator.pop(context);
              },
            ),
            BasicDialogAction(
              title: Text(tr("cancel")),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _renameGame(BuildContext context, Game game) {
    GameMgrCubit cubit = _nsCubit(context);
    _genericTextController.text = game.name;

    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text(tr("rename_game")),
        content: Padding(
          padding: EdgeInsets.all(8),
          child: TextField(
            controller: _genericTextController,
          ),
        ),
        actions: <Widget>[
          BasicDialogAction(
              title: Text("OK"),
              onPressed: () async {
                var text = _genericTextController.text;
                RegExp r = RegExp(r'^[\w\-. ]+$');

                if (!r.hasMatch(text)) {
                  showPlatformDialog(
                      context: context,
                      builder: (context) => BasicDialogAlert(
                              title: Text(tr('invalid_game_name')),
                              content: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text("The name is not valid. You can use numbers, letters,  and '-','_','.' characters.")),
                              actions: [
                                BasicDialogAction(
                                    title: Text("OK"),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    })
                              ]));
                  return;
                }
                cubit.renameGame(game, _genericTextController.text);
                Navigator.pop(context);
              }),
          BasicDialogAction(
            title: Text(tr("cancel")),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void showSteamActiveWhenSaving(BuildContext context, VoidCallback actionFunction) {
    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text(tr('warning')),
        content: Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(
                Icons.warning,
                color: Colors.red,
                size: 100,
              ),
            ),
            Expanded(child: Text(tr("steam_is_running_cant_action")))
          ],
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: Text("OK"),
            onPressed: () async {
              Navigator.pop(context);
              EasyLoading.show(status: tr("closing_steam"));
              await SteamTools.closeSteamClient();
              while (await SteamTools.isSteamRunning() == true) {
                await Future.delayed(const Duration(seconds: 1));
              }
              EasyLoading.dismiss();
              actionFunction();
            },
          ),
          BasicDialogAction(
            title: Text(tr("cancel")),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
