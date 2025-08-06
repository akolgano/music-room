import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static late Box _box;

  static Future<StorageService> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('app_storage');
    return StorageService._();
  }

  StorageService._();

  T? get<T>(String key) {
    final value = _box.get(key);
    if (value == null) { return null; }
    return value as T?;
  }

  Map<String, dynamic>? getMap(String key) {
    final value = _box.get(key);
    if (value == null) { return null; }
    if (value is Map<String, dynamic>) { return value; }
    if (value is Map) { return Map<String, dynamic>.from(value); }
    return null;
  }

  Future<void> set(String key, dynamic value) => _box.put(key, value);

  Future<void> delete(String key) => _box.delete(key);

  Future<void> clear() => _box.clear();

  bool containsKey(String key) => _box.containsKey(key);

}
