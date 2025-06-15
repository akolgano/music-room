// lib/providers/friend_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/consolidated_core.dart';

class FriendProvider with ChangeNotifier, StateManagement {
  final ApiService _api = ApiService();
  
  List<int> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  List<int> get friends => List.unmodifiable(_friends);
  List<Map<String, dynamic>> get pendingRequests => List.unmodifiable(_pendingRequests);

  Future<void> fetchFriends(String token) async {
    final result = await executeAsync(() => _api.getFriends(token));
    if (result != null) _friends = result;
  }

  Future<String?> sendFriendRequest(String token, int userId) async {
    return await executeAsync(() => _api.sendFriendRequest(userId, token));
  }

  Future<void> fetchPendingRequests(String token) async {
    final result = await executeAsync(() => _api.getPendingFriendRequests(token));
    if (result != null) _pendingRequests = result;
  }

  Future<String?> acceptFriendRequest(String token, int friendshipId) async {
    return executeAsync(() async {
      final message = await _api.acceptFriendRequest(friendshipId, token);
      final requestIndex = _pendingRequests.indexWhere((req) => 
        int.tryParse(req['id']?.toString() ?? '0') == friendshipId);
      if (requestIndex != -1) {
        final fromUser = _pendingRequests[requestIndex]['from_user'] as int?;
        _pendingRequests.removeAt(requestIndex);
        if (fromUser != null && !_friends.contains(fromUser)) {
          _friends.add(fromUser);
        }
      }
      notifyListeners();
      return message;
    });
  }

  Future<String?> rejectFriendRequest(String token, int friendshipId) async {
    return executeAsync(() async {
      final message = await _api.rejectFriendRequest(friendshipId, token);
      _pendingRequests.removeWhere((req) => 
        int.tryParse(req['id']?.toString() ?? '0') == friendshipId);
      notifyListeners();
      return message;
    });
  }

  Future<void> removeFriend(String token, int friendId) async {
    await executeAsync(() async {
      await _api.removeFriend(friendId, token);
      _friends.remove(friendId);
    });
  }
}
