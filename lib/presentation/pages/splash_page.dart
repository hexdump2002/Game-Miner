import 'dart:async';

import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    Timer(Duration(seconds: 3), (){
      Navigator.pushReplacementNamed(context, "/main");
    });
  }
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: null,
        body: Container(
            width: width,
            height: height,
            color: Color.fromARGB(255, 0x34, 02, 0x52),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png'),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Developed by HexDump", style: TextStyle(color:Colors.white, fontSize: 25),),
                  ),
                  Text("Main tester: excitecube", style: TextStyle(color:Colors.grey.shade400, fontSize: 20))

                ],
              ),
            )));
  }
}
