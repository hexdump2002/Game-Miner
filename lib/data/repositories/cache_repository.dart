class CacheRepository<T> {
  final Map<String, List<T>> _cachedData = <String,List<T>>{};

  List<T>? getObjectsFromCache(String key) {
      return _cachedData[key];
  }

  /*T? getObjectFromCache(String key, String id) {
    List<T>? objects = getObjectsFromCache(key);

    return objects?.firstWhere((element) => element.id.equals(id));
  }*/

  void setCacheKey(String key, List<T> objects) {
    _cachedData[key] = objects;
  }

  void removeCacheKey(String key) {
    _cachedData.remove(key);
  }
}