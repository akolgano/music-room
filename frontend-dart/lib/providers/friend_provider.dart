// lib/providers/friend_provider.dart
import 'package:flutter/material.dart';
import '../core/base_provider.dart';
import '../core/service_locator.dart';
import '../services/friend_service.dart';

class FriendProvider extends BaseProvider {
  final FriendService _friendService = getIt<FriendService>();
  
  List<int> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  List<int> get friends => List.unmodifiable(_friends);
  List<Map<String, dynamic>> get pendingRequests => List.unmodifiable(_pendingRequests);

  Future<void> fetchFriends(String token) async {
    final result = await executeAsync(
      () => _friendService.getFriends(token),
      errorMessage: 'Failed to load friends',
    );
    if (result != null) _friends = result;
  }

  Future<void> fetchPendingRequests(String token) async {
    final result = await executeAsync(
      () => _friendService.getPendingFriendRequests(token),
      errorMessage: 'Failed to load friend requests',
    );
    if (result != null) _pendingRequests = result;
  }

  Future<bool> sendFriendRequest(String token, int userId) async {
    return await executeBool(
      () async {
        await _friendService.sendFriendRequest(userId, token);
      },
      successMessage: 'Friend request sent!',
      errorMessage: 'Failed to send friend request',
    );
  }

  Future<bool> acceptFriendRequest(String token, int friendshipId) async {
    return await executeBool(
      () async {
        await _friendService.acceptFriendRequest(friendshipId, token);
        
        final requestIndex = _pendingRequests.indexWhere(
          (req) => int.tryParse(req['id']?.toString() ?? '0') == friendshipId
        );
        if (requestIndex != -1) {
          final fromUser = _pendingRequests[requestIndex]['from_user'] as int?;
          _pendingRequests.removeAt(requestIndex);
          if (fromUser != null && !_friends.contains(fromUser)) {
            _friends.add(fromUser);
          }
        }
      },
      successMessage: 'Friend request accepted!',
      errorMessage: 'Failed to accept request',
    );
  }

  Future<bool> rejectFriendRequest(String token, int friendshipId) async {
    return await executeBool(
      () async {
        await _friendService.rejectFriendRequest(friendshipId, token);
        
        _pendingRequests.removeWhere(
          (req) => int.tryParse(req['id']?.toString() ?? '0') == friendshipId
        );
      },
      successMessage: 'Friend request rejected',
      errorMessage: 'Failed to reject request',
    );
  }

  Future<bool> removeFriend(String token, int friendId) async {
    return await executeBool(
      () async {
        await _friendService.removeFriend(friendId, token);
        _friends.remove(friendId);
      },
      successMessage: 'Friend removed',
      errorMessage: 'Failed to remove friend',
    );
  }
}
