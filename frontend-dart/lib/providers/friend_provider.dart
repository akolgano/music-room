// lib/providers/friend_provider.dart
import 'package:flutter/material.dart';
import '../core/base_provider.dart';
import '../core/service_locator.dart';
import '../services/friend_service.dart';

class FriendProvider extends BaseProvider {
  final FriendService _friendService = getIt<FriendService>();
  
  List<int> _friends = [];
  
  List<int> get friends => List.unmodifiable(_friends);
  
  Future<void> fetchFriends(String token) async {
    final result = await executeAsync(
      () => _friendService.getFriends(token),
      errorMessage: 'Failed to load friends',
    );
    if (result != null) _friends = result;
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
      },
      successMessage: 'Friend request accepted!',
      errorMessage: 'Failed to accept request',
    );
  }

  Future<bool> rejectFriendRequest(String token, int friendshipId) async {
    return await executeBool(
      () async {
        await _friendService.rejectFriendRequest(friendshipId, token);
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
