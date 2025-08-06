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
    print('VotingService: Making vote API call - playlistId: $playlistId, trackIndex: $trackIndex');
    final request = VoteRequest(rangeStart: trackIndex);
    final response = await _api.voteForTrack(playlistId, token, request);
    print('VotingService: Vote API call successful');
    return response;
  }
}
