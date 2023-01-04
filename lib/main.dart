import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:game_miner/data/data_providers/compat_tools_data_provider.dart';
import 'package:game_miner/data/repositories/settings_repository.dart';
import 'package:game_miner/data/repositories/steam_user_repository.dart';
import 'package:game_miner/logic/Tools/steam_tools.dart';
import 'package:game_miner/logic/blocs/main_dart_cubit.dart';
import 'package:game_miner/logic/blocs/non_steam_games_cubit.dart';
import 'package:game_miner/logic/blocs/settings_cubit.dart';
import 'package:game_miner/presentation/pages/main_page.dart';
import 'package:game_miner/presentation/pages/non_steam_games_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_miner/presentation/pages/settings_page.dart';
import 'package:game_miner/presentation/pages/splash_page.dart';
import 'package:get_it/get_it.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import 'data/models/settings.dart';
import 'data/models/steam_user.dart';
import 'logic/Tools/service_locator.dart';

late SettingsCubit _settingsCubit;

void main() async {
  await setupServiceLocator();

  // Needs to be called so that we can await for EasyLocalization.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  //Close steam client
  SteamTools.closeSteamClient();

  SteamUserRepository userRepository = await GetIt.I<SteamUserRepository>();
  List<SteamUser> users = await userRepository.loadUsers();
  SteamUser? su = userRepository.getFirstUser();
  if (su == null) throw NotFoundException("No steam user was found in the system. Aborting...");
  GetIt.I<SettingsRepository>().loadSettings(su.id);

  runApp(EasyLocalization(child: MyApp(), supportedLocales: [Locale('en'), Locale('es')], path: 'assets/translations', fallbackLocale: Locale('en')));
  EasyLoading.instance.userInteractions = false;
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
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Settings>(
        stream: GetIt.I<SettingsRepository>().settings.distinct((Settings previous, Settings next) {
          return previous.darkTheme != next.darkTheme;
        }),
        initialData: GetIt.I<SettingsRepository>().getSettings(),
        builder: (context, AsyncSnapshot<Settings> snapshot) {
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            title: 'Game Miner',
            theme: _getTheme(snapshot.data!.darkTheme),
            home: BlocProvider(
              create: (context) => MainPageCubit(),
              child: MainPage(),
            ),
            /*",
              routes: _buildRoutes(),*/
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
  return ThemeData.light().copyWith(
    extensions: <ThemeExtension<CustomTheme>>[
      CustomTheme(gameCardHeaderPath: Colors.grey.shade600, gameCardExeOptionsBg: Colors.grey.shade200, infoBarBgColor: Colors.blueGrey),
    ],
  );
}

_buildRoutes() {
  return {
    '/': (context) => SplashPage(),
    '/main': (context) => BlocProvider(
          create: (context) => NonSteamGamesCubit(),
          child: const NonSteamGamesPage(),
        ),
    // When navigating to the "/second" route, build the SecondScreen widget.
    '/settings': (context) => SettingsPage(),
    '/gameArtworks': (context) => SettingsPage(),
  };
}

ThemeData _getTheme(bool darkTheme) {
  ThemeData ta = _getLightTheme();
  if (darkTheme) {
    ta = _getDarkTheme();
  }

  return ta;
}
