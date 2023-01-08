import 'package:flutter/material.dart';
import 'package:game_miner/logic/Tools/debouncer.dart';

typedef SearchFunction(String searchTerm);

class SearchBar extends StatefulWidget {
  late final SearchFunction _searchFunction;
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  SearchBar( SearchFunction searchFunction, {Key? key}) : super(key: key) {
    _searchFunction = searchFunction;
  }

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {

  @override
  Widget build(BuildContext context) {

    TextEditingController txtQuery = TextEditingController();

    return TextFormField(
      style: const TextStyle(color:Colors.white),
      controller: txtQuery,
      onChanged: (value) => widget._debouncer.run(()=> widget._searchFunction(value)),
      decoration: InputDecoration(
        hintText: "Search",
        hintStyle: TextStyle(color: Colors.white60),
        border: OutlineInputBorder( borderSide: BorderSide(color:Colors.green)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        fillColor:Colors.blue.shade700,
        filled: true,
        suffixIcon: IconButton(
          icon: Icon(Icons.search, color: Colors.white60),
          onPressed: () {
            txtQuery.text = '';
            widget._searchFunction(txtQuery.text);
          },
        ),

      ),
    );
  }
}
