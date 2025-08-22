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
import '../core/logging_core.dart';

class PlaylistVotingService {
  final String playlistId;
  
  bool _isPublicVoting = true;
  String _votingLicenseType = 'open';
  DateTime? _votingStartTime;
  DateTime? _votingEndTime;
  PlaylistVotingInfo? _votingInfo;
  double? _latitude;
  double? _longitude;
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

  void setPublicVoting(bool value) => _isPublicVoting = value;
  void setVotingLicenseType(String value) => _votingLicenseType = value;
  void setVotingStartTime(DateTime? value) => _votingStartTime = value;
  void setVotingEndTime(DateTime? value) => _votingEndTime = value;

  Future<void> applyVotingSettings(String authToken) async {
    try {
      String? voteStartTimeStr;
      String? voteEndTimeStr;
      
      if (_votingLicenseType == 'location_time') {
        if (_votingStartTime != null) {
          voteStartTimeStr = '${_votingStartTime!.hour.toString().padLeft(2, '0')}:${_votingStartTime!.minute.toString().padLeft(2, '0')}:${_votingStartTime!.second.toString().padLeft(2, '0')}';
        }
        if (_votingEndTime != null) {
          voteEndTimeStr = '${_votingEndTime!.hour.toString().padLeft(2, '0')}:${_votingEndTime!.minute.toString().padLeft(2, '0')}:${_votingEndTime!.second.toString().padLeft(2, '0')}';
        }
      }

      final request = PlaylistLicenseRequest(
        licenseType: _votingLicenseType,
        invitedUsers: _votingLicenseType != 'open' ? [] : null,
        voteStartTime: voteStartTimeStr,
        voteEndTime: voteEndTimeStr,
        latitude: _votingLicenseType == 'location_time' ? _latitude : null,
        longitude: _votingLicenseType == 'location_time' ? _longitude : null,
        allowedRadiusMeters: _votingLicenseType == 'location_time' ? _allowedRadiusMeters : null,
      );

      final apiService = getIt<ApiService>();
      await apiService.updatePlaylistLicense(playlistId, authToken, request);
      
      await loadVotingSettings(authToken);
      
      _votingInfo = PlaylistVotingInfo(
        playlistId: playlistId,
        restrictions: VotingRestrictions(
          licenseType: _votingLicenseType,
          isInvited: true,
          isInTimeWindow: _votingLicenseType != 'location_time' || _isInVotingTimeWindow(),
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
    if (!isOwner) {
      _votingLicenseType = 'open';
      _isPublicVoting = true;
      AppLogger.info('Skipping voting settings for non-owner', 'PlaylistVotingService');
      return;
    }
    
    try {
      final apiService = getIt<ApiService>();
      final licenseResponse = await apiService.getPlaylistLicense(playlistId, authToken);
      
      _votingLicenseType = licenseResponse.licenseType;
      
      if (licenseResponse.voteStartTime != null) {
        final timeStr = licenseResponse.voteStartTime!;
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final second = timeParts.length > 2 ? (int.tryParse(timeParts[2]) ?? 0) : 0;
          _votingStartTime = DateTime(2000, 1, 1, hour, minute, second);
        }
      }
      if (licenseResponse.voteEndTime != null) {
        final timeStr = licenseResponse.voteEndTime!;
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final second = timeParts.length > 2 ? (int.tryParse(timeParts[2]) ?? 0) : 0;
          _votingEndTime = DateTime(2000, 1, 1, hour, minute, second);
        }
      }
      
      _latitude = licenseResponse.latitude;
      _longitude = licenseResponse.longitude;
      _allowedRadiusMeters = licenseResponse.allowedRadiusMeters;
      
      _isPublicVoting = licenseResponse.licenseType == 'open';
      
      AppLogger.info('Successfully loaded voting settings: ${licenseResponse.licenseType}', 'PlaylistVotingService');
      
    } catch (e) {
      AppLogger.error('Failed to load voting settings: $e', null, null, 'PlaylistVotingService');
      rethrow;
    }
  }

  bool _isInVotingTimeWindow() {
    final now = DateTime.now();
    if (_votingStartTime != null && now.isBefore(_votingStartTime!)) return false;
    if (_votingEndTime != null && now.isAfter(_votingEndTime!)) return false;
    return true;
  }

  Future<DateTime?> selectVotingDateTime(BuildContext context, bool isStartTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

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

  bool needsTrackDetailsFetch(Track? track) {
    return track?.deezerTrackId != null && 
           _trackHasMissingDetails(track) &&
           !_fetchingTrackDetails.contains(track!.deezerTrackId!);
  }

  bool _trackHasMissingDetails(Track? track) {
    return track?.artist.isEmpty == true || track?.album.isEmpty == true;
  }

  bool shouldSkipTrackDetailsFetch(String? deezerTrackId, Track? track) {
    return deezerTrackId == null || 
           _fetchingTrackDetails.contains(deezerTrackId) || 
           (track != null && !_trackHasMissingDetails(track));
  }

  Future<Track?> fetchTrackDetailsIfNeeded(PlaylistTrack playlistTrack, String authToken) async {
    final track = playlistTrack.track;
    final deezerTrackId = track?.deezerTrackId;
    
    if (shouldSkipTrackDetailsFetch(deezerTrackId, track)) {
      return null;
    }

    final nonNullDeezerTrackId = deezerTrackId!;
    _fetchingTrackDetails.add(nonNullDeezerTrackId);
    
    try {
      final trackDetails = await _trackCacheService.getTrackDetails(
        nonNullDeezerTrackId, 
        authToken, 
        _apiService
      );
      
      return trackDetails;
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
    
    final futures = tracksNeedingDetails.map((playlistTrack) {
      return fetchTrackDetailsIfNeeded(playlistTrack, authToken); 
    }).toList();
    
    try {
      final results = await Future.wait(futures);
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
      final end = (i + batchSize < tracksNeedingDetails.length) 
          ? i + batchSize 
          : tracksNeedingDetails.length;
      final batch = tracksNeedingDetails.sublist(i, end);
      
      for (final playlistTrack in batch) {
        fetchTrackDetailsIfNeeded(playlistTrack, authToken).then((trackDetails) {
          if (trackDetails != null) {
            onTrackLoaded(playlistTrack, trackDetails);
          }
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

  void clearFetchingState() {
    _fetchingTrackDetails.clear();
  }
}

class PlaylistTimers {
  Timer? _autoRefreshTimer;
  Timer? _trackCountValidationTimer;
  
  final VoidCallback? onRefreshNeeded;
  final VoidCallback? onValidationNeeded;
  final VoidCallback? onStateUpdate;

  PlaylistTimers({
    this.onRefreshNeeded,
    this.onValidationNeeded, 
    this.onStateUpdate,
  });

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
    _trackCountValidationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      onValidationNeeded?.call();
    });
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