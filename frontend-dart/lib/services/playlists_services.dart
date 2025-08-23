import 'dart:async';
import 'package:flutter/material.dart';
import '../models/music_models.dart';
import '../models/voting_models.dart';
import '../models/api_models.dart';
import '../services/api_services.dart';
import '../services/cache_services.dart';
import '../services/websocket_services.dart';
import '../core/locator_core.dart';
import '../core/navigation_core.dart';

class PlaylistVotingService {
  final String playlistId;
  
  bool _isPublicVoting = true;
  String _votingLicenseType = 'open';
  DateTime? _votingStartTime, _votingEndTime;
  PlaylistVotingInfo? _votingInfo;
  double? _latitude, _longitude;
  int? _allowedRadiusMeters;

  PlaylistVotingService({required this.playlistId});

  bool get isPublicVoting => _isPublicVoting;
  String get votingLicenseType => _votingLicenseType;
  DateTime? get votingStartTime => _votingStartTime;
  DateTime? get votingEndTime => _votingEndTime;
  PlaylistVotingInfo? get votingInfo => _votingInfo;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  int? get allowedRadiusMeters => _allowedRadiusMeters;

  void setPublicVoting(bool value) => _isPublicVoting = true;
  void setVotingLicenseType(String value) => _votingLicenseType = value;
  void setVotingStartTime(DateTime? value) => _votingStartTime = value;
  void setVotingEndTime(DateTime? value) => _votingEndTime = value;

  String? _formatTime(DateTime? time) => time != null 
    ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}'
    : null;

  DateTime? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    return DateTime(2000, 1, 1,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
      parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0);
  }

  Future<void> applyVotingSettings(String authToken) async {
    try {
      final isLocationTime = _votingLicenseType == 'location_time';
      final request = PlaylistLicenseRequest(
        licenseType: _votingLicenseType,
        invitedUsers: _votingLicenseType != 'open' ? [] : null,
        voteStartTime: isLocationTime ? _formatTime(_votingStartTime) : null,
        voteEndTime: isLocationTime ? _formatTime(_votingEndTime) : null,
        latitude: isLocationTime ? _latitude : null,
        longitude: isLocationTime ? _longitude : null,
        allowedRadiusMeters: isLocationTime ? _allowedRadiusMeters : null,
      );

      await getIt<ApiService>().updatePlaylistLicense(playlistId, authToken, request);
      await loadVotingSettings(authToken);
      
      _votingInfo = PlaylistVotingInfo(
        playlistId: playlistId,
        restrictions: VotingRestrictions(
          licenseType: _votingLicenseType,
          isInvited: true,
          isInTimeWindow: !isLocationTime || _isInVotingTimeWindow(),
          isInLocation: true,
        ),
        trackVotes: {},
      );
    } catch (e) {
      AppLogger.error('Failed to update voting settings', e, null, 'PlaylistVotingService');
      rethrow;
    }
  }

  Future<void> loadVotingSettings(String authToken, {bool isOwner = true}) async {
    _isPublicVoting = true;
    
    if (!isOwner) {
      _votingLicenseType = 'open';
      AppLogger.info('Skipping voting settings for non-owner', 'PlaylistVotingService');
      return;
    }
    
    try {
      final response = await getIt<ApiService>().getPlaylistLicense(playlistId, authToken);
      _votingLicenseType = response.licenseType;
      _votingStartTime = _parseTime(response.voteStartTime);
      _votingEndTime = _parseTime(response.voteEndTime);
      _latitude = response.latitude;
      _longitude = response.longitude;
      _allowedRadiusMeters = response.allowedRadiusMeters;
      _isPublicVoting = response.licenseType == 'open';
      
      AppLogger.info('Successfully loaded voting settings: ${response.licenseType}', 'PlaylistVotingService');
    } catch (e) {
      AppLogger.error('Failed to load voting settings: $e', null, null, 'PlaylistVotingService');
      rethrow;
    }
  }

  bool _isInVotingTimeWindow() {
    final now = DateTime.now();
    return !(_votingStartTime != null && now.isBefore(_votingStartTime!) ||
             _votingEndTime != null && now.isAfter(_votingEndTime!));
  }

  Future<DateTime?> selectVotingDateTime(BuildContext context, bool isStartTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        if (isStartTime) {
          _votingStartTime = dateTime;
        } else {
          _votingEndTime = dateTime;
        }
        return dateTime;
      }
    }
    return null;
  }
}

class PlaylistTrackService {
  final ApiService _apiService;
  final TrackCacheService _trackCacheService;
  final Set<String> _fetchingTrackDetails = {};

  PlaylistTrackService({
    required ApiService apiService,
    required TrackCacheService trackCacheService,
  }) : _apiService = apiService, _trackCacheService = trackCacheService;

  Set<String> get fetchingTrackDetails => _fetchingTrackDetails;

  bool _trackHasMissingDetails(Track? track) =>
    track?.artist.isEmpty == true || track?.album.isEmpty == true;

  bool needsTrackDetailsFetch(Track? track) =>
    track?.deezerTrackId != null && 
    _trackHasMissingDetails(track) &&
    !_fetchingTrackDetails.contains(track!.deezerTrackId!);

  bool shouldSkipTrackDetailsFetch(String? deezerTrackId, Track? track) =>
    deezerTrackId == null || 
    _fetchingTrackDetails.contains(deezerTrackId) || 
    (track != null && !_trackHasMissingDetails(track));

  Future<Track?> fetchTrackDetailsIfNeeded(PlaylistTrack playlistTrack, String authToken) async {
    final track = playlistTrack.track;
    final deezerTrackId = track?.deezerTrackId;
    
    if (shouldSkipTrackDetailsFetch(deezerTrackId, track)) return null;

    final nonNullDeezerTrackId = deezerTrackId!;
    _fetchingTrackDetails.add(nonNullDeezerTrackId);
    
    try {
      return await _trackCacheService.getTrackDetails(
        nonNullDeezerTrackId, authToken, _apiService);
    } catch (e) {
      AppLogger.error('Failed to fetch track details for $deezerTrackId', e, null, 'PlaylistTrackService');
      return null;
    } finally {
      _fetchingTrackDetails.remove(nonNullDeezerTrackId);
    }
  }

  Future<List<Track?>> batchFetchTrackDetails(
    List<PlaylistTrack> tracksNeedingDetails, 
    String authToken
  ) async {
    if (tracksNeedingDetails.isEmpty) return [];
    
    AppLogger.debug('Starting parallel fetch for ${tracksNeedingDetails.length} tracks', 'PlaylistTrackService');
    
    try {
      final results = await Future.wait(
        tracksNeedingDetails.map((pt) => fetchTrackDetailsIfNeeded(pt, authToken)));
      AppLogger.debug('Completed parallel fetch for ${tracksNeedingDetails.length} tracks', 'PlaylistTrackService');
      return results;
    } catch (e) {
      AppLogger.error('Error in batch track fetch', e, null, 'PlaylistTrackService');
      return [];
    }
  }

  Future<void> batchFetchTrackDetailsProgressive(
    List<PlaylistTrack> tracksNeedingDetails,
    String authToken, {
    required Function(PlaylistTrack, Track?) onTrackLoaded,
  }) async {
    if (tracksNeedingDetails.isEmpty) return;
    
    AppLogger.debug('Starting progressive fetch for ${tracksNeedingDetails.length} tracks', 'PlaylistTrackService');
    
    const batchSize = 5;
    for (int i = 0; i < tracksNeedingDetails.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, tracksNeedingDetails.length);
      final batch = tracksNeedingDetails.sublist(i, end);
      
      for (final playlistTrack in batch) {
        fetchTrackDetailsIfNeeded(playlistTrack, authToken).then((trackDetails) {
          if (trackDetails != null) onTrackLoaded(playlistTrack, trackDetails);
        }).catchError((e) {
          AppLogger.error('Error fetching track ${playlistTrack.trackId}', e, null, 'PlaylistTrackService');
        });
      }
      
      if (end < tracksNeedingDetails.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    AppLogger.debug('Progressive fetch initiated for all tracks', 'PlaylistTrackService');
  }

  void clearFetchingState() => _fetchingTrackDetails.clear();
}

class PlaylistTimers {
  Timer? _autoRefreshTimer, _trackCountValidationTimer;
  
  final VoidCallback? onRefreshNeeded, onValidationNeeded, onStateUpdate;

  PlaylistTimers({this.onRefreshNeeded, this.onValidationNeeded, this.onStateUpdate});

  void startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final trackCacheService = getIt<TrackCacheService>();
      final webSocketService = getIt<WebSocketService>();
      
      if (trackCacheService.retryCount.isNotEmpty) {
        onRefreshNeeded?.call();
      } else if (!webSocketService.isConnected && timer.tick % 3 == 0) {
        onRefreshNeeded?.call();
      } else {
        onStateUpdate?.call();
      }
    });
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void startTrackCountValidation() {
    _trackCountValidationTimer = Timer.periodic(
      const Duration(seconds: 1), (_) => onValidationNeeded?.call());
  }

  void stopTrackCountValidation() {
    _trackCountValidationTimer?.cancel();
    _trackCountValidationTimer = null;
  }

  void dispose() {
    stopAutoRefresh();
    stopTrackCountValidation();
  }
}