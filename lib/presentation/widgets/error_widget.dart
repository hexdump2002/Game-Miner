import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String error;
  final String stackTrace;

  ErrorScreen({required this.error, required this.stackTrace});

  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Error'),),
      body: Center(
        child: Column(
          children: [
            Text("An error has ocurred. Please copy the text or take a screenshot and fill a bug at https://github.com/hexdump2002/game-miner-public/issues", style: TextStyle(fontSize: 18.0)),
            SizedBox(height: 20),
            Text(error, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            Text(stackTrace, style: TextStyle(color: Colors.limeAccent))
          ]
      )));
    }
  }