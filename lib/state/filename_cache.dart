import 'dart:collection';

class FilenameCache {
  static final Map<String, String> _cache = HashMap();

  static String? get(String fileId) => _cache[fileId];

  static void put(String fileId, String name) {
    _cache[fileId] = name;
  }

  static void clear() {
    _cache.clear();
  }
}
