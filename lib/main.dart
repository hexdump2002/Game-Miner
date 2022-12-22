import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:steamdeck_toolbox/logic/Tools/steam_tools.dart';
import 'package:steamdeck_toolbox/logic/blocs/non_steam_games_cubit.dart';
import 'package:steamdeck_toolbox/logic/blocs/settings_cubit.dart';
import 'package:steamdeck_toolbox/presentation/pages/game_artworks_page.dart';
import 'package:steamdeck_toolbox/presentation/pages/non_steam_games_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:steamdeck_toolbox/presentation/pages/settings_page.dart';
import 'package:steamdeck_toolbox/presentation/pages/splash_page.dart';

late SettingsCubit _settingsCubit;

void main() async {
  //Close steam client
  //SteamTools.closeSteamClient();

  _settingsCubit = SettingsCubit();
  await _settingsCubit.initialize();

  // ...
  // Needs to be called so that we can await for EasyLocalization.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

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
    return BlocProvider(
      create: (context) => _settingsCubit,
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (previous, current) => current is SettingsSaved || current is SettingsLoaded,
        builder: (context, state) {
          ThemeData ta = _getLightTheme();
          if(state is SettingsSaved && state.settings.darkTheme) {
            ta= _getDarkTheme();
          }
          else if(state is SettingsLoaded && state.settings.darkTheme) {
            ta = _getDarkTheme();
          }
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            title: 'Flutter Demo',
            theme: ta,
            initialRoute: "/",
            routes: _buildRoutes(),
            builder: EasyLoading.init(),
          );
        },
      ),
    );
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
      '/': (context) => /*GameArtworksPage()*/SplashPage(),
      '/main': (context) => BlocProvider(
            create: (context) => NonSteamGamesCubit(_settingsCubit),
            child: const NonSteamGamesPage(),
          ),
      // When navigating to the "/second" route, build the SecondScreen widget.
      '/settings': (context) => SettingsPage(),
      '/gameArtworks': (context) => SettingsPage(),
    };
  }
}
