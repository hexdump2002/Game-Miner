import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SteamGridNameSearch {
  List<String> types;
  int id;
  String name;
  bool verified;
  int releaseDate;

  SteamGridNameSearch(this.types, this.id, this.name, this.verified, this.releaseDate);
}

class GameArtworksPage extends StatefulWidget {
  const GameArtworksPage({Key? key}) : super(key: key);

  @override
  State<GameArtworksPage> createState() => _GameArtworksPageState();
}

class _GameArtworksPageState extends State<GameArtworksPage> {
  String searchValue = "";
  List<SteamGridNameSearch> results = [];
  List<String> bannerUrls = [];

  TextEditingController textController=TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: null,
        body: _buildUi());
  }

  Widget _buildUi() {
    return Container(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Row(children: [Expanded(child: TextField(controller: textController,enableSuggestions: true, decoration: InputDecoration(hintText: "Type to search"),))]),
        Text(
          "Banners",
          style: TextStyle(fontSize: 20),
        ),
      ]),
    );
  }

  Future<List<String>> _fetchSuggestions(String searchValue) async {
    print("webon");

    String url = "https://www.steamgriddb.com/api/v2/search/autocomplete/$searchValue";
    final res = await http.get(Uri.parse(url), headers: {"Authorization": "Bearer 6905fe1c3f734bcc9c2aefd0414bc98c"});

    List<String> searchResults = [];

    print("Status code: ${res.statusCode}");

    if (res.statusCode == 200) {
      var o = json.decode(res.body);
      assert(o['success'] == true);
      var data = o['data'] as List<dynamic>;
      for (var result in data) {
        //searchResults.add(SteamGridNameSearch(result['types'], result['id'], result['name'], result['verified'], result['release_date']);
        searchResults.add(result['name']);
      }
    }

    return searchResults;
  }

  void _fetchGrids(int gameId) async {
    print("Fetching grids");

    String url = "https://www.steamgriddb.com/api/v2/grids/game/$gameId";

    final res = await http.get(Uri.parse(url), headers: {"Authorization": "Bearer 6905fe1c3f734bcc9c2aefd0414bc98c"});

    print("Status code: ${res.statusCode}");

    if (res.statusCode == 200) {
      var o = json.decode(res.body);
      assert(o['success'] == true);
      var data = o['data'] as List<dynamic>;
      /*for (var result in data) {
        searchResults.add(result['name']);
      }*/
    }
  }

  _getImages() {
    List<Image> images = [];
    for(var bannerUrl in bannerUrls) {
      var image = Image.network(
        bannerUrl,
        fit: BoxFit.fitHeight);
      images.add(image);
    }
  }
}
