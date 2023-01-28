import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:game_miner/logic/blocs/main_dart_cubit.dart';
import 'package:game_miner/logic/blocs/splash_cubit.dart';
import 'package:game_miner/presentation/widgets/steam_user_selector_widget.dart';

import '../../data/models/steam_config.dart';

class SplashPage extends StatefulWidget {
  SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>  with SingleTickerProviderStateMixin{
  late SplashCubit _bloc;
  late AnimationController opacityAnimController;
  late Animation<double> opacityAnimation;

  late AnimationController scaleAnimController;
  late Animation<double> scaleAnimation;
  late CurvedAnimation scaleCurveAnimation;
  
  @override
  void initState() {
    _bloc=BlocProvider.of<SplashCubit>(context)..initDependencies();
    opacityAnimController =AnimationController(vsync: this, duration: const Duration(seconds:3));
    opacityAnimation = Tween<double>(begin: 0,end:1).animate(opacityAnimController)..addListener(() {setState(() {
    });});
    opacityAnimController.forward();
    //Future.delayed(const Duration(seconds: 4), ()=> opacityAnimController.forward());

    /*scaleAnimController =AnimationController(vsync: this, duration: const Duration(seconds:1));
    scaleCurveAnimation = CurvedAnimation(parent: scaleAnimController, curve: Curves.bounceInOut);
    scaleAnimation = Tween<double>(begin: 0,end:1).animate(
      scaleCurveAnimation
    )..addListener(() {setState(() {
    });});

    scaleAnimController.forward();*/
  }

  @override
  Widget build(BuildContext context) {
    //widget._player.setSourceAsset("audio/game-miner.mp3");


    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: null,
        body: BlocListener<SplashCubit, SplashState>(
          //listenWhen: (previous, current) => current is ShowSteamUsersDialog || current is UserAutoLogged || current is SplashAllWorkDone,
          listener: (context, state) {
            if(state is ShowSteamUsersDialog) {
              ShowSteamUsersDialog sde = state as ShowSteamUsersDialog;
              showSteamUsersDialog(context, state.caption);
            }
            else if(state is UserAutoLogged)
            {
              _bloc.finalizeSetup(context, state.user);
            }
            else if(state is SplashWorkDone) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, "/main");
              });
            }
          },
          child: Container(
              width: width,
              height: height,
              color: const Color.fromARGB(255, 38, 44,54),
              child: Column(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: opacityAnimation.value,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/logo.png'),
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                "Developed by HexDump",
                                style: TextStyle(color: Colors.white, fontSize: 25),
                              ),
                            ),
                            Text("Main tester: excitecube", style: TextStyle(color: Colors.grey.shade400, fontSize: 20)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0,0,0,16),
                    child: Row(
                      children: [
                        Expanded(child: Container()),
                        Container(
                          decoration: BoxDecoration(color:Colors.blueGrey.shade800, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), topLeft: Radius.circular(15))),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              Text(
                                "Initializing...  ",
                                style: TextStyle(fontSize: 20, color:Colors.blueGrey.shade300),
                              ),
                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color:Colors.white70))
                            ]),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              )),
        ));
  }

  void showSteamUsersDialog(BuildContext context, String caption) {
    showPlatformDialog(
      context: context,
      builder: (context) => BasicDialogAlert(
        title: Text(caption),
        content: SteamUserSelector(userSelectedCallback: (context, steamUser) {
          Navigator.pop(context);
          _bloc.finalizeSetup(context,steamUser);
        },)
        ),

      );
  }

  @override
  void dispose() {
    opacityAnimController.dispose();

    super.dispose();
  }

}
