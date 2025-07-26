import '../services/api_service.dart';
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
}
