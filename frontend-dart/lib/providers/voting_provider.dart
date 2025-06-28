// lib/providers/voting_provider.dart
import 'package:flutter/material.dart';
import '../core/base_provider.dart';
import '../core/service_locator.dart';
import '../services/voting_service.dart';
import '../models/voting_models.dart';

class VotingProvider extends BaseProvider {
  final VotingService _votingService = getIt<VotingService>();
  
  PlaylistVotingInfo? _currentPlaylistVotingInfo;
  Map<String, VoteStats> _trackVotes = {};
  VotingRestrictions? _votingRestrictions;

  PlaylistVotingInfo? get currentPlaylistVotingInfo => _currentPlaylistVotingInfo;
  Map<String, VoteStats> get trackVotes => Map.unmodifiable(_trackVotes);
  VotingRestrictions? get votingRestrictions => _votingRestrictions;
  
  bool get canVote => _votingRestrictions?.permission == VotingPermission.allowed;
  
  VoteStats? getTrackVotes(String trackId) => _trackVotes[trackId];
  
  bool hasUserVoted(String trackId) {
    final stats = _trackVotes[trackId];
    return stats?.userHasVoted ?? false;
  }
  
  int? getUserVote(String trackId) {
    final stats = _trackVotes[trackId];
    return stats?.userVoteValue;
  }

  Future<void> loadPlaylistVotingInfo(String playlistId, String token) async {
    await executeAsync(
      () async {
        _currentPlaylistVotingInfo = await _votingService.getPlaylistVotingInfo(playlistId, token);
        if (_currentPlaylistVotingInfo != null) {
          _trackVotes = _currentPlaylistVotingInfo!.trackVotes;
          _votingRestrictions = _currentPlaylistVotingInfo!.restrictions;
        }
      },
      errorMessage: 'Failed to load voting information',
    );
  }

  Future<void> loadVotingRestrictions(String playlistId, String token) async {
    await executeAsync(
      () async {
        _votingRestrictions = await _votingService.getVotingRestrictions(playlistId, token);
      },
      errorMessage: 'Failed to load voting restrictions',
    );
  }

  Future<void> loadTrackVotes(String playlistId, String token) async {
    await executeAsync(
      () async {
        _trackVotes = await _votingService.getTrackVotes(playlistId, token);
      },
      errorMessage: 'Failed to load track votes',
    );
  }

  Future<bool> voteForTrack({required String playlistId, required String trackId, required int voteValue, required String token}) async {
    if (!canVote) {
      setError(_votingRestrictions?.restrictionMessage ?? 'Voting not allowed');
      return false;
    }

    return await executeBool(
      () async {
        final response = await _votingService.voteForTrack(playlistId: playlistId, trackId: trackId, voteValue: voteValue, token: token);
        
        _trackVotes[trackId] = response.stats;
      },
      successMessage: voteValue == 0 ? 'Vote removed' : voteValue > 0 ? 'Upvoted!' : 'Downvoted!',
      errorMessage: 'Failed to submit vote',
    );
  }

  Future<bool> upvoteTrack(String playlistId, String trackId, String token) async {
    final currentVote = getUserVote(trackId);
    final newVote = currentVote == 1 ? 0 : 1; 
    
    return await voteForTrack(playlistId: playlistId, trackId: trackId, voteValue: newVote, token: token);
  }

  Future<bool> downvoteTrack(String playlistId, String trackId, String token) async {
    final currentVote = getUserVote(trackId);
    final newVote = currentVote == -1 ? 0 : -1; 
    
    return await voteForTrack(
      playlistId: playlistId,
      trackId: trackId,
      voteValue: newVote,
      token: token,
    );
  }

  Future<bool> removeVote(String playlistId, String trackId, String token) async {
    return await voteForTrack(
      playlistId: playlistId,
      trackId: trackId,
      voteValue: 0,
      token: token,
    );
  }

  void clearVotingData() {
    _currentPlaylistVotingInfo = null;
    _trackVotes.clear();
    _votingRestrictions = null;
    notifyListeners();
  }

  String getVotingStatusMessage() {
    if (_votingRestrictions == null) return 'Loading voting information...';
    
    return _votingRestrictions!.restrictionMessage;
  }
}
