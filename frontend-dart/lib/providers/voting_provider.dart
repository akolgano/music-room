// lib/providers/voting_provider.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    if (kDebugMode) {
      developer.log('Updating track $index points to $points', name: 'VotingProvider');
    }
    _trackPoints[index] = points;
    final trackKey = 'track_$index';
    _trackVotes[trackKey] = VoteStats(
      totalVotes: points,
      upvotes: points,
      downvotes: 0,
      userHasVoted: _userVotesByIndex.containsKey(index),
      userVoteValue: _userVotesByIndex[index], voteScore: points.toDouble(),
    );
    notifyListeners();
  }

  void initializeTrackPoints(List<PlaylistTrack> tracks) {
    if (kDebugMode) {
      developer.log('Initializing track points for ${tracks.length} tracks', name: 'VotingProvider');
    }
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
        userHasVoted: _userVotesByIndex.containsKey(i),
        userVoteValue: _userVotesByIndex[i],
        voteScore: points.toDouble(),
      );
      if (kDebugMode) {
        developer.log('Track $i (${tracks[i].name}): ${points} points', name: 'VotingProvider');
      }
    }
    notifyListeners();
  }

  void setVotingPermission(bool canVote) {
    if (kDebugMode) {
      developer.log('Setting voting permission to: $canVote', name: 'VotingProvider');
    }
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
    if (kDebugMode) {
      developer.log('Voting for track at index $trackIndex', name: 'VotingProvider');
    }
    return await executeBool(
      () async {
        _userVotesByIndex[trackIndex] = 1;
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
          if (kDebugMode) {
            developer.log('Vote successful for track $trackIndex, new points: $newPoints', name: 'VotingProvider');
          }
        } catch (e) {
          if (kDebugMode) {
            developer.log('Vote failed, reverting: $e', name: 'VotingProvider');
          }
          _userVotesByIndex.remove(trackIndex);
          updateTrackPoints(trackIndex, currentPoints);
          rethrow;
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

  Future<bool> upvoteTrack(String playlistId, String trackId, String token) async {
    int trackIndex = 0;
    if (trackId.startsWith('track_')) {
      trackIndex = int.tryParse(trackId.split('_').last) ?? 0;
    }
    return await voteForTrackByIndex(
      playlistId: playlistId,
      trackIndex: trackIndex,
      token: token
    );
  }

  void _updateVotingDataFromPlaylist(List<PlaylistInfoWithVotes> playlistData) {
    if (kDebugMode) {
      developer.log('Updating voting data from ${playlistData.length} playlist(s)', name: 'VotingProvider');
    }
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
            final userHasVoted = _userVotesByIndex.containsKey(j);
            final userVoteValue = _userVotesByIndex[j];
            _trackVotes[trackKey] = VoteStats(
              totalVotes: points.abs(),
              upvotes: points > 0 ? points : 0,
              downvotes: 0,
              userHasVoted: userHasVoted,
              userVoteValue: userVoteValue,
              voteScore: points.toDouble(),
            );
            if (kDebugMode) {
              developer.log('Updated track $j: $points points, voted: $userHasVoted', name: 'VotingProvider');
            }
          } else {
            _trackVotes[trackKey] = VoteStats(
              totalVotes: 0,
              upvotes: 0,
              downvotes: 0,
              userHasVoted: _userVotesByIndex.containsKey(j),
              userVoteValue: _userVotesByIndex[j],
              voteScore: 0.0,
            );
          }
        }
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error updating voting data: $e', name: 'VotingProvider');
      }
    }
  }

  void clearVotingData() {
    if (kDebugMode) {
      developer.log('Clearing all voting data', name: 'VotingProvider');
    }
    _trackVotes.clear();
    _userVotesByIndex.clear();
    _trackPoints.clear();
    notifyListeners();
  }

  String getVotingStatusMessage() {
    return _canVote ? 'You can vote on this playlist' : 'Voting is not allowed';
  }

  void setUserVote(int trackIndex, int voteValue) {
    if (kDebugMode) {
      developer.log('Setting user vote for track $trackIndex: $voteValue', name: 'VotingProvider');
    }
    if (voteValue <= 0) {
      if (kDebugMode) {
        developer.log('Invalid vote value: $voteValue', name: 'VotingProvider');
      }
      return;
    }
    _userVotesByIndex[trackIndex] = voteValue;
    final trackKey = 'track_$trackIndex';
    final currentPoints = _trackPoints[trackIndex] ?? 0;
    final newPoints = currentPoints + voteValue;
    _trackPoints[trackIndex] = newPoints;
    final currentStats = _trackVotes[trackKey];
    _trackVotes[trackKey] = VoteStats(
      totalVotes: (currentStats?.totalVotes ?? 0) + 1,
      upvotes: voteValue > 0 ? (currentStats?.upvotes ?? 0) + 1 : (currentStats?.upvotes ?? 0),
      downvotes: 0, 
      userHasVoted: true,
      userVoteValue: voteValue,
      voteScore: newPoints.toDouble(),
    );
    notifyListeners();
  }

  int getTotalPoints() {
    return _trackPoints.values.fold(0, (sum, points) => sum + points);
  }

  List<int> getVotedTrackIndices() {
    return _trackPoints.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
  }

  void refreshVotingData(List<PlaylistTrack> tracks) {
    if (kDebugMode) {
      developer.log('Refreshing voting data for ${tracks.length} tracks', name: 'VotingProvider');
    }
    for (int i = 0; i < tracks.length; i++) {
      final points = tracks[i].points;
      if (_trackPoints[i] != points) {
        if (kDebugMode) {
          developer.log('Track $i points changed from ${_trackPoints[i]} to $points', name: 'VotingProvider');
        }
        updateTrackPoints(i, points);
      }
    }
  }
}
