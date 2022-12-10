import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:steamdeck_toolbox/logic/blocs/settings_cubit.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsCubit _bloc;

  @override
  void initState() {
    _bloc = BlocProvider.of<SettingsCubit>(context);
    _bloc.refresh();
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
              onPressed: () => _bloc.save(),
              icon: Icon(Icons.save),
              tooltip: "Save",
            ),
          ],
        ),
        body: Container(
            padding: EdgeInsets.all(8),
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: const [
                              Text(
                                "Search Paths",
                                style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: BlocBuilder<SettingsCubit, SettingsState>(
                            buildWhen: (previous, current) => current is SearchPathsChanged,
                            builder: (context, state) {
                              return state is SearchPathsChanged
                                  ? ListView(
                                      children: (state as SearchPathsChanged)
                                          .searchPaths
                                          .map<ListTile>((e) => ListTile(
                                                title: Text(e),
                                                trailing: IconButton(onPressed: () => _bloc.removePath(e), icon: const Icon(Icons.delete)),
                                              ))
                                          .toList(),
                                    )
                                  : Container();
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 16, 8, 16),
                          child: ElevatedButton(onPressed: () => _bloc.pickPath(), child: Text("Add Path")),
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex:4,
                  child: Card(

                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: const [
                                Text(
                                  "General Options",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                    children: [

                            Expanded(child: Text("Default Proton")),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                  items: _bloc.getAvailableProtonNames().map<DropdownMenuItem<String>>((String e) {
                                    return DropdownMenuItem<String>(value: e, child: Text(e));
                                  }).toList(),
                                  value: _bloc.getProtonNameForCode(_bloc.getSettings().defaultProtonCode),
                                  onChanged: (String? value) => _bloc.getSettings().defaultProtonCode = _bloc.getProtonCodeFromName(value!),
                                  decoration: const InputDecoration()),
                            )
                    ],
                  ),
                          ),
                        ],
                      )),
                )
              ],
            )));
  }
}
