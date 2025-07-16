import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class TrackCacheService {
  static final TrackCacheService _instance = TrackCacheService._internal();
  factory TrackCacheService() => _instance;
  TrackCacheService._internal();

  final Map<String, Track> _trackCache = {};
  final Map<String, Future<Track?>> _ongoingRequests = {};

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
    try {
      final formattedToken = 'Token $token';
      return await apiService.getDeezerTrack(deezerTrackId, formattedToken);
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error fetching track $deezerTrackId: $e', name: 'TrackCacheService');
      }
      return null;
    }
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

  Map<String, int> getCacheStats() {
    return {
      'cached_tracks': _trackCache.length,
      'ongoing_requests': _ongoingRequests.length,
    };
  }

  void clearCache() {
    _trackCache.clear();
    if (kDebugMode) {
      developer.log('Track cache cleared', name: 'TrackCacheService');
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
