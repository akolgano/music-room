// lib/providers/voting_provider.dart
import 'package:flutter/material.dart';
import '../core/base_provider.dart';
import '../core/service_locator.dart';
import '../services/voting_service.dart';
import '../models/voting_models.dart';
import '../models/models.dart';

class VotingProvider extends BaseProvider {
  final VotingService _votingService = getIt<VotingService>();

  Map<String, VoteStats> _trackVotes = {};
  Map<String, VoteStats> get trackVotes => Map.unmodifiable(_trackVotes);

  bool _canVote = true;
  bool get canVote => _canVote;

  Map<int, int> _userVotesByIndex = {};
  Map<int, int> _trackPoints = {};
  Map<int, int> get trackPoints => Map.unmodifiable(_trackPoints);

  VoteStats? getTrackVotes(String trackId) => _trackVotes[trackId];

  VoteStats? getTrackVotesByIndex(int index) {
    final trackKey = 'track_$index';
    return _trackVotes[trackKey];
  }

  bool hasUserVoted(String trackId) {
    final stats = _trackVotes[trackId];
    return stats?.userHasVoted ?? false;
  }

  bool hasUserVotedByIndex(int index) {
    return _userVotesByIndex.containsKey(index);
  }

  int? getUserVote(String trackId) {
    final stats = _trackVotes[trackId];
    return stats?.userVoteValue;
  }

  int? getUserVoteByIndex(int index) {
    return _userVotesByIndex[index];
  }

  int getTrackPoints(int index) {
    return _trackPoints[index] ?? 0;
  }

  void updateTrackPoints(int index, int points) {
    _trackPoints[index] = points;
    notifyListeners();
  }

  void initializeTrackPoints(List<PlaylistTrack> tracks) {
    _trackPoints.clear();
    for (int i = 0; i < tracks.length; i++) {
      _trackPoints[i] = tracks[i].points;
    }
    notifyListeners();
  }

  void setVotingPermission(bool canVote) {
    _canVote = canVote;
    notifyListeners();
  }

  Future<bool> voteForTrackByIndex({
    required String playlistId, 
    required int trackIndex, 
    required String token
  }) async {
    if (!canVote) {
      setError('Voting not allowed');
      return false;
    }

    if (_userVotesByIndex.containsKey(trackIndex)) {
      setError('You have already voted for this track');
      return false;
    }

    return await executeBool(
      () async {
        final response = await _votingService.voteForTrack(
          playlistId: playlistId, 
          trackIndex: trackIndex, 
          token: token
        );

        _userVotesByIndex[trackIndex] = 1; 

        if (response.playlist.isNotEmpty) {
          _updateVotingDataFromPlaylist(response.playlist);
        } else {
          final currentPoints = _trackPoints[trackIndex] ?? 0;
          _trackPoints[trackIndex] = currentPoints + 1;
        }
      },
      successMessage: 'Vote recorded!',
      errorMessage: 'Failed to submit vote',
    );
  }

  Future<bool> upvoteTrackByIndex(String playlistId, int trackIndex, String token) async {
    return await voteForTrackByIndex(playlistId: playlistId, trackIndex: trackIndex, token: token);
  }

  Future<bool> upvoteTrack(String playlistId, String trackId, String token) async {
    return await voteForTrackByIndex(playlistId: playlistId, trackIndex: 0, token: token);
  }

  Future<bool> removeVote(String playlistId, String trackId, String token) async {
    setError('Vote removal is not currently supported');
    return false;
  }

  void _updateVotingDataFromPlaylist(List<PlaylistInfoWithVotes> playlistData) {
    _trackVotes.clear();
    _trackPoints.clear();

    for (int i = 0; i < playlistData.length; i++) {
      final playlistInfo = playlistData[i];
      for (int j = 0; j < playlistInfo.tracks.length; j++) {
        final track = playlistInfo.tracks[j];
        final trackKey = 'track_$j';

        if (track.containsKey('points')) {
          final points = track['points'] as int? ?? 0;
          _trackPoints[j] = points; 

          final userHasVoted = _userVotesByIndex.containsKey(j);
          final userVoteValue = _userVotesByIndex[j];

          _trackVotes[trackKey] = VoteStats(
            totalVotes: points.abs(), upvotes: points > 0 ? points : 0, downvotes: 0, 
            userHasVoted: userHasVoted,
            userVoteValue: userVoteValue,
            voteScore: points.toDouble(),
          );
        } else {
          _trackVotes[trackKey] = VoteStats(
            totalVotes: 0, upvotes: 0, downvotes: 0,
            userHasVoted: _userVotesByIndex.containsKey(j),
            userVoteValue: _userVotesByIndex[j], voteScore: 0.0,
          );
        }
      }
    }
    notifyListeners();
  }

  void clearVotingData() {
    _trackVotes.clear();
    _userVotesByIndex.clear();
    _trackPoints.clear(); 
    notifyListeners();
  }

  String getVotingStatusMessage() {
    return _canVote ? 'You can vote on this playlist' : 'Voting is not allowed';
  }

  void setUserVote(int trackIndex, int voteValue) {
    _userVotesByIndex[trackIndex] = voteValue;
    final trackKey = 'track_$trackIndex';
    final currentPoints = _trackPoints[trackIndex] ?? 0;
    _trackPoints[trackIndex] = currentPoints + voteValue;

    final currentStats = _trackVotes[trackKey];
    if (currentStats != null) {
      _trackVotes[trackKey] = VoteStats(
        totalVotes: currentStats.totalVotes + 1,
        upvotes: voteValue > 0 ? currentStats.upvotes + 1 : currentStats.upvotes, downvotes: 0, 
        userHasVoted: true,
        userVoteValue: voteValue, 
        voteScore: currentStats.voteScore + voteValue,
      );
    }
    notifyListeners();
  }
}
