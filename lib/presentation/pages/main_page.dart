import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:game_miner/data/models/steam_config.dart';
import 'package:game_miner/data/repositories/steam_user_repository.dart';
import 'package:game_miner/logic/Tools/dialog_tools.dart';
import 'package:game_miner/logic/Tools/steam_tools.dart';
import 'package:game_miner/logic/blocs/game_data_mgr_cubit.dart';
import 'package:game_miner/logic/blocs/main_dart_cubit.dart';
import 'package:game_miner/logic/blocs/game_mgr_cubit.dart';
import 'package:game_miner/logic/blocs/settings_cubit.dart';
import 'package:game_miner/presentation/pages/game_data_mgr_page.dart';
import 'package:game_miner/presentation/pages/settings_page.dart';
import 'package:get_it/get_it.dart';
import 'package:window_manager/window_manager.dart';

import '../widgets/steam_user_selector_widget.dart';
import 'game_mgr_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WindowListener {
  List<dynamic> _cubits = List.generate(4, (index) => null);
  List<Widget?> _pages = List.generate(4, (index) => null);

  late MainPageCubit _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = BlocProvider.of<MainPageCubit>(context);
    windowManager.addListener(this);
    _init();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    showDataNotSavedDialog(context,tr("warning"), tr("config_not_saved_exit_text"),tr("warning"), tr("data_not_saved_exit_text"),() async => await windowManager.destroy());
  }

  void showDataNotSavedDialog(BuildContext buildContext, String configNotSavedCaption, String configNotSaveText, String dataNotSavedCaption, String dataNotSavedText,VoidCallback doAction) async {
    if (_cubits[2] != null && (_cubits[2] as SettingsCubit).modified) {
      showSimpleDialog(buildContext,configNotSavedCaption,configNotSaveText, true, true, () async {
        //Navigator.of(buildContext).pop();
        doAction();
      });
    }
    else if ((_cubits[0] as GameMgrCubit).modified) {
      showSimpleDialog(buildContext,dataNotSavedCaption, dataNotSavedText, true, true, () async {
        //Navigator.of(buildContext).pop();
        doAction();
      });
    }
    else {
      doAction();
    }
  }


  void _init() async {
    // Add this line to override the default close handler
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MainPageCubit, MainPageState>(
        builder: (context, state) {
          int selectedIndex = 0;
          if (state is SelectedPageIndexChanged) {
            selectedIndex = state.selectedIndex;
          }

          SteamUser su = state.steamUser;

          return Row(
            children: <Widget>[
              _buildVerticalMenu(context, su, selectedIndex),

              const VerticalDivider(thickness: 1, width: 1),
              // This is the main content.
              Expanded(child: _getPage(context, selectedIndex)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVerticalMenu(BuildContext context, SteamUser su, int selectedIndex) {
    return Column(
      children: [
        Expanded(
          child: NavigationRail(
            selectedIndex: selectedIndex,
            groupAlignment: 0,
            onDestinationSelected: (int index) {
              if (canMoveToDiffentPage()) {
                BlocProvider
                    .of<MainPageCubit>(context)
                    .selectedIndex = index;
              }
              else {
                if (_bloc.selectedIndex == 2) {
                  showSimpleDialog(context, tr("warning"), tr('config_not_saved_exit_text'), true, true, () async {
                    BlocProvider
                        .of<MainPageCubit>(context)
                        .selectedIndex = index;
                  });
                }
              }
            },
            labelType: NavigationRailLabelType.all,
            leading: Tooltip(
              message: su.personName,
              child: InkWell(
                onTap: () => _showUserSelector(context, tr("change_user")),
                child: CircleAvatar(
                  radius: 35,
                  child: ClipOval(
                    child: CircleAvatar(
                        radius: 30,
                        child: su.avatarUrlMedium != null
                            ? CachedNetworkImage(imageUrl: su.avatarUrlMedium!,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, error, stackTrace) {
                            return const Icon(Icons.person);
                          },
                        )
                            : const Icon(Icons.person)),
                  ),
                ),
              ),
            ),
            /*trailing: IconButton(
              onPressed: () {
                // Add your onPressed code here!
              },
              icon: const Icon(Icons.more_horiz_rounded),
            ),*/
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
              /*NavigationRailDestination(
                icon: Icon(
                  Icons.info_outline,
                  size: 40,
                ),
                selectedIcon: Icon(Icons.info, size: 40),
                label: Padding(
                  padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
                  child: Text('Information'),
                ),
              ),*/

            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Tooltip(
            message: tr("open_steam"),
            child: GestureDetector(
                child: Image.asset('assets/images/steam.png', width: 64, height: 64,),
                onTap: () async {
                  // do something when the button is pressed
                  EasyLoading.show(status: tr("opening_steam"));
                  SteamTools.openSteamClient(false);
                  await Future.delayed(const Duration(seconds: 3));
                  EasyLoading.dismiss();
                }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: const Text("0.9.023"),
        ) //versión
      ],

    );
  }

  Widget _getPage(BuildContext context, int selectedIndex) {
    Widget widget = Container();

    if (_pages[selectedIndex] != null) return _pages[selectedIndex]!;

    switch (selectedIndex) {
      case 0:
        {
          var cubit = GameMgrCubit();
          _cubits[0] = cubit;
          widget = BlocProvider.value(value: cubit, child: GameMgrPage());
          break;
        }
      case 1:
        {
          var cubit = GameDataMgrCubit();
          _cubits[1] = cubit;
          widget = BlocProvider.value(value: cubit, child: const GameDataMgrPage());
        }
        break;
      case 2:
        widget = BlocProvider(
          create: (context) {
            var cubit = SettingsCubit();
            _cubits[2] = cubit;
            return cubit;
          },
          child: SettingsPage(),
        );
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

  void _showUserSelector(BuildContext buildContext, String caption) {

    showDataNotSavedDialog(buildContext, tr("warning"), tr("config_not_saved_change_user_text"),tr("warning"), tr("data_not_saved_change_user_text"),() {
      Future.microtask(() => showPlatformDialog(
        context: context,
        builder: (context) =>
            BasicDialogAlert(
                title: Text(caption),
                content: SteamUserSelector(
                    userSelectedCallback: (BuildContext context, SteamUser steamUser) => {_bloc.changeUser(buildContext, steamUser)}),
                actions: [
                  BasicDialogAction(
                    title: Text(tr("cancel")),
                    onPressed: () {
                      Navigator.pop(buildContext);
                    },
                  ),
                ]),
      ));});
  }

  bool canMoveToDiffentPage() {
    if (_bloc.selectedIndex == 2 && (_cubits[2] as SettingsCubit).modified) {
      return false;
    }

    return true;
  }
}
