import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:get_it/get_it.dart';

import '../../data/models/steam_config.dart';
import '../../data/repositories/steam_config_repository.dart';

typedef void TUserSelectedCallback(BuildContext context, SteamUser steamUser);

class SteamUserSelector extends StatefulWidget {
  final TUserSelectedCallback _userSelectedCallback;

  const SteamUserSelector({Key? key,required TUserSelectedCallback userSelectedCallback}) : _userSelectedCallback = userSelectedCallback, super(key: key);

  @override
  State<SteamUserSelector> createState() => _SteamUserSelectorState();
}

class _SteamUserSelectorState extends State<SteamUserSelector> {

  @override
  Widget build(BuildContext context) {

    SteamConfigRepository scr = GetIt.I<SteamConfigRepository>();
    List<SteamUser> steamUsers =scr.getConfig().steamUsers;

    return SizedBox(
      height: 300,
      width: 400,
      child: ListView.builder(
          itemCount: steamUsers.length,
          itemBuilder: (context, index) => ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.redAccent,
              radius: 25,
              child: ClipOval(
                child: CircleAvatar(
                  radius:22,
                  child: steamUsers[index].avatarUrlSmall != null
                      ? CachedNetworkImage(imageUrl: steamUsers[index].avatarUrlMedium!,
                    fit: BoxFit.fill,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, error, stackTrace) {
                      return const Icon(Icons.person);
                    },
                  )
                      : const Icon(Icons.person),
                ),
              ),
            ),
            title: Text(steamUsers[index].accountName),
            subtitle: Text(steamUsers[index].personName),
            onTap: () async{
              widget._userSelectedCallback(context, steamUsers[index]);
            },
          )),
    );
  }
}
