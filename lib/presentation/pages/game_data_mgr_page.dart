import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_miner/data/models/app_storage.dart';
import 'package:game_miner/data/models/game.dart';
import 'package:game_miner/logic/Tools/string_tools.dart';
import 'package:game_miner/logic/blocs/settings_cubit.dart';

import '../../data/models/steam_app.dart';
import '../../logic/blocs/game_data_mgr_cubit.dart';

class GameDataMgrPage extends StatefulWidget {
  const GameDataMgrPage({Key? key}) : super(key: key);

  @override
  State<GameDataMgrPage> createState() => _GameDataMgrPageState();
}

class _GameDataMgrPageState extends State<GameDataMgrPage> {
  late final GameDataMgrCubit _bloc;

  @override
  void initState() {
    _bloc = BlocProvider.of<GameDataMgrCubit>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(tr("Game data manager")),
          /*leading: GestureDetector(
              child: const Icon(Icons.arrow_back),
              onTap: () {
                Navigator.pop(context, _bloc.isGameListDirty);
              }),*/
          actions: [
            IconButton(
              onPressed: () => /*_bloc.save()*/ null,
              icon: Icon(Icons.cleaning_services),
              tooltip: tr("clean"),
            ),
          ],
        ),
        body: BlocBuilder<GameDataMgrCubit, GameDataMgrState>(
          builder: (context, state) {
            if (state is GameDataMgrInitial) {
              return CircularProgressIndicator();
            } else if (state is AppDataStorageLoaded) {
              return ListView(children: [_buildPage(state.steamApps)]);
            } else if (state is AppDataStorageChanged) {
              return ListView(children: [_buildPage(state.steamApps)]);
            }
            else {
              return Container();
            }
          },
        ));
  }

  Widget _buildPage(List<AppDataStorageEntry> appsStorage) {

    return Container(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Id', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Size', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Storage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Steam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Selected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
        rows: appsStorage.map((e){
          //print("Appid:${e.appId}");
          //print("Cache size: ${e.shaderCacheSize} ${e.compatDataSize}");
          return DataRow(cells: [
            DataCell(Text(e.appId)),
            DataCell(Text(e.name)),
            DataCell(Text(StringTools.bytesToStorageUnity(e.size))),
            DataCell(_getStorageType(e)),
            DataCell(_getGameType(e)),
            DataCell(Switch(value:e.selected, onChanged: (bool? value) => _bloc.setSelectedState(e,value!))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _getGameType(AppDataStorageEntry as) {
    Color color = as.gameType == GameType.Steam ? Colors.blue : Colors.red;
    String text = as.gameType == GameType.Steam ? "Yes" : "No";
    return Container(padding:EdgeInsets.fromLTRB(8, 8, 8, 8), decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),color: color
    ), child: Text(text,style:const TextStyle(color: Colors.white)),);
  }

  Widget _getStorageType(AppDataStorageEntry as) {
    Color color = as.storageType == StorageType.CompatData ? Colors.blue : Colors.red;
    String text = as.storageType == StorageType.CompatData ? "CompatData": "ShaderCache";
    return Container(padding:EdgeInsets.fromLTRB(8, 8, 8, 8), decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20), color:color
    ),child: Text(text, style: const TextStyle(color: Colors.white),));
  }
}
