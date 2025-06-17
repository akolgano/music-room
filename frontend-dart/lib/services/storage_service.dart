// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static late Box _box;

  static Future<StorageService> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('app_storage');
    return StorageService._();
  }

  StorageService._();

  T? get<T>(String key) => _box.get(key);
  
  Future<void> set(String key, dynamic value) => _box.put(key, value);
  
  Future<void> delete(String key) => _box.delete(key);
  
  Future<void> clear() => _box.clear();
  
  bool containsKey(String key) => _box.containsKey(key);
  
  List<String> get keys => _box.keys.cast<String>().toList();
}
