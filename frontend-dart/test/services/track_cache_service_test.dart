import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:music_room/services/track_cache_service.dart';
import 'package:music_room/services/api_service.dart';
import 'package:music_room/models/music_models.dart';

void main() {
  group('Track Cache Service Tests', () {
    late TrackCacheService cacheService;

    setUp(() {
      cacheService = TrackCacheService();
      final dio = Dio();
      dio.options.baseUrl = 'http://localhost:8000';
      ApiService(dio);
      cacheService.clearCache();
    });

    test('TrackCacheService should be a singleton', () {
      final instance1 = TrackCacheService();
      final instance2 = TrackCacheService();
      
      expect(instance1, same(instance2));
    });

    test('TrackCacheService should handle cache operations', () {
      const testTrackId = 'test_track_123';
      
      expect(cacheService.isTrackCached(testTrackId), false);
      
      const testTrack = Track(
        id: 'track_1',
        name: 'Test Track',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track',
        previewUrl: 'https://example.com/preview',
        imageUrl: 'https://example.com/image',
        deezerTrackId: testTrackId,
      );
      
      cacheService.updateTrackInCache(testTrackId, testTrack);
      expect(cacheService.isTrackCached(testTrackId), true);
      
      cacheService.removeFromCache(testTrackId);
      expect(cacheService.isTrackCached(testTrackId), false);
    });

    test('TrackCacheService should implement retry logic with exponential backoff', () {
      expect(cacheService.retryConfig.maxRetries, 5);
      expect(cacheService.retryConfig.baseDelayMs, 1000);
      expect(cacheService.retryConfig.maxDelayMs, 30000);
      expect(cacheService.retryConfig.jitterFactor, 0.1);
    });

    test('TrackCacheService should track retry status correctly', () {
      const testTrackId = 'test_track_123';
      
      expect(cacheService.isTrackRetrying(testTrackId), false);
      expect(cacheService.getRetryCount(testTrackId), 0);
      expect(cacheService.getLastRetryTime(testTrackId), null);
    });

    test('TrackCacheService should handle retry configuration', () {
      const newConfig = TrackRetryConfig(
        maxRetries: 3,
        baseDelayMs: 500,
        maxDelayMs: 15000,
        jitterFactor: 0.2,
      );
      
      cacheService.setRetryConfig(newConfig);
      
      expect(cacheService.retryConfig.maxRetries, 3);
      expect(cacheService.retryConfig.baseDelayMs, 500);
      expect(cacheService.retryConfig.maxDelayMs, 15000);
      expect(cacheService.retryConfig.jitterFactor, 0.2);
    });

    test('TrackCacheService should provide cache statistics', () {
      final stats = cacheService.getCacheStats();
      
      expect(stats, containsPair('cached_tracks', isA<int>()));
      expect(stats, containsPair('ongoing_requests', isA<int>()));
      expect(stats, containsPair('tracks_retrying', isA<int>()));
      expect(stats, containsPair('retry_details', isA<Map>()));
    });

    test('TrackCacheService should cancel retries', () {
      const testTrackId = 'test_track_123';
      
      cacheService.cancelRetries(testTrackId);
      
      expect(cacheService.isTrackRetrying(testTrackId), false);
      expect(cacheService.getRetryCount(testTrackId), 0);
    });

    test('TrackCacheService should clear cache properly', () {
      const testTrackId = 'test_track_123';
      const testTrack = Track(
        id: 'track_1',
        name: 'Test Track',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://example.com/track',
        previewUrl: 'https://example.com/preview',
        imageUrl: 'https://example.com/image',
        deezerTrackId: testTrackId,
      );
      
      cacheService.updateTrackInCache(testTrackId, testTrack);
      expect(cacheService.isTrackCached(testTrackId), true);
      
      cacheService.clearCache();
      expect(cacheService.isTrackCached(testTrackId), false);
    });

    test('TrackRetryConfig should have predefined configurations', () {
      expect(TrackRetryConfig.standard.maxRetries, 5);
      expect(TrackRetryConfig.aggressive.maxRetries, 10);
      expect(TrackRetryConfig.conservative.maxRetries, 3);
      
      expect(TrackRetryConfig.standard.baseDelayMs, 1000);
      expect(TrackRetryConfig.aggressive.baseDelayMs, 500);
      expect(TrackRetryConfig.conservative.baseDelayMs, 2000);
    });
  });
}