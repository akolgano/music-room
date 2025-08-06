import '../core/app_logger.dart';
import '../core/base_provider.dart';
import '../core/service_locator.dart';
import '../services/voting_service.dart';
import '../models/music_models.dart';
import '../models/voting_models.dart';

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

  VoteStats? getTrackVotes(String trackId) => _trackVotes[trackId];

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
        _hasUserVotedForPlaylist = true;
        final currentPoints = _trackPoints[trackIndex] ?? 0;
        final newPoints = currentPoints + 1;
        updateTrackPoints(trackIndex, newPoints);
        
        try {
          final response = await _votingService.voteForTrack(
            playlistId: playlistId,
            trackIndex: trackIndex,
            token: token
          );
          if (response.playlist.isNotEmpty) {
            _updateVotingDataFromPlaylist(response.playlist);
          }
          AppLogger.info('Vote successful for track $trackIndex, new points: $newPoints', 'VotingProvider');
        } catch (e) {
          AppLogger.error('Vote failed, reverting', e, null, 'VotingProvider');
          _hasUserVotedForPlaylist = false;
          updateTrackPoints(trackIndex, currentPoints);
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
              totalVotes: points.abs(),
              upvotes: points > 0 ? points : 0,
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

  void initializeVotingForPlaylist(List<PlaylistTrack> tracks) {
    AppLogger.debug('Initializing voting for playlist with ${tracks.length} tracks', 'VotingProvider');
    clearVotingData();
    initializeTrackPoints(tracks);
    _hasUserVotedForPlaylist = false;
    notifyListeners();
  }

  String getVotingStatusMessage() {
    if (_hasUserVotedForPlaylist) {
      return 'You have already voted on this playlist';
    }
    return _canVote ? 'Select a track to vote for' : 'Voting is not allowed';
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
