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

  Future<List<Map<String, dynamic>>> getReceivedInvitations(String token) async {
    final response = await _api.getReceivedInvitations(token);
    return response.invitations.map((invitation) => {
      'id': invitation.friendshipId,
      'friend_id': invitation.friendId,
      'friend_username': invitation.friendUsername,
      'friendship_id': invitation.friendshipId,
      'profile_picture_url': invitation.profilePictureUrl,
      'status': invitation.status,
      'from_user': invitation.friendId,
      'to_user': invitation.friendId, 
      'from_username': invitation.friendUsername,
      'to_username': invitation.friendUsername, 
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getSentInvitations(String token) async {
    final response = await _api.getSentInvitations(token);
    return response.invitations.map((invitation) => {
      'id': invitation.friendshipId,
      'friend_id': invitation.friendId,
      'friend_username': invitation.friendUsername,
      'friendship_id': invitation.friendshipId,
      'profile_picture_url': invitation.profilePictureUrl,
      'status': invitation.status,
      'from_user': invitation.friendId,
      'to_user': invitation.friendId, 
      'from_username': invitation.friendUsername,
      'to_username': invitation.friendUsername, 
    }).toList();
  }
}
