import '../services/api_service.dart';

class FriendService {
  final ApiService _api;
  FriendService(this._api);

  Future<List<String>> getFriends(String token) async {
    final response = await _api.getFriends(token); 
    return response.friends;
  }

  Future<String> sendFriendRequest(String userId, String token) async {
    final response = await _api.sendFriendRequest(userId, token); 
    return response.message;
  }

  Future<String> acceptFriendRequest(String friendshipId, String token) async {
    final response = await _api.acceptFriendRequest(friendshipId, token); 
    return response.message;
  }

  Future<String> rejectFriendRequest(String friendshipId, String token) async {
    final response = await _api.rejectFriendRequest(friendshipId, token); 
    return response.message;
  }

  Future<void> removeFriend(String friendId, String token) async {
    await _api.removeFriend(friendId, token); 
  }

  Future<List<Map<String, dynamic>>> getReceivedInvitations(String token) async {
    final response = await _api.getReceivedInvitations(token);
    return response.invitations;
  }

  Future<List<Map<String, dynamic>>> getSentInvitations(String token) async {
    final response = await _api.getSentInvitations(token);
    return response.invitations;
  }
}
