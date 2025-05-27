// lib/providers/friend_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

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
    await _execute(() async {
      _friends = await _api.getFriends(token);
    });
  }

  Future<String?> sendFriendRequest(String token, int userId) async {
    return await _execute(() => _api.sendFriendRequest(userId, token));
  }

  Future<void> fetchPendingRequests(String token) async {
    await _execute(() async {
      _pendingRequests = [
        {
          'id': '1',
          'from_user': 123,
          'to_user': int.tryParse(token) ?? 0, 
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        }
      ];
    });
  }

  Future<String?> acceptFriendRequest(String token, int friendshipId) async {
    return await _execute(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      
      _pendingRequests.removeWhere((req) => 
          int.tryParse(req['id']?.toString() ?? '0') == friendshipId);
      
      final fromUser = _pendingRequests.firstWhere(
        (req) => int.tryParse(req['id']?.toString() ?? '0') == friendshipId,
        orElse: () => {'from_user': friendshipId}
      )['from_user'] as int?;
      
      if (fromUser != null && !_friends.contains(fromUser)) {
        _friends.add(fromUser);
      }
      
      notifyListeners();
      return 'Friend request accepted';
    });
  }

  Future<String?> rejectFriendRequest(String token, int friendshipId) async {
    return await _execute(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      
      _pendingRequests.removeWhere((req) => 
          int.tryParse(req['id']?.toString() ?? '0') == friendshipId);
      
      notifyListeners();
      return 'Friend request rejected';
    });
  }

  Future<void> removeFriend(String token, int friendId) async {
    await _execute(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      _friends.remove(friendId);
    });
  }
}
