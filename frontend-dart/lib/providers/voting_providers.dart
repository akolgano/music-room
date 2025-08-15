import '../core/navigation_core.dart';
import '../core/provider_core.dart';
import '../core/locator_core.dart';
import '../services/api_services.dart';
import '../models/api_models.dart';
import '../models/music_models.dart';
import '../models/voting_models.dart';

class VotingService {
  final ApiService _api;
  
  VotingService(this._api);

  Future<VoteResponse> voteForTrack({ 
    required String playlistId, 
    required int trackIndex, 
    required String token 
  }) async {
    final request = VoteRequest(rangeStart: trackIndex);
    final response = await _api.voteForTrack(playlistId, token, request);
    return response;
  }
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

  VoteStats? getTrackVotesByIndex(int index) {
    final trackKey = 'track_$index';
    return _trackVotes[trackKey];
  }


  bool hasUserVotedByIndex(int index) {
    return _hasUserVotedForPlaylist;
  }

  int getTrackPoints(int index) {
    return _trackPoints[index] ?? 0;
  }

  void updateTrackPoints(int index, int points) {
    AppLogger.debug('Updating track $index points to $points', 'VotingProvider');
    _trackPoints[index] = points;
    final trackKey = 'track_$index';
    _trackVotes[trackKey] = VoteStats(
      totalVotes: points,
      upvotes: points,
      downvotes: 0,
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
      final trackKey = 'track_$i';
      _trackVotes[trackKey] = VoteStats(
        totalVotes: points,
        upvotes: points,
        downvotes: 0,
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
      case 'open':
        setVotingPermission(true);
        break;
      case 'invite_only':
        AppLogger.debug('Invite-only playlist detected - voting eligibility depends on backend invitation status', 'VotingProvider');
        break;
      case 'location_time':
        AppLogger.debug('Location/time restricted playlist detected - voting eligibility depends on backend validation', 'VotingProvider');
        break;
      default:
        AppLogger.warning('Unknown license type: ${playlist.licenseType}', 'VotingProvider');
        setVotingPermission(false);
    }
  }

  Future<bool> voteForTrackByIndex({
    required String playlistId,
    required int trackIndex,
    required String token
  }) async {
    AppLogger.debug('VoteForTrackByIndex called - playlistId: $playlistId, trackIndex: $trackIndex, canVote: $canVote, hasUserVoted: $_hasUserVotedForPlaylist', 'VotingProvider');
    
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
    return await executeBool(
      () async {
        try {
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
        } catch (e) {
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('already voted')) {
            _hasUserVotedForPlaylist = true;
            AppLogger.warning('Backend confirmed user already voted', 'VotingProvider');
            setError('You have already voted for this playlist');
          } else if (errorString.contains('not invited')) {
            setError('You are not invited to vote on this playlist');
            _canVote = false;
            AppLogger.warning('User not invited to vote on invite-only playlist', 'VotingProvider');
          } else if (errorString.contains('not allowed at this time') || errorString.contains('time window')) {
            setError('Voting is not allowed at this time');
            _canVote = false;
            AppLogger.warning('Voting outside allowed time window', 'VotingProvider');
          } else if (errorString.contains('not within') || errorString.contains('voting area')) {
            setError('You are not within the allowed voting area');
            _canVote = false;
            AppLogger.warning('User outside allowed voting area', 'VotingProvider');
          } else if (errorString.contains('location is missing')) {
            setError('Location is required for voting');
            _canVote = false;
            AppLogger.warning('User location missing for location-based voting', 'VotingProvider');
          } else if (errorString.contains('time window not configured') || errorString.contains('location settings not configured')) {
            setError('Playlist voting settings not configured properly');
            _canVote = false;
            AppLogger.error('Playlist license settings incomplete', 'VotingProvider');
          } else if (errorString.contains('not allowed') || errorString.contains('permission')) {
            setError('Voting not permitted');
            _canVote = false;
            AppLogger.warning('Backend rejected vote due to permissions/license', 'VotingProvider');
          } else if (errorString.contains('invalid track')) {
            setError('Invalid track selection');
            AppLogger.error('Invalid track index sent to backend: $trackIndex', 'VotingProvider');
          } else {
            AppLogger.error('Vote failed with error', e, null, 'VotingProvider');
          }
          rethrow;
        }
      },
      successMessage: 'Vote recorded!',
      errorMessage: 'Failed to submit vote',
    );
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
              totalVotes: points,
              upvotes: points,
              downvotes: 0,
              userHasVoted: _hasUserVotedForPlaylist,
              userVoteValue: _hasUserVotedForPlaylist ? 1 : null,
              voteScore: points.toDouble(),
            );
            AppLogger.debug('Updated track $j: $points points, voted: $_hasUserVotedForPlaylist', 'VotingProvider');
          } else {
            _trackVotes[trackKey] = VoteStats(
              totalVotes: 0,
              upvotes: 0,
              downvotes: 0,
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
