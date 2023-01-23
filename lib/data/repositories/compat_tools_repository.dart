import 'package:game_miner/data/data_providers/compat_tools_data_provider.dart';
import 'package:game_miner/data/repositories/cache_repository.dart';
import 'package:get_it/get_it.dart';

import '../models/compat_tool.dart';

class CompatToolsRepository extends CacheRepository<CompatTool>{
  final String cacheKey = "CompatTools";
  final CompatToolsDataProvider _ctdp = GetIt.I<CompatToolsDataProvider>();

  Future<List<CompatTool>> loadCompatTools() async {

    List<CompatTool>? compatTools = getObjectsFromCache(cacheKey);

    if(compatTools == null) {
      List<CompatTool> externalCompatTools = await _ctdp.loadExternalCompatTools();
      List<CompatTool> internalCompatTools = await _ctdp.loadInternalCompatTools();
      List<CompatTool> compatTools = [];
      compatTools..addAll(externalCompatTools)..addAll(internalCompatTools);
      compatTools.sort((a,b) => a.displayName.compareTo(b.displayName));
      setCacheKey(cacheKey, compatTools);
      return List.from(compatTools);
    }

    return List.from(compatTools!);

  }

  Future<String> getCompatToolNameFromCode(String code) async{
    return (await loadCompatTools()).firstWhere((e) => e.code == code).displayName;
  }

  Future<String> getCompatToolCodeFromName(String compatToolName) async{
    return (await loadCompatTools()).firstWhere((e) => e.displayName == compatToolName).code;
  }

  List<CompatTool> getCachedCompatTools() {
    List<CompatTool>? data = getObjectsFromCache(cacheKey);
    return data ?? [];
  }

  String getCachedCompatToolNameFromCode(String code) {
    return getCachedCompatTools().firstWhere((e) => e.code == code).displayName;
  }

  String getCachedCompatToolCodeFromName(String displayName) {
    return getCachedCompatTools().firstWhere((e) => e.displayName == displayName).code;
  }

}