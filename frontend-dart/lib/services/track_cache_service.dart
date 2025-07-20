import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/music_models.dart';
import '../services/api_service.dart';

class TrackRetryConfig {
  final int maxRetries;
  final int baseDelayMs;
  final int maxDelayMs;
  final double jitterFactor;
  
  const TrackRetryConfig({
    this.maxRetries = 5,
    this.baseDelayMs = 1000,
    this.maxDelayMs = 30000,
    this.jitterFactor = 0.1,
  });
  
  static const standard = TrackRetryConfig();
  static const aggressive = TrackRetryConfig(maxRetries: 10, baseDelayMs: 500);
  static const conservative = TrackRetryConfig(maxRetries: 3, baseDelayMs: 2000);
}

class TrackCacheService {
  static final TrackCacheService _instance = TrackCacheService._internal();
  factory TrackCacheService() => _instance;
  TrackCacheService._internal();

  final Map<String, Track> _trackCache = {};
  final Map<String, Future<Track?>> _ongoingRequests = {};
  final Map<String, int> _retryCount = {};
  final Map<String, DateTime> _lastRetryTime = {};
  
  // Retry configuration - can be updated at runtime
  TrackRetryConfig _retryConfig = TrackRetryConfig.standard;

  Future<Track?> getTrackDetails(String deezerTrackId, String token, ApiService apiService) async {
    if (_trackCache.containsKey(deezerTrackId)) {
      if (kDebugMode) {
        developer.log('Track $deezerTrackId found in cache', name: 'TrackCacheService');
      }
      return _trackCache[deezerTrackId];
    }

    if (_ongoingRequests.containsKey(deezerTrackId)) {
      if (kDebugMode) {
        developer.log('Track $deezerTrackId already being fetched, waiting for result', name: 'TrackCacheService');
      }
      return await _ongoingRequests[deezerTrackId];
    }

    if (kDebugMode) {
      developer.log('Fetching track details for $deezerTrackId from API', name: 'TrackCacheService');
    }

    final Future<Track?> request = _fetchTrackFromApi(deezerTrackId, token, apiService);
    _ongoingRequests[deezerTrackId] = request;

    try {
      final track = await request;
      if (track != null) {
        _trackCache[deezerTrackId] = track;
        if (kDebugMode) {
          developer.log('Track $deezerTrackId cached successfully', name: 'TrackCacheService');
        }
      }
      return track;
    } finally {
      _ongoingRequests.remove(deezerTrackId);
    }
  }

  Future<Track?> _fetchTrackFromApi(String deezerTrackId, String token, ApiService apiService) async {
    return await _fetchTrackWithRetry(deezerTrackId, token, apiService);
  }

  Future<Track?> _fetchTrackWithRetry(String deezerTrackId, String token, ApiService apiService) async {
    final currentRetries = _retryCount[deezerTrackId] ?? 0;
    
    try {
      final track = await apiService.getDeezerTrack(deezerTrackId, token);
      
      if (track != null) {
        // Success - clear retry tracking
        _retryCount.remove(deezerTrackId);
        _lastRetryTime.remove(deezerTrackId);
        if (kDebugMode) {
          developer.log('Successfully fetched track $deezerTrackId after $currentRetries retries', name: 'TrackCacheService');
        }
        return track;
      } else {
        // API returned null - treat as retriable error
        throw Exception('API returned null for track $deezerTrackId');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error fetching track $deezerTrackId (attempt ${currentRetries + 1}): $e', name: 'TrackCacheService');
      }
      
      if (currentRetries < _retryConfig.maxRetries) {
        return await _scheduleRetry(deezerTrackId, token, apiService, currentRetries);
      } else {
        if (kDebugMode) {
          developer.log('Max retries (${_retryConfig.maxRetries}) reached for track $deezerTrackId, giving up', name: 'TrackCacheService');
        }
        // Clean up retry tracking after max retries
        _retryCount.remove(deezerTrackId);
        _lastRetryTime.remove(deezerTrackId);
        return null;
      }
    }
  }

  Future<Track?> _scheduleRetry(String deezerTrackId, String token, ApiService apiService, int currentRetries) async {
    final retryCount = currentRetries + 1;
    _retryCount[deezerTrackId] = retryCount;
    _lastRetryTime[deezerTrackId] = DateTime.now();
    
    // Calculate exponential backoff delay
    final baseDelay = _retryConfig.baseDelayMs * math.pow(2, retryCount - 1);
    final jitter = math.Random().nextDouble() * _retryConfig.jitterFactor;
    final delayMs = math.min((baseDelay * (1 + jitter)).round(), _retryConfig.maxDelayMs);
    
    if (kDebugMode) {
      developer.log('Scheduling retry $retryCount for track $deezerTrackId in ${delayMs}ms', name: 'TrackCacheService');
    }
    
    await Future.delayed(Duration(milliseconds: delayMs));
    
    // Check if we're still supposed to retry (could have been cleared)
    if (_retryCount.containsKey(deezerTrackId)) {
      return await _fetchTrackWithRetry(deezerTrackId, token, apiService);
    }
    
    return null;
  }

  bool isTrackCached(String deezerTrackId) {
    return _trackCache.containsKey(deezerTrackId);
  }

  Future<void> preloadTracks(List<String> deezerTrackIds, String token, ApiService apiService) async {
    final List<Future<Track?>> futures = [];
    
    for (final trackId in deezerTrackIds) {
      if (!isTrackCached(trackId) && !_ongoingRequests.containsKey(trackId)) {
        futures.add(getTrackDetails(trackId, token, apiService));
      }
    }

    if (futures.isNotEmpty) {
      if (kDebugMode) {
        developer.log('Preloading ${futures.length} tracks', name: 'TrackCacheService');
      }
      await Future.wait(futures);
    }
  }

  Map<String, dynamic> getCacheStats() {
    return {
      'cached_tracks': _trackCache.length,
      'ongoing_requests': _ongoingRequests.length,
      'tracks_retrying': _retryCount.length,
      'retry_details': Map.fromEntries(_retryCount.entries.map((entry) => MapEntry(
        entry.key, 
        {
          'retry_count': entry.value,
          'last_retry': _lastRetryTime[entry.key]?.toIso8601String(),
        }
      ))),
    };
  }

  bool isTrackRetrying(String deezerTrackId) {
    return _retryCount.containsKey(deezerTrackId);
  }

  int getRetryCount(String deezerTrackId) {
    return _retryCount[deezerTrackId] ?? 0;
  }

  DateTime? getLastRetryTime(String deezerTrackId) {
    return _lastRetryTime[deezerTrackId];
  }

  void cancelRetries(String deezerTrackId) {
    _retryCount.remove(deezerTrackId);
    _lastRetryTime.remove(deezerTrackId);
    if (kDebugMode) {
      developer.log('Cancelled retries for track $deezerTrackId', name: 'TrackCacheService');
    }
  }

  void setRetryConfig(TrackRetryConfig config) {
    _retryConfig = config;
    if (kDebugMode) {
      developer.log('Updated retry config: maxRetries=${config.maxRetries}, baseDelayMs=${config.baseDelayMs}', name: 'TrackCacheService');
    }
  }

  TrackRetryConfig get retryConfig => _retryConfig;

  void clearCache() {
    _trackCache.clear();
    _retryCount.clear();
    _lastRetryTime.clear();
    if (kDebugMode) {
      developer.log('Track cache and retry tracking cleared', name: 'TrackCacheService');
    }
  }

  void updateTrackInCache(String deezerTrackId, Track track) {
    _trackCache[deezerTrackId] = track;
    if (kDebugMode) {
      developer.log('Track $deezerTrackId updated in cache', name: 'TrackCacheService');
    }
  }

  void removeFromCache(String deezerTrackId) {
    _trackCache.remove(deezerTrackId);
    if (kDebugMode) {
      developer.log('Track $deezerTrackId removed from cache', name: 'TrackCacheService');
    }
  }
}
