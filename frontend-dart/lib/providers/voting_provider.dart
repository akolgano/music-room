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
    final stats = getTrackVotesByIndex(index);
    return stats?.userHasVoted ?? false;
  }
  
  int? getUserVote(String trackId) {
    final stats = _trackVotes[trackId];
    return stats?.userVoteValue;
  }
  
  int? getUserVoteByIndex(int index) {
    final stats = getTrackVotesByIndex(index);
    return stats?.userVoteValue;
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
    
    return await executeBool(
      () async {
        final response = await _votingService.voteForTrack(
          playlistId: playlistId, 
          trackIndex: trackIndex, 
          token: token
        );
        
        if (response.playlist.isNotEmpty) {
          _updateVotingDataFromPlaylist(response.playlist);
        }
      },
      successMessage: 'Vote recorded!',
      errorMessage: 'Failed to submit vote',
    );
  }

  Future<bool> upvoteTrackByIndex(String playlistId, int trackIndex, String token) async {
    return await voteForTrackByIndex(
      playlistId: playlistId, 
      trackIndex: trackIndex, 
      token: token
    );
  }

  Future<bool> downvoteTrackByIndex(String playlistId, int trackIndex, String token) async {
    return await voteForTrackByIndex(
      playlistId: playlistId, 
      trackIndex: trackIndex, 
      token: token
    );
  }

  Future<bool> voteForTrack({
    required String playlistId, 
    required String trackId, 
    required int voteValue, 
    required String token
  }) async {
    return await voteForTrackByIndex(
      playlistId: playlistId,
      trackIndex: 0, 
      token: token
    );
  }

  Future<bool> upvoteTrack(String playlistId, String trackId, String token) async {
    return await voteForTrack(
      playlistId: playlistId, 
      trackId: trackId, 
      voteValue: 1, 
      token: token
    );
  }

  Future<bool> downvoteTrack(String playlistId, String trackId, String token) async {
    return await voteForTrack(
      playlistId: playlistId, 
      trackId: trackId, 
      voteValue: -1, 
      token: token
    );
  }

  Future<bool> removeVote(String playlistId, String trackId, String token) async {
    return await voteForTrack(
      playlistId: playlistId, 
      trackId: trackId, 
      voteValue: 0, 
      token: token
    );
  }

  void _updateVotingDataFromPlaylist(List<PlaylistInfoWithVotes> playlistData) {
    _trackVotes.clear();
    for (int i = 0; i < playlistData.length; i++) {
      final playlistInfo = playlistData[i];
      for (int j = 0; j < playlistInfo.tracks.length; j++) {
        final track = playlistInfo.tracks[j];
        final trackKey = 'track_$j';
        if (track.containsKey('points')) {
          final points = track['points'] as int? ?? 0;
          _trackVotes[trackKey] = VoteStats(
            totalVotes: points.abs(),
            upvotes: points > 0 ? points : 0,
            downvotes: points < 0 ? points.abs() : 0,
            userHasVoted: false, 
            userVoteValue: null, 
            voteScore: points.toDouble(),
          );
        }
      }
    }
    notifyListeners();
  }

  void clearVotingData() {
    _trackVotes.clear();
    notifyListeners();
  }

  String getVotingStatusMessage() {
    return _canVote ? 'You can vote on this playlist' : 'Voting is not allowed';
  }
}
