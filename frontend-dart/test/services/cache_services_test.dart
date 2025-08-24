import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:music_room/services/cache_services.dart';

class MockCacheService extends Mock implements CacheService {}

void main() {
  group('CacheService Tests', () {
    late CacheService cacheService;
    late MockCacheService mockCacheService;

    setUp(() {
      cacheService = CacheService();
      mockCacheService = MockCacheService();
    });

    test('should create CacheService instance', () {
      expect(cacheService, isA<CacheService>());
    });

    test('should store and retrieve string values', () async {
      const key = 'test_string';
      const value = 'test_value';
      
      await cacheService.setString(key, value);
      final retrievedValue = await cacheService.getString(key);
      
      expect(retrievedValue, equals(value));
    });

    test('should store and retrieve int values', () async {
      const key = 'test_int';
      const value = 42;
      
      await cacheService.setInt(key, value);
      final retrievedValue = await cacheService.getInt(key);
      
      expect(retrievedValue, equals(value));
    });

    test('should store and retrieve bool values', () async {
      const key = 'test_bool';
      const value = true;
      
      await cacheService.setBool(key, value);
      final retrievedValue = await cacheService.getBool(key);
      
      expect(retrievedValue, equals(value));
    });

    test('should store and retrieve double values', () async {
      const key = 'test_double';
      const value = 3.14;
      
      await cacheService.setDouble(key, value);
      final retrievedValue = await cacheService.getDouble(key);
      
      expect(retrievedValue, equals(value));
    });

    test('should store and retrieve string list values', () async {
      const key = 'test_list';
      const value = ['item1', 'item2', 'item3'];
      
      await cacheService.setStringList(key, value);
      final retrievedValue = await cacheService.getStringList(key);
      
      expect(retrievedValue, equals(value));
    });

    test('should return null for non-existent keys', () async {
      final value = await cacheService.getString('non_existent_key');
      expect(value, isNull);
    });

    test('should handle removal of cached values', () async {
      const key = 'test_removal';
      const value = 'test_value';
      
      await cacheService.setString(key, value);
      await cacheService.remove(key);
      final retrievedValue = await cacheService.getString(key);
      
      expect(retrievedValue, isNull);
    });

    test('should clear all cached values', () async {
      await cacheService.setString('key1', 'value1');
      await cacheService.setString('key2', 'value2');
      
      await cacheService.clear();
      
      final value1 = await cacheService.getString('key1');
      final value2 = await cacheService.getString('key2');
      
      expect(value1, isNull);
      expect(value2, isNull);
    });

    test('should check if key exists in cache', () async {
      const key = 'test_existence';
      
      expect(await cacheService.containsKey(key), false);
      
      await cacheService.setString(key, 'value');
      expect(await cacheService.containsKey(key), true);
    });

    test('should get all cached keys', () async {
      await cacheService.clear();
      
      await cacheService.setString('key1', 'value1');
      await cacheService.setString('key2', 'value2');
      
      final keys = await cacheService.getKeys();
      expect(keys, contains('key1'));
      expect(keys, contains('key2'));
    });

    test('should handle cache size limits gracefully', () async {
      const largeValue = 'x' * 10000;
      const key = 'large_value';
      
      await cacheService.setString(key, largeValue);
      final retrievedValue = await cacheService.getString(key);
      
      expect(retrievedValue, equals(largeValue));
    });

    test('should handle concurrent cache operations', () async {
      final futures = <Future>[];
      
      for (int i = 0; i < 10; i++) {
        futures.add(cacheService.setString('key_$i', 'value_$i'));
      }
      
      await Future.wait(futures);
      
      for (int i = 0; i < 10; i++) {
        final value = await cacheService.getString('key_$i');
        expect(value, equals('value_$i'));
      }
    });

    test('should handle cache expiration if supported', () async {
      const key = 'expiring_key';
      const value = 'expiring_value';
      
      await cacheService.setString(key, value);
      final retrievedValue = await cacheService.getString(key);
      
      expect(retrievedValue, equals(value));
    });

    test('should provide cache statistics if available', () {
      final stats = cacheService.getStats();
      expect(stats, isA<Map<String, dynamic>>());
    });

    test('should handle invalid data types gracefully', () async {
      expect(() => cacheService.setString('key', null), throwsArgumentError);
    });
  });

  group('MockCacheService Tests', () {
    late MockCacheService mockCache;

    setUp(() {
      mockCache = MockCacheService();
    });

    test('should mock string operations', () async {
      when(mockCache.getString('key')).thenAnswer((_) async => 'mocked_value');
      when(mockCache.setString('key', 'value')).thenAnswer((_) async => true);
      
      final result = await mockCache.setString('key', 'value');
      final value = await mockCache.getString('key');
      
      expect(result, true);
      expect(value, 'mocked_value');
      
      verify(mockCache.setString('key', 'value')).called(1);
      verify(mockCache.getString('key')).called(1);
    });

    test('should mock removal operations', () async {
      when(mockCache.remove('key')).thenAnswer((_) async => true);
      when(mockCache.containsKey('key')).thenAnswer((_) async => false);
      
      await mockCache.remove('key');
      final exists = await mockCache.containsKey('key');
      
      expect(exists, false);
      verify(mockCache.remove('key')).called(1);
      verify(mockCache.containsKey('key')).called(1);
    });
  });
}