import '../core/navigation_core.dart';
import 'dart:math' as math;
import '../models/music_models.dart';
import '../services/api_services.dart';

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
  
  TrackRetryConfig _retryConfig = TrackRetryConfig.standard;

  Future<Track?> getTrackDetails(String deezerTrackId, String token, ApiService apiService) async {
    if (_trackCache.containsKey(deezerTrackId)) {
      AppLogger.debug('Track $deezerTrackId found in cache', 'TrackCacheService');
      return _trackCache[deezerTrackId];
    }

    if (_ongoingRequests.containsKey(deezerTrackId)) {
      AppLogger.debug('Track $deezerTrackId already being fetched, waiting for result', 'TrackCacheService');
      return await _ongoingRequests[deezerTrackId];
    }

    AppLogger.debug('Fetching track details for $deezerTrackId from API', 'TrackCacheService');

    final Future<Track?> request = _fetchTrackWithRetry(deezerTrackId, token, apiService);
    _ongoingRequests[deezerTrackId] = request;

    try {
      final track = await request;
      if (track != null) {
        _trackCache[deezerTrackId] = track;
        AppLogger.debug('Track $deezerTrackId cached successfully', 'TrackCacheService');
      }
      return track;
    } finally {
      _ongoingRequests.remove(deezerTrackId);
    }
  }


  Future<Track?> _fetchTrackWithRetry(String deezerTrackId, String token, ApiService apiService) async {
    final currentRetries = _retryCount[deezerTrackId] ?? 0;
    
    try {
      final track = await apiService.getDeezerTrack(deezerTrackId, token);
      
      if (track != null) {
        _retryCount.remove(deezerTrackId);
        _lastRetryTime.remove(deezerTrackId);
        AppLogger.info('Successfully fetched track $deezerTrackId after $currentRetries retries', 'TrackCacheService');
        return track;
      } else {
        throw Exception('API returned null for track $deezerTrackId');
      }
    } catch (e) {
      AppLogger.error('Error fetching track $deezerTrackId (attempt ${currentRetries + 1}): ${e.toString()}', null, null, 'TrackCacheService');
      
      if (currentRetries < _retryConfig.maxRetries) {
        return await _scheduleRetry(deezerTrackId, token, apiService, currentRetries);
      } else {
        AppLogger.warning('Max retries (${_retryConfig.maxRetries}) reached for track $deezerTrackId, giving up', 'TrackCacheService');
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
    
    final baseDelay = _retryConfig.baseDelayMs * math.pow(2, retryCount - 1);
    final jitter = math.Random().nextDouble() * _retryConfig.jitterFactor;
    final delayMs = math.min((baseDelay * (1 + jitter)).round(), _retryConfig.maxDelayMs);
    
    AppLogger.debug('Scheduling retry $retryCount for track $deezerTrackId in ${delayMs}ms', 'TrackCacheService');
    
    await Future.delayed(Duration(milliseconds: delayMs));
    
    if (_retryCount.containsKey(deezerTrackId)) {
      return await _fetchTrackWithRetry(deezerTrackId, token, apiService);
    }
    
    return null;
  }

  bool isTrackCached(String deezerTrackId) {
    return _trackCache.containsKey(deezerTrackId);
  }

  Track? operator [](String deezerTrackId) {
    return _trackCache[deezerTrackId];
  }

  Future<void> preloadTracks(List<String> deezerTrackIds, String token, ApiService apiService) async {
    final List<Future<Track?>> futures = [];
    
    for (final trackId in deezerTrackIds) {
      if (!isTrackCached(trackId) && !_ongoingRequests.containsKey(trackId)) {
        futures.add(getTrackDetails(trackId, token, apiService));
      }
    }

    if (futures.isNotEmpty) {
      AppLogger.debug('Preloading ${futures.length} tracks', 'TrackCacheService');
      await Future.wait(futures);
    }
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
    AppLogger.debug('Cancelled retries for track $deezerTrackId', 'TrackCacheService');
  }

  void setRetryConfig(TrackRetryConfig config) {
    _retryConfig = config;
    AppLogger.debug('Updated retry config: maxRetries=${config.maxRetries}, baseDelayMs=${config.baseDelayMs}', 'TrackCacheService');
  }

  TrackRetryConfig get retryConfig => _retryConfig;

  Map<String, int> get retryCount => Map.unmodifiable(_retryCount);

  void clearCache() {
    _trackCache.clear();
    _retryCount.clear();
    _lastRetryTime.clear();
    AppLogger.debug('Track cache and retry tracking cleared', 'TrackCacheService');
  }


}
