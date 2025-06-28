// lib/services/friend_service.dart
import '../services/api_service.dart';
import '../models/api_models.dart';

class FriendService {
  final ApiService _api;
  
  FriendService(this._api);

  Future<List<int>> getFriends(String token) async {
    final response = await _api.getFriends(token); 
    return response.friends;
  }

  Future<String> sendFriendRequest(int userId, String token) async {
    final response = await _api.sendFriendRequest(userId, token); 
    return response.message;
  }

  Future<String> acceptFriendRequest(int friendshipId, String token) async {
    final response = await _api.acceptFriendRequest(friendshipId, token); 
    return response.message;
  }

  Future<String> rejectFriendRequest(int friendshipId, String token) async {
    final response = await _api.rejectFriendRequest(friendshipId, token); 
    return response.message;
  }

  Future<void> removeFriend(int friendId, String token) async {
    await _api.removeFriend(friendId, token); 
  }
}
