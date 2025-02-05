import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/logic/Tools/file_tools.dart';

import 'package:game_miner/logic/blocs/main_dart_cubit.dart';

import 'package:game_miner/logic/blocs/splash_cubit.dart';

import 'package:game_miner/presentation/pages/main_page.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_miner/presentation/pages/splash_page.dart';
import 'package:game_miner/presentation/widgets/error_widget.dart';
import 'package:get_it/get_it.dart';
import 'package:window_manager/window_manager.dart';

import 'data/models/settings.dart';
import 'logic/Tools/service_locator.dart';

Stream<Settings> stream = GetIt.I<SettingsRepository>().settings.distinct((Settings previous, Settings next) {
  if(next.currentUserId.isEmpty) return false;
  if(previous.currentUserId.isEmpty) return true;
  return previous.getCurrentUserSettings()!.darkTheme != next.getCurrentUserSettings()!.darkTheme;
});


void main() async {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  setupServiceLocator();

  // Needs to be called so that we can await for EasyLocalization.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await EasyLocalization.ensureInitialized();


  windowManager.setMinimumSize(const Size(800, 700));

  runZonedGuarded( () {

    runApp(
        EasyLocalization(child: MyApp(navigatorKey:navigatorKey), supportedLocales: [Locale('en'), Locale('es')], path: 'assets/translations', fallbackLocale: Locale('en')));
    EasyLoading.instance.userInteractions = false;
    EasyLoading.instance.displayDuration = const Duration(seconds: 2);
  }, (error, stackTrace) {
    print('Caught an unhandled exception: $error');
    print('Stack trace: $stackTrace');

    EasyLoading.dismiss();
    navigatorKey.currentState?.push( MaterialPageRoute( builder: (context) => ErrorScreen(error: error.toString(), stackTrace: stackTrace.toString())));
  });
}

class CustomTheme extends ThemeExtension<CustomTheme> {
  final Color? gameCardHeaderPath;
  final Color? gameCardExeOptionsBg;
  final Color? infoBarBgColor;

  const CustomTheme({required this.gameCardHeaderPath, required this.gameCardExeOptionsBg, required this.infoBarBgColor});

  @override
  CustomTheme copyWith({Color? gameCardHeaderPath, Color? gameCardExeOptionBg}) {
    return CustomTheme(
        gameCardHeaderPath: gameCardHeaderPath ?? this.gameCardHeaderPath,
        gameCardExeOptionsBg: gameCardExeOptionsBg ?? this.gameCardExeOptionsBg,
        infoBarBgColor: infoBarBgColor ?? this.infoBarBgColor);
  }

  @override
  CustomTheme lerp(ThemeExtension<CustomTheme>? other, double t) {
    if (other is! CustomTheme) {
      return this;
    }

    return CustomTheme(
        gameCardHeaderPath: Color.lerp(gameCardHeaderPath, other.gameCardHeaderPath, t),
        gameCardExeOptionsBg: Color.lerp(gameCardExeOptionsBg, other.gameCardExeOptionsBg, t),
        infoBarBgColor: Color.lerp(infoBarBgColor, other.gameCardExeOptionsBg, t));
  }
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const MyApp({required this.navigatorKey});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Settings>(
        stream: stream,
        initialData: Settings(), //PLACEHOLDER
        builder: (context, AsyncSnapshot<Settings> snapshot) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            title: 'Game Miner',
            theme: _getTheme(snapshot.data!.getCurrentUserSettings() == null?
            false
                :
            snapshot.data!.getCurrentUserSettings()!.darkTheme),
            initialRoute: '/',
            /*home: BlocProvider(
              create: (context) => MainPageCubit(),
              child: MainPage(),
            ),*/
            routes: _buildRoutes(),
            builder: EasyLoading.init(),
          );
        });
  }
}

ThemeData _getDarkTheme() {
  return ThemeData.dark().copyWith(
    extensions: <ThemeExtension<CustomTheme>>[
      CustomTheme(gameCardHeaderPath: Colors.grey.shade400, gameCardExeOptionsBg: Colors.grey.shade700, infoBarBgColor: Colors.grey.shade600),
    ],
  );
}

ThemeData _getLightTheme() {
  ThemeData data = ThemeData.light().copyWith(
    toggleButtonsTheme: ToggleButtonsThemeData(
        selectedBorderColor: Colors.blue[700], selectedColor: Colors.white, fillColor: Colors.blue[200], color: Colors.blue[700]),
    extensions: <ThemeExtension<CustomTheme>>[
      CustomTheme(gameCardHeaderPath: Colors.grey.shade600, gameCardExeOptionsBg: Colors.grey.shade200, infoBarBgColor: Colors.blueGrey.shade500),
    ],
  );

  return data;
}

_buildRoutes() {
  return {
    '/': (context) => BlocProvider(
          create: (context) => SplashCubit(),
          child: SplashPage(),
        ),
    '/main': (context) => BlocProvider(
          create: (context) => MainPageCubit(MainPageCubit.getSteamUser()),
          child: const MainPage(),
        ),
    // When navigating to the "/second" route, build the SecondScreen widget.
    /*'/settings': (context) => SettingsPage(),
    '/gameArtworks': (context) => SettingsPage(),*/
  };
}

ThemeData _getTheme(bool darkTheme) {
  ThemeData ta = _getLightTheme();
  if (darkTheme) {
    ta = _getDarkTheme();
  }

  return ta;
}
