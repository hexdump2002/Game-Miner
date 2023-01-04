import 'package:game_miner/data/data_providers/steam_users_data_provider.dart';
import 'package:game_miner/data/models/steam_user.dart';
import 'package:game_miner/data/repositories/cache_repository.dart';
import 'package:get_it/get_it.dart';

class SteamUserRepository extends CacheRepository<SteamUser> {
  final SteamUsersDataProvider _steamUsersDataProvider = GetIt.I<SteamUsersDataProvider>();

  Future<List<SteamUser>> loadUsers() async {
    const String cacheKey = "SteamUsers";
    List<SteamUser>? users = getObjectsFromCache(cacheKey);
    if(users==null) {
      List<SteamUser> users = await _steamUsersDataProvider.loadUsers();
      setCacheKey(cacheKey, users);
      return List.from(users);
    }
    else {
      return List.from(users!);
    }
  }

  SteamUser? getFirstUser() {
    var users = getObjectsFromCache("SteamUsers");
    return users!=null && users.isNotEmpty ?  users[0] : null;
  }
}