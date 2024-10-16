import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:expandable/expandable.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/logic/Tools/string_tools.dart';
import 'package:game_miner/logic/blocs/game_mgr_cubit.dart';
import 'package:game_miner/main.dart';
import 'package:game_miner/presentation/pages/view_image_type_common.dart';
import 'package:game_miner/presentation/widgets/searchbar/searchbar_widget.dart' as GameMinerPresentation;
import 'package:get_it/get_it.dart';
import 'package:collection/collection.dart';
import 'package:window_manager/window_manager.dart';
import '../../data/models/advanced_filter.dart';
import '../../data/models/game_executable.dart';
import '../../data/models/game.dart';
import '../../data/models/settings.dart';
import '../../data/repositories/games_repository.dart';
import '../../logic/Tools/game_tools.dart';
import '../../logic/Tools/steam_tools.dart';
import '../widgets/advanced_filter_widget.dart';

enum ContextMenuItem { ShowFolder, RenameGame, DeleteGame, ExportConfig, ImportConfig, DeleteConfig }

//WARNING: THIS CLASS USES A LOT OF NON BEST PRACTICES. FOR EXAMPLE: A CUBIT SHOULD BE PORTABLE AND THIS ONE RECEIVES A LOT OF BUILDCONTEXT
class GameMgrPage extends StatefulWidget {
  GameMgrPage({Key? key}) : super(key: key);

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
    //final stopwatch = Stopwatch()..start();

    const List<String> contextMenuItemIds = <String>['name', 'size', 'status', 'notification', 'date'];

    Widget widgets = Scaffold(
      appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("Game Manager"),
          actions: [
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: GameMinerPresentation.SearchBar(_nsCubit(context).searchText, tr("search"), (term) => _nsCubit(context).searchTermChanged(term))),
            ),
            BlocBuilder<GameMgrCubit, GameMgrBaseState>(
              builder: (context, state) {
                return Row(children: [
                  IconButton(
                    onPressed: () async {
                      _showAdvancedFilterDialog(_nsCubit(context).getAdvancedFilter());
                    },
                    icon: const Icon(Icons.filter_list),
                    tooltip: tr("advanced_filter"),
                  ),
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButton<String>(
                        borderRadius: const BorderRadius.all(Radius.circular(3)),
                        /*hint:const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Filter by"),
                      ),*/
                        value: _nsCubit(context).getSortIndex().toString(),

                        icon: TextButton(
                          child: _nsCubit(context).getSortDirectionIndex() == 0 ? const Icon(Icons.arrow_upward) : const Icon(Icons.arrow_downward),
                          onPressed: () => {_nsCubit(context).swapSortDirecion()},
                        ),
                        //elevation: 16,
                        //style: const TextStyle(color: Colors.deepPurple),
                        underline: Container(
                          height: 0,
                        ),
                        onChanged: (String? value) {
                          int index = int.parse(value!);
                          var nsgpBloc = _nsCubit(context);
                          if (index == 0) {
                            nsgpBloc.sortFilteredByName();
                          } else if (index == 1) {
                            nsgpBloc.sortFilteredBySize();
                          } else if (index == 2) {
                            nsgpBloc.sortFilteredByStatus();
                          } else if (index == 3) {
                            nsgpBloc.sortFilteredByWithErrors();
                          } else if (index == 4) {
                            nsgpBloc.sortFilteredByDate();
                          }
                        },

                        items: contextMenuItemIds.mapIndexed<DropdownMenuItem<String>>((int index, String value) {
                          return DropdownMenuItem<String>(
                            value: index.toString(),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(tr(value)),
                            ),
                          );
                        }).toList(),
                      )),
                  Tooltip(
                      message: tr("multi_selection_mode"),
                      child:
                          Switch(value: _nsCubit(context).getMultiSelectionMode(), onChanged: (value) => _nsCubit(context).swapMultiSelectionMode())),
                  IconButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _nsCubit(context).trySave();
                      } else {
                        print("There are errors in the form. Fix them!");
                      }
                    },
                    icon:  Icon(Icons.save, color: _nsCubit(context).modified ? Colors.orange : Colors.white),
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
                    icon: const Icon(Icons.refresh),
                    tooltip: tr("refresh"),
                  ),
                ]);
              },
            )
          ]),
      body: BlocConsumer<GameMgrCubit, GameMgrBaseState>(
        listener: (context, state) {
          if (state is DeleteGameClicked) {
            _deleteGame(context, state.game);
          } else if (state is SteamDetected) {
            showSteamActiveWhenSaving(context, state.okAction);
          } else if (state is RenameGameClicked) {
            _nsCubit(context).renameGame(state.game, state.newName);
          } else if (state is DeleteSelectedClicked) {
            _deleteSelectedGames(context, state);
          }
        },
        buildWhen: (previous, current) {
          return current is! DeleteGameClicked && current is! SteamDetected && current is! RenameGameClicked && current is! DeleteSelectedClicked;
        },
        builder: (context, state) {
          return Stack(
            children: [
              ExpandableTheme(
                  data: const ExpandableThemeData(hasIcon: false),
                  child: Container(
                      alignment: Alignment.center,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildDataScreen(context, state),
                      ))),
              if (state is BaseDataChanged && state.multiSelectionMode)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: _buildMultiSelectionPanel(state)
                  ),
                ),
            ],
          );
        },
      ),
    );

    //stopwatch.stop();
    //print('[UI] Time taken to execute method: ${stopwatch.elapsed}');

    return widgets;
  }

  Widget _buildMultiSelectionPanel(BaseDataChanged state) {
    return Container(
      color: Colors.grey.shade700,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: () => {_nsCubit(context).selectAll()},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                child: Text(tr("select_all"))),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: () => {_nsCubit(context).selectNone()},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                child: Text(tr("select_none"))),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: () => {_showChangeCompatToolDialog(state)},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                child: Text(tr("change_compattool"))),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: () => _nsCubit(context).tryDeleteSelected(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                child: Text(tr("delete_selected"))),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: () => _importSelectedGamesConfig(state.games),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                child: Text(tr("import_selected"))),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: () => _exportSelectedGames(state.games),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                child: Text(tr("export_selected"))),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: () => _deleteSelectedGameConfigs(state.games),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                child: Text(tr("delete_configs"))),
          ),
        ],
      ),
    );
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
    } else if (nsgState is FilterChanged) {
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

  Widget _buildContextMenu(GameView gameView) {
    return PopupMenuButton<ContextMenuItem>(
      initialValue: null,
      enabled: !gameView.game.isExternal,
      // Callback that sets the selected popup menu item.
      onSelected: (ContextMenuItem item) {},
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ContextMenuItem>>[
        PopupMenuItem<ContextMenuItem>(
          value: ContextMenuItem.ShowFolder,
          child: Text(tr("open_folder")),
          onTap: () => _nsCubit(context).openFolder(gameView.game),
        ),
        PopupMenuItem<ContextMenuItem>(
          value: ContextMenuItem.RenameGame,
          child: Text(tr("rename_game")),
          onTap: () => Future.microtask(() => _renameGame(context, gameView.game)), //_nsCubit(context).tryRenameGame(context, gameView.game),
        ),
        PopupMenuItem<ContextMenuItem>(
            value: ContextMenuItem.DeleteGame, child: Text(tr("delete_game")), onTap: () => _nsCubit(context).tryDeleteGame(gameView.game)),
        PopupMenuItem<ContextMenuItem>(
          value: ContextMenuItem.ExportConfig,
          child: Text(tr("export_config")),
          onTap: () => _nsCubit(context).exportGame(gameView),
        ),
        PopupMenuItem<ContextMenuItem>(
            value: ContextMenuItem.ImportConfig, child: Text(tr("import_game_config")), onTap: () => _importGameConfig(gameView)),
        PopupMenuItem<ContextMenuItem>(
          value: ContextMenuItem.DeleteConfig,
          child: Text(tr("delete_game_config")),
          onTap: () => _deleteGameConfig(gameView),
        ),
      ],
    );
  }

  Widget _createGameCards(BuildContext context, BaseDataChanged state, CustomTheme themeExtension) {
    var gamesView = state.games;
    return Form(
        key: _formKey,
        child: ListView.builder(
            itemCount: gamesView.length,
            itemBuilder: (BuildContext context, int index) {
              var gameView = gamesView[index];
              return getGamesView(context, gameView, index, state, themeExtension);
            }));
  }

  Widget _createGameCardImage(BuildContext context, GameView gameView, int index, CustomTheme themeExtension, BaseDataChanged state) {
    return Container(
      color: const Color.fromARGB(255, 80, 80, 80),
      padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: ExpandablePanel(
        controller: ExpandableController(initialExpanded: gameView.isExpanded)..addListener(() => _nsCubit(context).swapExpansionStateForItem(index)),
        header: Row(
          children: [
            if (state.multiSelectionMode)
              Column(
                children: [
                  Checkbox(value: gameView.selected, onChanged: (value) => {_nsCubit(context).swapGameViewSelected(gameView)}),
                ],
              ),
            _getGameSteamImage(context, gameView, state.gameExecutableImageType, state.multiSelectionMode),
            Expanded(
              child: ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(gameView.game.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.left)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 24, 0),
                              child: gameView.game.isExternal ? null : Text(StringTools.bytesToStorageUnity(gameView.game.gameSize)),
                            ),
                            Padding(padding: const EdgeInsets.fromLTRB(0, 0, 24, 0), child: _getDateText(gameView))
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                          child: _getExeCurrentStateIcon(GameTools.getGameStatus(gameView.game)),
                        ),
                        _getErrorsOrModifiedIcon(gameView),
                        _buildContextMenu(gameView)
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
            ),
          ],
        ),
        expanded: Container(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black12),
            child: _buildGameTile(context, themeExtension, gameView, state.availableProntonNames)),
        collapsed: Container(),
      ),
    );
  }

  //region Full Baner
  Widget _createGameCardFullBannerSize(GameView gameView, int index, CustomTheme themeExtension, BaseDataChanged state) {
    return ExpandablePanel(
      controller: ExpandableController(initialExpanded: gameView.isExpanded)..addListener(() => _nsCubit(context).swapExpansionStateForItem(index)),
      header: Stack(
        children: [
          _getGameSteamImage(context, gameView, GameExecutableImageType.Banner, state.multiSelectionMode),
          ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (state.multiSelectionMode)
                      Checkbox(value: gameView.selected, onChanged: (value) => {_nsCubit(context).swapGameViewSelected(gameView)}),
                    Container(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black.withAlpha(180)),
                        child: Text(gameView.game.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.left)),
                    Expanded(child: Container()),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 18, 0),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black.withAlpha(180)),
                      child: Row(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 24, 0),
                          child: gameView.game.isExternal ? null : Text(StringTools.bytesToStorageUnity(gameView.game.gameSize)),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                          child: _getExeCurrentStateIcon(GameTools.getGameStatus(gameView.game)),
                        ),
                        _getErrorsOrModifiedIcon(gameView),
                        _buildContextMenu(gameView)
                      ]),
                    )
                  ],
                ),
                if (gameView.isExpanded)
                  Column(
                    children: [
                      const SizedBox(
                        height: 4,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.black.withAlpha(180),
                        child: Text(
                          "${gameView.game.path}",
                          textAlign: TextAlign.left,
                          style: TextStyle(color: themeExtension.gameCardHeaderPath, fontSize: 13),
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
        ],
      ),
      expanded: Container(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black.withAlpha(100)),
          child: _buildGameTile(context, themeExtension, gameView, state.availableProntonNames)),
      collapsed: Container(),
    );
  }

  Widget _createGameCardHalfBannerSize(GameView gameView, int index, CustomTheme themeExtension, BaseDataChanged state) {
    return Container(
      color: Color.fromARGB(255, 80, 80, 80),
      alignment: Alignment.center,
      child: ExpandablePanel(
        controller: ExpandableController(initialExpanded: gameView.isExpanded)..addListener(() => _nsCubit(context).swapExpansionStateForItem(index)),
        header: ListTile(
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (state.multiSelectionMode)
                Checkbox(value: gameView.selected, onChanged: (value) => {_nsCubit(context).swapGameViewSelected(gameView)}),
              _getGameSteamImage(context, gameView, GameExecutableImageType.HalfBanner, state.multiSelectionMode),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _getExeCurrentStateIcon(GameTools.getGameStatus(gameView.game)),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 0, 0, 0),
                            child: Text(gameView.game.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.left),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 4, 0, 0),
                        child: _getDateText(gameView),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 16, 0, 0),
                        child: gameView.game.isExternal ? null : Text(StringTools.bytesToStorageUnity(gameView.game.gameSize)),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(16.0, 0, 0, 0),child: _getErrorsOrModifiedIcon(gameView)),
              _buildContextMenu(gameView)
            ],
          ),
        ),
        expanded: Container(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black.withAlpha(100)),
            child: _buildGameTile(context, themeExtension, gameView, state.availableProntonNames)),
        collapsed: Container(),
      ),
    );
  }

  //endregion

  Widget _buildGameTile(BuildContext context, CustomTheme themeExtension, GameView gv, List<String> availableProtons) {
    List<Widget> gameItems = [];

    List<GameExecutable> gameExePaths = gv.game.exeFileEntries;

    if (gv.game.exeFileEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        child: Container(
            decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.all(Radius.circular(40))),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(tr("folder_no_contains_exe"), style: const TextStyle(color: Colors.white, fontSize: 20), textAlign: TextAlign.center)),
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
                    child: Icon(Icons.warning, color: error ? Colors.red : const Color(0)),
                    message: error ? _buildErrorTextForGameExecutable(uge) : ""),
              ),
              Expanded(
                child: Text(uge.relativeExePath, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.left),
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

    String baseKey = uge.appId.toString();
    GameMgrCubit nsgc = _nsCubit(context);
    return Container(
      color: themeExtension.gameCardExeOptionsBg,
      margin: const EdgeInsets.fromLTRB(32, 8, 128, 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  _nsCubit(context).notifyDataChanged();
                }
              },
              child: TextFormField(
                key: UniqueKey(),
                initialValue: uge.name,
                decoration: InputDecoration(labelText: tr("name"), errorStyle: TextStyle(color: Colors.redAccent.shade100)),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (value) {
                  uge.name = value!;
                  gv.modified = true;
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
            ),
            Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  _nsCubit(context).notifyDataChanged();
                }
              },
              child: TextFormField(
                key: UniqueKey(),
                initialValue: uge.launchOptions,
                decoration: InputDecoration(labelText: tr("launch_options")),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (value) {
                  uge.launchOptions = value!;
                  gv.modified = true;
                  //_nsCubit(context).notifyDataChanged();
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
            ),
            DropdownButtonFormField<String>(
                //key: ObjectKey("${baseKey}_2"),
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
    String tooltip = "";

    if (gameAddedStatus == GameStatus.FullyAdded) {
      color = Colors.green;
    } else if (gameAddedStatus == GameStatus.Added) {
      color = Colors.orange;
    } else if (gameAddedStatus == GameStatus.NonAdded) {
      color = Colors.red;
    } else {
      color = Colors.blue.shade200;
    }

    /*Widget c = Stack(children: [Container(height: 15, width: 15, color: color), Positioned.fill(
      child: Align(
          alignment: Alignment.center,
          child: Container(height: 6, width: 6, color: Colors.white))
      )],
    );*/

    Widget c = Container(height: 15, width: 15, color: color);

    return c;
  }

  Widget _buildInfoBar(BuildContext context, BaseDataChanged state, CustomTheme themeExtension) {
    return Container(
        color: themeExtension.infoBarBgColor,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "${state.notAddedGamesCount + state.addedGamesCount + state.fullyAddedGamesCount} " + tr("discovered_games"),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              child: TextButton(
                  onPressed: () => _nsCubit(context).cycleViewType(),
                  child: Container(
                      padding: const EdgeInsets.all(5),
                      color: Colors.black38,
                      child: Text(
                        viewTypesStr[state.gameExecutableImageType.index],
                        style: const TextStyle(color: Colors.white),
                      ))),
            ),
            Tooltip(
              message: tr("game_status_red_tooltip"),
              child: Row(
                children: [
                  Container(height: 15, width: 15, color: Colors.red),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: Text(
                      state.notAddedGamesCount.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: tr("game_status_orange_tooltip"),
              child: Row(
                children: [
                  Container(height: 15, width: 15, color: Colors.orange),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: Text(
                      state.addedGamesCount.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: tr("game_status_green_tooltip"),
              child: Row(
                children: [
                  Container(height: 15, width: 15, color: Colors.green),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: Text(
                      state.fullyAddedGamesCount.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: tr("game_status_blue_tooltip"),
              child: Row(
                children: [
                  Container(height: 15, width: 15, color: Colors.blue.shade200),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                      child: Text(
                        state.addedExternal.toString(),
                        style: const TextStyle(color: Colors.white),
                      )),
                ],
              ),
            ),
            Tooltip(
              message: tr("free_sd_card_space"),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8, 0),
                child: Row(
                  children: [
                    const Icon(Icons.sd_card),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                      child: Text(
                        "${StringTools.bytesToStorageUnity(state.freeSDCardSpace)} / ${StringTools.bytesToStorageUnity(state.totalSDCardSpace)}",
                        style: const TextStyle(color: Colors.white),
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
                    const Icon(Icons.storage),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                      child: Text(
                        "${StringTools.bytesToStorageUnity(state.freeSSDSpace)} / ${StringTools.bytesToStorageUnity(state.totalSSDSpace)}",
                        style: const TextStyle(color: Colors.white),
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

  void _deleteSelectedGames(BuildContext context, DeleteSelectedClicked state) {
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
                  TextSpan(text: tr("going_to")),
                  TextSpan(text: tr("delete_capitals"), style: const TextStyle(color: Colors.redAccent)),
                  TextSpan(text: tr("delete_selected_game_dialog_text", args: [state.selectedGameCount.toString()])),
                  TextSpan(text: tr("warning_action_undone"), style: const TextStyle(color: Colors.red, fontSize: 18, height: 2))
                ])),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                          child: CheckboxListTile(
                              dense: true,
                              title: const Text(
                                "CompatData",
                                style: TextStyle(fontSize: 14),
                              ),
                              value: deleteCompatData,
                              onChanged: (value) => setState(() => deleteCompatData = value!))),
                      Expanded(
                          child: CheckboxListTile(
                              dense: true,
                              title: const Text("ShaderData", style: TextStyle(fontSize: 14)),
                              value: deleteShaderData,
                              onChanged: (value) => setState(() => deleteShaderData = value!))),
                    ]),
                    Row(
                      children: [
                        Expanded(
                            child: CheckboxListTile(
                                dense: true,
                                title: const Text("Images", style: TextStyle(fontSize: 14)),
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
              title: const Text("OK"),
              onPressed: () async {
                nsCubit.deleteSelectedGames(deleteImages, deleteCompatData, deleteShaderData);
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
                  TextSpan(text: tr("going_to")),
                  TextSpan(text: tr("delete_capitals"), style: const TextStyle(color: Colors.redAccent)),
                  TextSpan(text: tr("delete_game_dialog_text", args: ['${game.name}'])),
                  TextSpan(text: tr("warning_action_undone"), style: const TextStyle(color: Colors.red, fontSize: 18, height: 2))
                ])),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                          child: CheckboxListTile(
                              dense: true,
                              title: const Text(
                                "CompatData",
                                style: TextStyle(fontSize: 14),
                              ),
                              value: deleteCompatData,
                              onChanged: (value) => setState(() => deleteCompatData = value!))),
                      Expanded(
                          child: CheckboxListTile(
                              dense: true,
                              title: const Text("ShaderData", style: TextStyle(fontSize: 14)),
                              value: deleteShaderData,
                              onChanged: (value) => setState(() => deleteShaderData = value!))),
                    ]),
                    Row(
                      children: [
                        Expanded(
                            child: CheckboxListTile(
                                dense: true,
                                title: const Text("Images", style: TextStyle(fontSize: 14)),
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
              title: const Text("OK"),
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

  void _exportSelectedGames(List<GameView> games) async {
    if (games.where((o) => o.selected).isEmpty) {
      EasyLoading.showToast(tr("no_action_no_games_selected"));
      return;
    }

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
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(tr("export_selected_games_dialog_text")),
          ]),
          actions: <Widget>[
            BasicDialogAction(
              title: const Text("OK"),
              onPressed: () {
                nsCubit.exportSelectedGames();
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

  void _importSelectedGamesConfig(List<GameView> games) async {
    if (games.where((o) => o.selected).isEmpty) {
      EasyLoading.showToast(tr("no_action_no_games_selected"));
      return;
    }

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
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(tr("import_games_config_dialog_text")),
          ]),
          actions: <Widget>[
            BasicDialogAction(
              title: const Text("OK"),
              onPressed: () {
                nsCubit.importSelectedGamesConfig();
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

  //Import game
  void _importGameConfig(GameView gv) async {
    var nsCubit = _nsCubit(context);
    Future.microtask(() => showPlatformDialog(
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
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(tr("import_config_dialog_text")),
              ]),
              actions: <Widget>[
                BasicDialogAction(
                  title: const Text("OK"),
                  onPressed: () {
                    nsCubit.importGameConfig(gv);
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
        ));
  }

  void _deleteSelectedGameConfigs(List<GameView> games) {
    if (games.where((o) => o.selected).isEmpty) {
      EasyLoading.showToast(tr("no_action_no_games_selected"));
      return;
    }

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
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(tr("delete_games_config_dialog_text")),
          ]),
          actions: <Widget>[
            BasicDialogAction(
              title: const Text("OK"),
              onPressed: () {
                nsCubit.deleteSelectedGameConfigs();
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

  void _deleteGameConfig(GameView gv) {
    var nsCubit = _nsCubit(context);
    Future.microtask(() => showPlatformDialog(
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
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(tr("delete_game_config_dialog_text", args: [gv.game.name])),
              ]),
              actions: <Widget>[
                BasicDialogAction(
                  title: const Text("OK"),
                  onPressed: () {
                    nsCubit.deleteGameConfig(gv);
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
        ));
  }

  void _renameGame(BuildContext context, Game game) {
    GameMgrCubit cubit = _nsCubit(context);
    _genericTextController.text = game.name;

    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text(tr("rename_game")),
        content: Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _genericTextController,
          ),
        ),
        actions: <Widget>[
          BasicDialogAction(
              title: const Text("OK"),
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
                                    title: const Text("OK"),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    })
                              ]));
                  return;
                }
                cubit.tryRenameGame(context, game, _genericTextController.text);
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
            title: const Text("OK"),
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

  Widget _getGameSteamImage(BuildContext context, GameView gv, GameExecutableImageType imageType, bool multiSelectionMode) {
    //50 x 100 (Pequeño) 0 padding
    //75 x 125 (Medio)    "
    //100x150 (Grande)    "
    //48x48     padding 4 (arriba y abajo)

    if (imageType == GameExecutableImageType.None) {
      return multiSelectionMode && gv.hasConfig ? Container(width: 3, height: 16, color: Colors.redAccent) : Container();
    } else if (imageType == GameExecutableImageType.Icon) {
      return Row(children: [
        if (multiSelectionMode && gv.hasConfig) Container(width: 3, height: 48, color: Colors.redAccent),
        gv.gameImagePath == null
            ? Container(color: Colors.grey.shade800, width: 48, height: 48, child: const Icon(Icons.question_mark))
            : Image.file(
                File(gv.gameImagePath!),
                width: 48,
                height: 48,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
      ]);
    } else if (imageType == GameExecutableImageType.CoverSmall) {
      return Row(children: [
        if (multiSelectionMode && gv.hasConfig) Container(width: 3, height: 75, color: Colors.redAccent),
        gv.gameImagePath == null
            ? Container(color: Colors.grey.shade800, width: 50, height: 75, child: const Icon(Icons.question_mark))
            : Image.file(File(gv.gameImagePath!), width: 50, height: 75, fit: BoxFit.fill, filterQuality: FilterQuality.medium)
      ]);
    } else if (imageType == GameExecutableImageType.CoverMedium) {
      return Row(children: [
        if (multiSelectionMode && gv.hasConfig) Container(width: 3, height: 125, color: Colors.redAccent),
        gv.gameImagePath == null
            ? Container(color: Colors.grey.shade800, width: 75, height: 125, child: const Icon(Icons.question_mark))
            : Image.file(File(gv.gameImagePath!), width: 75, height: 125, fit: BoxFit.fill, filterQuality: FilterQuality.medium)
      ]);
    } else if (imageType == GameExecutableImageType.CoverBig) {
      return Row(children: [
        if (multiSelectionMode && gv.hasConfig) Container(width: 3, height: 150, color: Colors.redAccent),
        gv.gameImagePath == null
            ? Container(color: Colors.grey.shade800, width: 100, height: 150, child: const Icon(Icons.question_mark))
            : Image.file(File(gv.gameImagePath!), width: 100, height: 150, fit: BoxFit.fill, filterQuality: FilterQuality.medium)
      ]);
    } else if (imageType == GameExecutableImageType.Banner) {
      double width = MediaQuery.of(context).size.width - 90;
      return Row(children: [
        if (multiSelectionMode && gv.hasConfig) Container(width: 3, height: 150, color: Colors.redAccent),
        gv.gameImagePath == null
            ? Expanded(
                child: Container(
                    color: Colors.grey.shade800,
                    height: 150,
                    child: const Icon(
                      Icons.question_mark,
                      size: 80,
                    )))
            : Image.file(File(gv.gameImagePath!), width: width, height: 150, fit: BoxFit.fitWidth, filterQuality: FilterQuality.medium)
      ]);
    } else if (imageType == GameExecutableImageType.HalfBanner) {
      //print("${gv.game.name} ${gv.gameImagePath}");
      return Row(children: [
        if (multiSelectionMode && gv.hasConfig) Container(width: 3, height: 150, color: Colors.redAccent),
        gv.gameImagePath == null
            ? Container(
                color: Colors.grey.shade800,
                width: 465,
                height: 150,
                child: const Icon(
                  Icons.question_mark,
                  size: 80,
                ))
            : Image.file(File(gv.gameImagePath!), width: 465, height: 150, fit: BoxFit.fitWidth, filterQuality: FilterQuality.medium)
      ]);
    } else {
      return Container(child: const Text("Error with image type"));
    }
  }

  Widget getGamesView(BuildContext context, GameView gameView, int index, BaseDataChanged state, CustomTheme themeExtension) {
    if (state.gameExecutableImageType == GameExecutableImageType.Banner) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: _createGameCardFullBannerSize(gameView, index, themeExtension, state),
      );
    } else if (state.gameExecutableImageType == GameExecutableImageType.HalfBanner) {
      return Padding(padding: const EdgeInsets.fromLTRB(8, 8, 8, 8), child: _createGameCardHalfBannerSize(gameView, index, themeExtension, state));
    } else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: _createGameCardImage(context, gameView, index, themeExtension, state),
      );
    }
  }

  Widget? _getDateText(GameView gameView) {
    if (gameView.game.isExternal) return null;

    try {
      String formatedDate = DateFormat('dd-MM-yyyy').format(gameView.game.creationDate);
      return Text("Updated on $formatedDate", style: TextStyle(fontSize: 12, color: Colors.grey.shade500));
    } catch (ex) {
      print(ex);
      return null;
    }
  }

  void _showAdvancedFilterDialog(AdvancedFilter advancedFilter) {
    GameMgrCubit cubit = _nsCubit(context);

    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(

        content: AdvancedFilterWidget(advancedFilter: advancedFilter, searchPaths: [..._userSettings.searchPaths]),
        actions: <Widget>[
          BasicDialogAction(
            title: const Text("OK"),
            onPressed: () async {
              Navigator.pop(context);
              cubit.setAdvancedFilter(advancedFilter);
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

  //Hay que forzar un repintado por si hay algun juego desplegado que se vea el cambio ahi tmb
  //TOO Lazy to do this in the correct way. Just make it work.
  void _showChangeCompatToolDialog(BaseDataChanged state) {
    GameMgrCubit cubit = _nsCubit(context);

    if (state.games.where((element) => element.selected).isEmpty) {
      EasyLoading.showToast(tr("no_action_no_games_selected"));
      return;
    }

    String compatToolName = state.availableProntonNames[0];
    
    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text(tr('change_compattool_dialog_title')),
        content: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: 700,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 32,),
                Text(tr("change_compattool_dialog_text")),
                SizedBox(height: 16,),
                Row(
                  children: [
                    Expanded(child: Text(tr("Compat Tool"))),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                          items: state.availableProntonNames.map<DropdownMenuItem<String>>((String e) {
                            return DropdownMenuItem<String>(value: e, child: Text(e));
                          }).toList(),
                          value: state.availableProntonNames[0], //At least one must exist
                          onChanged: (String? value) => compatToolName = value!,
                          decoration: const InputDecoration()),
                    ),
                  ],
                )

              ],
            ),
          ),
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: const Text("OK"),
            onPressed: () async {
              Navigator.pop(context);
              cubit.changeSelectedGamesCompatTool(compatToolName);
              EasyLoading.showToast(tr("all_selected_games_compattool_changed", args:[compatToolName]));
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
