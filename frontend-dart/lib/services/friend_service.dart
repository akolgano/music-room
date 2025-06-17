// lib/services/friend_service.dart
import '../services/api_service.dart';
import '../models/api_models.dart';

class FriendService {
  final ApiService _api;

  FriendService(this._api);

  Future<List<int>> getFriends(String token) async {
    final response = await _api.getFriends('Token $token');
    return response.friends;
  }

  Future<String> sendFriendRequest(int userId, String token) async {
    final request = FriendRequestRequest(userId: userId);
    final response = await _api.sendFriendRequest('Token $token', request);
    return response.message;
  }

  Future<List<Map<String, dynamic>>> getPendingFriendRequests(String token) async {
    final response = await _api.getPendingFriendRequests('Token $token');
    return response.requests;
  }

  Future<String> acceptFriendRequest(int friendshipId, String token) async {
    final request = FriendRequestActionRequest(friendshipId: friendshipId);
    final response = await _api.acceptFriendRequest('Token $token', request);
    return response.message;
  }

  Future<String> rejectFriendRequest(int friendshipId, String token) async {
    final request = FriendRequestActionRequest(friendshipId: friendshipId);
    final response = await _api.rejectFriendRequest('Token $token', request);
    return response.message;
  }

  Future<void> removeFriend(int friendId, String token) async {
    final request = RemoveFriendRequest(friendId: friendId);
    await _api.removeFriend('Token $token', request);
  }
}
