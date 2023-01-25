import 'package:flutter/material.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/logic/Tools/debouncer.dart';
import 'package:get_it/get_it.dart';

import '../../../data/models/settings.dart';

typedef SearchFunction(String searchTerm);

class SearchBar extends StatefulWidget {
  late final SearchFunction _searchFunction;
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  late final _initialTerm;
  SearchBar( String initialTerm, SearchFunction searchFunction, {Key? key}) : super(key: key) {
    _searchFunction = searchFunction;
    _initialTerm = initialTerm;
  }

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {

  TextEditingController txtQuery = TextEditingController();
  @override
  void initState() {
    txtQuery.text = widget._initialTerm;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    Settings settings = GetIt.I<SettingsRepository>().getSettings();
    UserSettings userSettings = settings.getCurrentUserSettings()!;

    Color bgColor = userSettings.darkTheme ? Colors.white10 : Colors.blue.shade600;
    Color borderColor = userSettings.darkTheme ? Colors.black26 : Colors.blue.shade700;



    return TextFormField(
      style: const TextStyle(color:Colors.white),
      controller: txtQuery,
      onChanged: (value) => widget._debouncer.run(()=> widget._searchFunction(value)),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: "Search",
        hintStyle: TextStyle(color: Colors.white60),
        enabledBorder: OutlineInputBorder( borderSide: BorderSide(color:borderColor)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        fillColor:bgColor,
        filled: true,
        suffixIcon: IconButton(
          icon: Icon(Icons.search, color: Colors.white60),
          onPressed: () {
            /*txtQuery.text = '';
            widget._searchFunction(txtQuery.text);*/
          },
        ),

      ),
    );
  }
}
