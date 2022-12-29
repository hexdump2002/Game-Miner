import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_miner/logic/blocs/main_dart_cubit.dart';
import 'package:game_miner/logic/blocs/non_steam_games_cubit.dart';
import 'package:game_miner/logic/blocs/settings_cubit.dart';
import 'package:game_miner/presentation/pages/settings_page.dart';

import 'non_steam_games_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Widget?> _pages = List.generate(4, (index) => null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => NonSteamGamesCubit(BlocProvider.of<SettingsCubit>(context)),
        child: BlocBuilder<MainPageCubit, MainPageState>(
          builder: (context, state) {
            int selectedIndex = 0;
            if (state is SelectedPageIndexChanged) {
              selectedIndex = state.selectedIndex;
            }

            return Row(
              children: <Widget>[
                _buildVerticalMenu(context, selectedIndex),

                const VerticalDivider(thickness: 1, width: 1),
                // This is the main content.
                Expanded(child: _getPage(context, selectedIndex)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVerticalMenu(BuildContext context, int selectedIndex) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      groupAlignment: 0,
      onDestinationSelected: (int index) {
        BlocProvider.of<MainPageCubit>(context).selectedIndex = index;
      },
      labelType: NavigationRailLabelType.all,
      /*leading: showLeading
          ? FloatingActionButton(
        elevation: 0,
        onPressed: () {
          // Add your onPressed code here!
        },
        child: const Icon(Icons.star),
      )
          : const SizedBox(),
      trailing: showTrailing
          ? IconButton(
        onPressed: () {
          // Add your onPressed code here!
        },
        icon: const Icon(Icons.more_horiz_rounded),
      )
          : const SizedBox(),*/
      destinations: const <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.gamepad_outlined, size: 40),
          selectedIcon: Icon(Icons.gamepad, size: 40),
          label: Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: Text('Manager'),
          ),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.cleaning_services_outlined, size: 40),
          selectedIcon: Icon(Icons.cleaning_services, size: 40),
          label: Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: Text('Cleaner'),
          ),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined, size: 40),
          selectedIcon: Icon(Icons.settings, size: 40),
          label: Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: Text('Settings'),
          ),
        ),
        NavigationRailDestination(
          icon: Icon(
            Icons.info_outline,
            size: 40,
          ),
          selectedIcon: Icon(Icons.info, size: 40),
          label: Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: Text('Information'),
          ),
        )
      ],
    );
  }

  Widget _getPage(BuildContext context, int selectedIndex) {
    Widget widget = Container();

    if (_pages[selectedIndex] != null) return _pages[selectedIndex]!;
    print("Created!");

    switch (selectedIndex) {
      case 0:
        {
          widget = const NonSteamGamesPage();
          break;
        }
      case 1:
        widget = Container(
          child: Center(child: Text("Comming soon")),
        );
        break;
      case 2:
        widget = SettingsPage();
        break;
      case 3:
        widget = Container(
          child: Center(child: Text("Comming soon")),
        );
        break;
    }

    _pages[selectedIndex] = widget;

    return widget;
  }
}
