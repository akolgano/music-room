// lib/services/voting_service.dart
import '../services/api_service.dart';
import '../models/voting_models.dart';
import '../models/api_models.dart';

class VotingService {
  final ApiService _api;
  VotingService(this._api);

  Future<VoteResponse> voteForTrack({required String playlistId, required String trackId, required int voteValue, required String token,
  }) async {
    final request = VoteRequest(trackId: trackId, voteValue: voteValue);
    return await _api.voteForTrack(playlistId, token, request); 
  }

  Future<PlaylistVotingInfo> getPlaylistVotingInfo(String playlistId, String token) async {
    return await _api.getPlaylistVotingInfo(playlistId, token); 
  }

  Future<VotingRestrictions> getVotingRestrictions(String playlistId, String token) async {
    return await _api.getVotingRestrictions(playlistId, token); 
  }

  Future<Map<String, VoteStats>> getTrackVotes(String playlistId, String token) async {
    return await _api.getTrackVotes(playlistId, token); 
  }

  Future<VoteStats?> getTrackVoteStats({required String playlistId, required String trackId, required String token}) async {
    try {
      final allVotes = await getTrackVotes(playlistId, token);
      return allVotes[trackId];
    } catch (e) {
      print('Error getting track vote stats: $e');
      return null;
    }
  }
}
