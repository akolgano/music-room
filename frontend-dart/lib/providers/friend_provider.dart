// lib/providers/friend_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FriendProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<int> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<int> get friends => List.unmodifiable(_friends);
  List<Map<String, dynamic>> get pendingRequests => List.unmodifiable(_pendingRequests);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<T?> _execute<T>(Future<T> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await operation();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFriends(String token) async {
    final result = await _execute(() => _api.getFriends(token));
    if (result != null) _friends = result;
  }

  Future<String?> sendFriendRequest(String token, int userId) async {
    return await _execute(() => _api.sendFriendRequest(userId, token));
  }

  Future<void> fetchPendingRequests(String token) async {
    final result = await _execute(() => _api.getPendingFriendRequests(token));
    if (result != null) _pendingRequests = result;
  }

  Future<String?> acceptFriendRequest(String token, int friendshipId) async {
    final result = await _execute(() async {
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
    return result;
  }

  Future<String?> rejectFriendRequest(String token, int friendshipId) async {
    final result = await _execute(() async {
      final message = await _api.rejectFriendRequest(friendshipId, token);
      
      _pendingRequests.removeWhere((req) => 
        int.tryParse(req['id']?.toString() ?? '0') == friendshipId);
      
      notifyListeners();
      return message;
    });
    return result;
  }

  Future<void> removeFriend(String token, int friendId) async {
    await _execute(() async {
      await _api.removeFriend(friendId, token);
      _friends.remove(friendId);
    });
  }
}
