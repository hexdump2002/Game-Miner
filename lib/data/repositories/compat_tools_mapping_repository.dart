import 'package:game_miner/data/data_providers/compat_tools_data_provider.dart';
import 'package:game_miner/data/data_providers/compat_tools_mapping_data_provider.dart';
import 'package:game_miner/data/models/compat_tool_mapping.dart';
import 'package:game_miner/data/repositories/cache_repository.dart';
import 'package:get_it/get_it.dart';

import '../models/compat_tool.dart';

class CompatToolsMappipngRepository extends CacheRepository<CompatToolMapping>{
  final String cacheKey = "CompatToolMappings";

  final CompatToolsMappingDataProvider _ctmr = GetIt.I<CompatToolsMappingDataProvider>();

  Future<List<CompatToolMapping>> loadCompatToolMappings() async {

    List<CompatToolMapping>? compatToolMappings = getObjectsFromCache(cacheKey);

    if(compatToolMappings == null) {
      List<CompatToolMapping> compatToolMappings = await _ctmr.loadCompatToolMappings();
      setCacheKey(cacheKey, compatToolMappings);
      return List.from(compatToolMappings);
    }
    else {
      return List.from(compatToolMappings!);
    }
  }

  List<CompatToolMapping> getCachedCompatToolMappings() {
    List<CompatToolMapping>? data = getObjectsFromCache(cacheKey);
    return data ?? [];
  }

  Future<bool> saveCompatToolMappings(String path, List<CompatToolMapping> compatToolMappings, Map<String, dynamic> extraParams) async {
    await _ctmr.saveCompatToolMappings(path, compatToolMappings, extraParams);
    return true;
  }



}