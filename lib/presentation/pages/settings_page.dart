import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({Key? key}) : super(key: key);

  final List<String> paths = ["/home/hexdump/Download/Games", "/run/media","/home/hexdump/Download/Games", "/run/media","/home/hexdump/Download/Games", "/run/media","/home/hexdump/Download/Games", "/run/media"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text("Non Steam Games Manager"),
        ),
        body: Container(
            padding: EdgeInsets.all(8),
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Text("Search Paths",style: TextStyle(fontSize: 30),),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(children: paths.map((e) =>
                              ListTile(
                                title: Text(e),
                                trailing: IconButton(onPressed: () => print("deleted!"), icon: const Icon(Icons.delete)),
                              )).toList(),),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0,16,8,16),
                          child: ElevatedButton(onPressed: ()=>null, child: Text("Add Path")),
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(child: Container())
                
              ],
            ))
    );

  }
}
