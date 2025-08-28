import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/services/cache_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('CacheService Tests', () {
    late TrackCacheService cacheService;

    setUp(() {
      cacheService = TrackCacheService();
    });

    test('should create TrackCacheService instance', () {
      expect(cacheService, isA<TrackCacheService>());
    });

    test('should clear all cached values', () async {
      cacheService.clearCache();
    });
  });
}