import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_miner/data/repositories/compat_tools_mapping_repository.dart';
import 'package:game_miner/logic/blocs/game_mgr_cubit.dart';
import 'package:game_miner/logic/blocs/settings_cubit.dart';
import 'package:get_it/get_it.dart';

import '../../data/models/settings.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsCubit _bloc;
  late final Future<void> _blocInitializer;

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
            IconButton(
              onPressed: () => _bloc.save(),
              icon: Icon(Icons.save),
              tooltip: tr("save"),
            ),
          ],
        ),
        body: FutureBuilder(future: _blocInitializer, builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            return _buildSettings();
          }
          else {
            return Container();
          }
        }));
  }

  Widget _buildGeneralOptions(Settings settings) {
    return Expanded(
        flex: 4,
        child: Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
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
                  padding: const EdgeInsets.all(8.0),
                  child: Row(children: [
                    Expanded(child: Text(tr("default_proton"))),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                          items: _bloc.getAvailableCompatToolDisplayNames().map<DropdownMenuItem<String>>((String e) {
                            return DropdownMenuItem<String>(value: e, child: Text(e));
                          }).toList(),
                          value: _bloc.getCompatToolDisplayNameFromCode(_bloc
                              .getSettings()
                              .defaultCompatTool),
                          onChanged: (String? value) =>
                          _bloc
                              .getSettings()
                              .defaultCompatTool = _bloc.getCompatToolCodeFromDisplayName(value!),
                          decoration: const InputDecoration()),
                    )
                  ])),
              Padding(
                padding: const EdgeInsets.all(8.0),
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
              ),
            ],
          ),
        ));
  }

  Widget _buildSettings() {
    return Container(
        padding: EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
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
                    child: BlocBuilder<SettingsCubit, SettingsState>(
                      //buildWhen: (previous, current) => current is SearchPathsChanged || current is SettingsChangedState,
                      builder: (context, state) {
                        late Settings settings;
                        if (state is SearchPathsChanged || state is SettingsChangedState  || state is SettingsLoaded || state is SettingsSaved) {
                          settings = state.settings;
                        } else {
                          return Container();
                        }

                        return Column(
                          children: [
                            Expanded(
                              child: ListView(
                                shrinkWrap: true,
                                children: settings.searchPaths
                                    .map<ListTile>((e) =>
                                    ListTile(
                                      visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                      title: Text(e),
                                      trailing: Tooltip(message: tr("remove_path"),child: IconButton(onPressed: () => _bloc.removePath(e), icon: const Icon(Icons.delete))),
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
                                          decoration:
                                          const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(40))),
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          BlocBuilder<SettingsCubit, SettingsState>(
            //buildWhen: (previous, current) => current is GeneralOptionsChanged || current is SettingsChangedState,
              builder: (context, state) {
                /*if (state is GeneralOptionsChanged) {
                  return _buildGeneralOptions((state).settings);
                } else if (state is SettingsChangedState) {
                  return _buildGeneralOptions((state).settings);
                } else {
                  return Container();
                }*/
                return _buildGeneralOptions(state.settings);
              })
        ]));
  }
}
