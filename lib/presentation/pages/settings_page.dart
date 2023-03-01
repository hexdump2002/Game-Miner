import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_miner/logic/blocs/settings_cubit.dart';
import 'package:game_miner/presentation/pages/view_image_type_common.dart';

import '../../data/models/settings.dart';

//2234758278 Path: /home/deck/Games/Metroid_Prime_Remastered/usr/bin/metroid_prime.sh
//3979613357 Path: /home/deck/Games/Metroid PrimeRemastered/usr/bin/metroid_prime.sh

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsCubit _bloc;
  late final Future<void> _blocInitializer;

  //This follows same order as ExecutableNameProcesTextProcessingOption in settings
  List<String> processingTextOptions = ["do_nothing", "capitalized", "title_capitalized", "all_uppercase", "all_lowercase"];

  @override
  void initState() {
    _bloc = BlocProvider.of<SettingsCubit>(context);
    _blocInitializer = _bloc.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(tr("settings")),
          /*leading: GestureDetector(
              child: const Icon(Icons.arrow_back),
              onTap: () {
                Navigator.pop(context, _bloc.isGameListDirty);
              }),*/
          actions: [
            BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                return IconButton(
                  onPressed: () => _bloc.save(),
                  icon: Icon(Icons.save, color: state.modified ? Colors.orange:Colors.white),
                  tooltip: tr("save"),
                );
              },
            ),
          ],
        ),
        body: FutureBuilder(
            future: _blocInitializer,
            builder: (ctx, snapshot) {
              if (snapshot.hasData) {
                return _buildSettings();
              } else {
                return Container();
              }
            }));
  }

  Widget _buildGameMgrOptions(UserSettings settings) {
    var padding = EdgeInsets.fromLTRB(8, 8, 8, 0);
    return Container(
      padding: EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Text(
                    tr("game_mgr_options"),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
                padding: padding,
                child: Row(children: [
                  Expanded(child: Text(tr("default_image_view"))),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                        items: viewTypesStr.map<DropdownMenuItem<String>>((String e) {
                          return DropdownMenuItem<String>(value: e, child: Text(e));
                        }).toList(),
                        value: viewTypesStr[settings.defaultGameManagerView],
                        onChanged: (String? value) => _bloc.setDefaultGameManagerView(value!),
                        decoration: const InputDecoration()),
                  )
                ])),
            Padding(
                padding: EdgeInsets.fromLTRB(8, 32, 8, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        // Red border with the width is equal to 5
                        border: Border.all(width: 1, color: Colors.grey.shade600)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          tr("apply_game_processing_config_text"),
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 0, height: 16),
                        Padding(
                            padding: padding,
                            child: Row(
                              children: [
                                Expanded(child: Text(tr("remove_extension"))),
                                Switch(
                                  value: settings.executableNameProcessRemoveExtension,
                                  onChanged: (bool? value) {
                                    _bloc.setExecutableNameProcessRemoveExtension(value!);
                                  },
                                )
                              ],
                            )),
                        Padding(
                            padding: padding,
                            child: Row(children: [
                              Expanded(child: Text(tr("text_processing"))),
                              Expanded(
                                child: DropdownButtonFormField<ExecutableNameProcesTextProcessingOption>(
                                    items: ExecutableNameProcesTextProcessingOption.values
                                        .map<DropdownMenuItem<ExecutableNameProcesTextProcessingOption>>(
                                            (ExecutableNameProcesTextProcessingOption e) {
                                      return DropdownMenuItem<ExecutableNameProcesTextProcessingOption>(
                                          value: e, child: Text(tr(processingTextOptions[e.index])));
                                    }).toList(),
                                    value: settings.executableNameProcessTextProcessingOption,
                                    onChanged: (ExecutableNameProcesTextProcessingOption? value) =>
                                        _bloc.setDefaultNameProcessTextProcessingOption(value!),
                                    decoration: const InputDecoration()),
                              )
                            ]))
                      ],
                    ),
                  )
                ])),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralOptions(UserSettings settings) {
    var padding = EdgeInsets.fromLTRB(8, 8, 8, 0);
    return Container(
      padding: EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Text(
                    tr("general_options"),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
                padding: padding,
                child: Row(children: [
                  Expanded(child: Text(tr("default_proton"))),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                        items: _bloc.getAvailableCompatToolDisplayNames().map<DropdownMenuItem<String>>((String e) {
                          return DropdownMenuItem<String>(value: e, child: Text(e));
                        }).toList(),
                        value: _bloc.getDefaultCompatToolDisplayNameFromCode(),
                        onChanged: (String? value) => _bloc.setDefaultCompatToolFromName(value!),
                        decoration: const InputDecoration()),
                  )
                ])),
            /*Padding(
              padding: padding,
              child: Row(
                children: [
                  Expanded(child: Text(tr("dark_theme"))),
                  Switch(
                      value: settings.darkTheme,
                      onChanged: (value) {
                        _bloc.setDarkThemeState(value);
                      }),
                ],
              ),
            ),*/
            Padding(
              padding: padding,
              child: Row(
                children: [
                  Expanded(child: Text(tr("settings_close_steam_at_startup"))),
                  Switch(
                      value: settings.closeSteamAtStartUp,
                      onChanged: (value) {
                        _bloc.setCloseSteamAtStartUp(value);
                      }),
                ],
              ),
            ),
            if (settings.backupsEnabled)
              Padding(
                padding: padding,
                child: Row(
                  children: [
                    Expanded(child: Text(tr("backup_count"))),
                    Expanded(
                      child: Slider(
                        min: 1.0,
                        max: 10.0,
                        divisions: 10,
                        value: settings.maxBackupsCount.toDouble(),
                        label: '${settings.maxBackupsCount}',
                        onChanged: (value) {
                          setState(() {
                            _bloc.setMaxBackupCount(value);
                          });
                        },
                      ),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildDesktopOptions() {
    var padding = EdgeInsets.fromLTRB(8, 8, 8, 0);
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Text(
                    tr("Desktop App Icon Options"),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8,16, 8,16),
              child: Row(children: [Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(64, 0, 64, 0),
                  child: ElevatedButton(
                      onPressed: () {
                          _bloc.addGameMinerDesktopIcons();
                      }, child: Text(tr('add_settings_desktop_icons')),),
                ),
              ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(64, 0, 64, 0),
                    child: ElevatedButton(
                      onPressed: () {
                         _bloc.removeGameMinerDesktopIcons();
                      }, child: Text(tr('remove_settings_desktop_icons')),),
                  ),
                )]),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSearchPathSettings(UserSettings settings) {
    return Container(
        padding: EdgeInsets.all(8),
        alignment: Alignment.center,
        child: SizedBox(
          height: 250,
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        tr("search_paths"),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: settings.searchPaths
                              .map<ListTile>((e) => ListTile(
                                    visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                    title: Text(e),
                                    trailing: Tooltip(
                                        message: tr("remove_path"),
                                        child: IconButton(onPressed: () => _bloc.removePath(e), icon: const Icon(Icons.delete))),
                                  ))
                              .toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                                    decoration: const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(40))),
                                    child: Text(
                                      "${settings.searchPaths.length} ${tr("folders")}",
                                      style: TextStyle(fontSize: 15, color: Colors.white),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            ElevatedButton(onPressed: () => _bloc.pickPath(), child: Text(tr('add_path'))),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }

  Widget _buildSettings() {
    return Container(
        padding: EdgeInsets.all(8),
        alignment: Alignment.center,
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildSearchPathSettings(state.settings), _buildGameMgrOptions(state.settings), _buildGeneralOptions(state.settings), _buildDesktopOptions()]),
            );
          },
        ));
  }
}
