// lib/services/voting_service.dart
import '../services/api_service.dart';
import '../models/voting_models.dart';
import '../models/api_models.dart';

class VotingService {
  final ApiService _api;
  VotingService(this._api);

  Future<VoteResponse> voteForTrack({ 
    required String playlistId, 
    required int trackIndex, 
    required String token 
  }) async {
    final request = VoteRequest(rangeStart: trackIndex);
    return await _api.voteForTrack(playlistId, token, request);
  }

  Future<bool> canUserVote({
    required String playlistId,
    required String token,
  }) async {
    try {
      return true;
    } catch (e) {
      return true;
    }
  }

  Future<Map<String, VoteStats>> getPlaylistVotingStats({
    required String playlistId,
    required String token,
  }) async {
    return {};
  }
}
