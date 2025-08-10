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

  void initializeVotingForPlaylist(List<PlaylistTrack> tracks) {
    initializeTrackPoints(tracks);
  }

  void setVotingPermission(bool canVote) {
    AppLogger.debug('Setting voting permission to: $canVote', 'VotingProvider');
    _canVote = canVote;
    notifyListeners();
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
          final currentPoints = _trackPoints[trackIndex] ?? 0;
          final newPoints = currentPoints + 1;
          updateTrackPoints(trackIndex, newPoints);
          
          if (response.playlist.isNotEmpty) {
            _updateVotingDataFromPlaylist(response.playlist);
          }
          AppLogger.info('Vote successful for track $trackIndex, new points: $newPoints', 'VotingProvider');
        } catch (e) {
          AppLogger.error('Vote failed', e, null, 'VotingProvider');
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
