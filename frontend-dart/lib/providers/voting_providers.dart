import '../core/navigation_core.dart';
import '../core/provider_core.dart';
import '../core/locator_core.dart';
import '../services/api_services.dart';
import '../models/api_models.dart';
import '../models/music_models.dart';
import '../models/voting_models.dart';
import 'package:dio/dio.dart';

class VotingService {
  final ApiService _api;
  
  VotingService(this._api);

  Future<VoteResponse> voteForTrack({required String playlistId, required int trackIndex, required String token}) async => 
    await _api.voteForTrack(playlistId, token, VoteRequest(rangeStart: trackIndex));
}

class VotingProvider extends BaseProvider {
  final VotingService _votingService = getIt<VotingService>();
  final Map<String, VoteStats> _trackVotes = {};
  Map<String, VoteStats> get trackVotes => Map.unmodifiable(_trackVotes);
  bool _canVote = true;
  bool get canVote => _canVote;
  bool _hasUserVotedForPlaylist = false;
  bool get hasUserVotedForPlaylist => _hasUserVotedForPlaylist;
  final Map<int, int> _trackPoints = {};
  Map<int, int> get trackPoints => Map.unmodifiable(_trackPoints);

  VoteStats? getTrackVotesByIndex(int index) => _trackVotes['track_$index'];

  void updateTrackPoints(int index, int points) {
    AppLogger.debug('Updating track $index points to $points', 'VotingProvider');
    _trackPoints[index] = points;
    _trackVotes['track_$index'] = VoteStats(
      totalVotes: points, upvotes: points, downvotes: 0,
      userHasVoted: _hasUserVotedForPlaylist,
      userVoteValue: _hasUserVotedForPlaylist ? 1 : null,
      voteScore: points.toDouble(),
    );
    notifyListeners();
  }

  void initializeTrackPoints(List<PlaylistTrack> tracks) {
    AppLogger.debug('Initializing track points for ${tracks.length} tracks', 'VotingProvider');
    _trackPoints.clear();
    _trackVotes.clear();
    for (int i = 0; i < tracks.length; i++) {
      final points = tracks[i].points;
      _trackPoints[i] = points;
      _trackVotes['track_$i'] = VoteStats(
        totalVotes: points, upvotes: points, downvotes: 0,
        userHasVoted: _hasUserVotedForPlaylist,
        userVoteValue: _hasUserVotedForPlaylist ? 1 : null,
        voteScore: points.toDouble(),
      );
      AppLogger.debug('Track $i (${tracks[i].name}): $points points', 'VotingProvider');
    }
    notifyListeners();
  }

  void setVotingPermission(bool canVote) {
    AppLogger.debug('Setting voting permission to: $canVote', 'VotingProvider');
    _canVote = canVote;
    notifyListeners();
  }

  void updateVotingEligibilityFromPlaylist(Playlist playlist) {
    AppLogger.debug('Updating voting eligibility for playlist license: ${playlist.licenseType}', 'VotingProvider');
    
    switch (playlist.licenseType) {
      case 'open': setVotingPermission(true); break;
      case 'invite_only': AppLogger.debug('Invite-only playlist detected - voting eligibility depends on backend invitation status', 'VotingProvider'); break;
      case 'location_time': AppLogger.debug('Location/time restricted playlist detected - voting eligibility depends on backend validation', 'VotingProvider'); break;
      default: AppLogger.warning('Unknown license type: ${playlist.licenseType}', 'VotingProvider'); setVotingPermission(false);
    }
  }

  Future<bool> voteForTrackByIndex({
    required String playlistId,
    required int trackIndex,
    required String token,
    String? playlistOwnerId,
    String? currentUserId,
    String? currentUsername,
  }) async {
    AppLogger.debug('[VoteForTrackByIndex] called - playlistId: $playlistId, trackIndex: $trackIndex, canVote: $canVote, hasUserVoted: $_hasUserVotedForPlaylist', 'VotingProvider');
    AppLogger.debug('[VoteForTrackByIndex] playlistOwnerId: $playlistOwnerId, currentUsername: $currentUsername, currentUserId: $currentUserId', 'VotingProvider');
    
    if (!canVote) {
      AppLogger.warning('Voting not allowed - canVote: $canVote', 'VotingProvider');
      setError('Voting not allowed');
      return false;
    }
    if (_hasUserVotedForPlaylist) {
      AppLogger.warning('User has already voted for playlist', 'VotingProvider');
      setError('You have already voted for this playlist');
      return false;
    }
    
    AppLogger.debug('Proceeding with vote for track at index $trackIndex', 'VotingProvider');
    
    try {
      AppLogger.debug('[VoteForTrackByIndex] Attempting initial vote...', 'VotingProvider');
      final response = await _votingService.voteForTrack(
        playlistId: playlistId,
        trackIndex: trackIndex,
        token: token
      );
      
      _hasUserVotedForPlaylist = true;
      
      if (response.playlist.isNotEmpty) {
        _updateVotingDataFromPlaylist(response.playlist);
        AppLogger.info('Updated voting data from backend response', 'VotingProvider');
      } else {
        final currentPoints = _trackPoints[trackIndex] ?? 0;
        final newPoints = currentPoints + 1;
        updateTrackPoints(trackIndex, newPoints);
        AppLogger.info('Vote successful for track $trackIndex, incremented points locally to $newPoints', 'VotingProvider');
      }
      
      setSuccess('Vote recorded!');
      return true;
      
    } catch (e) {
      AppLogger.debug('[VoteForTrackByIndex] Initial vote failed: $e', 'VotingProvider');
      final errorString = e.toString().toLowerCase();
      
      String? responseDetail;
      if (e.toString().contains('detail')) {
        final match = RegExp(r'"detail":\s*"([^"]+)"').firstMatch(e.toString());
        responseDetail = match?.group(1)?.toLowerCase();
        AppLogger.debug('[VoteForTrackByIndex] Extracted response detail: $responseDetail', 'VotingProvider');
      }
      
      if (e is DioException && e.response?.data != null) {
        try {
          final responseData = e.response!.data;
          if (responseData is Map<String, dynamic> && responseData['detail'] != null) {
            responseDetail = responseData['detail'].toString().toLowerCase();
            AppLogger.debug('[VoteForTrackByIndex] Direct extraction from DioException: $responseDetail', 'VotingProvider');
          }
        } catch (extractError) {
          AppLogger.debug('[VoteForTrackByIndex] Failed to extract from DioException: $extractError', 'VotingProvider');
        }
      }
      
      bool isNotInvitedError = errorString.contains('not invited') || (responseDetail != null && responseDetail.contains('not invited'));
      
      AppLogger.debug('[VoteForTrackByIndex] Error analysis: errorString="$errorString", responseDetail="$responseDetail", isNotInvitedError=$isNotInvitedError', 'VotingProvider');
      
      if (isNotInvitedError) {
        
        AppLogger.debug('[VoteForTrackByIndex] Not invited error detected - checking if user is playlist owner', 'VotingProvider');
        AppLogger.debug('[VoteForTrackByIndex] Owner check: playlistOwnerId="$playlistOwnerId", currentUsername="$currentUsername", equal=${playlistOwnerId == currentUsername}', 'VotingProvider');
        
        if (playlistOwnerId != null && playlistOwnerId.isNotEmpty && currentUsername != null && currentUsername.isNotEmpty && 
            currentUserId != null && currentUserId.isNotEmpty && playlistOwnerId == currentUsername) {
          
          AppLogger.info('[VoteForTrackByIndex] Playlist owner not invited to own playlist - auto-inviting and retrying vote', 'VotingProvider');
          
          try {
            final apiService = getIt<ApiService>();
            await apiService.inviteUserToPlaylist(playlistId, token, InviteUserRequest(userId: currentUserId));
            AppLogger.info('[VoteForTrackByIndex] Successfully auto-invited playlist owner', 'VotingProvider');
            
            final retryResponse = await _votingService.voteForTrack(playlistId: playlistId, trackIndex: trackIndex, token: token);
            
            _hasUserVotedForPlaylist = true;
            
            if (retryResponse.playlist.isNotEmpty) {
              _updateVotingDataFromPlaylist(retryResponse.playlist);
              AppLogger.info('Updated voting data from backend response after auto-invite', 'VotingProvider');
            } else {
              final currentPoints = _trackPoints[trackIndex] ?? 0;
              final newPoints = currentPoints + 1;
              updateTrackPoints(trackIndex, newPoints);
              AppLogger.info('Vote successful after auto-invite for track $trackIndex, incremented points locally to $newPoints', 'VotingProvider');
            }
            
            setSuccess('Vote recorded! (Auto-invited to playlist)');
            return true;
            
          } catch (inviteError) {
            AppLogger.error('[VoteForTrackByIndex] Failed to auto-invite playlist owner: $inviteError', 'VotingProvider');
            setError('Failed to auto-invite playlist owner. Please try again.');
            return false;
          }
        } else {
          AppLogger.warning('User not playlist owner or missing IDs - playlistOwnerId: $playlistOwnerId, currentUsername: $currentUsername', 'VotingProvider');
          setError('You are not invited to vote on this playlist');
          _canVote = false;
          return false;
        }
      } 
      
      if (errorString.contains('already voted')) {
        _hasUserVotedForPlaylist = true;
        AppLogger.warning('Backend confirmed user already voted', 'VotingProvider');
        setError('You have already voted for this playlist');
      } else if (errorString.contains('not allowed at this time') || errorString.contains('time window')) {
        setError('Voting is not allowed at this time'); _canVote = false;
        AppLogger.warning('Voting outside allowed time window', 'VotingProvider');
      } else if (errorString.contains('not within') || errorString.contains('voting area')) {
        setError('You are not within the allowed voting area'); _canVote = false;
        AppLogger.warning('User outside allowed voting area', 'VotingProvider');
      } else if (errorString.contains('location is missing')) {
        setError('Location is required for voting'); _canVote = false;
        AppLogger.warning('User location missing for location-based voting', 'VotingProvider');
      } else if (errorString.contains('time window not configured') || errorString.contains('location settings not configured')) {
        setError('Playlist voting settings not configured properly'); _canVote = false;
        AppLogger.error('Playlist license settings incomplete', 'VotingProvider');
      } else if (errorString.contains('not allowed') || errorString.contains('permission')) {
        setError('Voting not permitted'); _canVote = false;
        AppLogger.warning('Backend rejected vote due to permissions/license', 'VotingProvider');
      } else if (errorString.contains('invalid track')) {
        setError('Invalid track selection');
        AppLogger.error('Invalid track index sent to backend: $trackIndex', 'VotingProvider');
      } else {
        AppLogger.error('Vote failed with error', e, null, 'VotingProvider');
        setError('Voting failed. Please try again.');
      }
      
      return false;
    }
  }

  void _updateVotingDataFromPlaylist(List<PlaylistInfoWithVotes> playlistData) {
    AppLogger.debug('Updating voting data from ${playlistData.length} playlist(s)', 'VotingProvider');
    try {
      _trackVotes.clear();
      for (int i = 0; i < playlistData.length; i++) {
        final playlistInfo = playlistData[i];
        for (int j = 0; j < playlistInfo.tracks.length; j++) {
          final track = playlistInfo.tracks[j];
          final trackKey = 'track_$j';
          if (track.containsKey('points')) {
            final points = track['points'] as int? ?? 0;
            _trackPoints[j] = points;
            _trackVotes[trackKey] = VoteStats(
              totalVotes: points, upvotes: points, downvotes: 0,
              userHasVoted: _hasUserVotedForPlaylist,
              userVoteValue: _hasUserVotedForPlaylist ? 1 : null,
              voteScore: points.toDouble(),
            );
            AppLogger.debug('Updated track $j: $points points, voted: $_hasUserVotedForPlaylist', 'VotingProvider');
          } else {
            _trackVotes[trackKey] = VoteStats(
              totalVotes: 0, upvotes: 0, downvotes: 0,
              userHasVoted: _hasUserVotedForPlaylist,
              userVoteValue: _hasUserVotedForPlaylist ? 1 : null,
              voteScore: 0.0,
            );
          }
        }
      }
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating voting data: ${e.toString()}', null, null, 'VotingProvider');
    }
  }

  void clearVotingData() {
    AppLogger.debug('Clearing all voting data', 'VotingProvider');
    _trackVotes.clear();
    _hasUserVotedForPlaylist = false;
    _trackPoints.clear();
    notifyListeners();
  }

  void setHasUserVotedForPlaylist(bool hasVoted) {
    AppLogger.debug('Setting user voted for playlist: $hasVoted', 'VotingProvider');
    _hasUserVotedForPlaylist = hasVoted;
    notifyListeners();
  }

  void refreshVotingData(List<PlaylistTrack> tracks) {
    AppLogger.debug('Refreshing voting data for ${tracks.length} tracks', 'VotingProvider');
    for (int i = 0; i < tracks.length; i++) {
      final points = tracks[i].points;
      if (_trackPoints[i] != points) {
        AppLogger.debug('Track $i points changed from ${_trackPoints[i]} to $points', 'VotingProvider');
        updateTrackPoints(i, points);
      }
    }
  }
}
