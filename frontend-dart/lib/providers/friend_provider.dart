// lib/providers/friend_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FriendProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
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

  Future<void> fetchFriends(String token) async {
    try {
      _isLoading = true;
      notifyListeners();

      _friends = await _apiService.getFriends(token);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> sendFriendRequest(String token, int userId) async {
    try {
      return await _apiService.sendFriendRequest(userId, token);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchPendingRequests(String token) async {
    try {
      _isLoading = true;
      notifyListeners();

      _pendingRequests = [
        {
          'id': '1',
          'from_user': 123,
          'to_user': int.parse(token.hashCode.toString().substring(0, 3)),
          'status': 'pending',
        }
      ];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> acceptFriendRequest(String token, int friendshipId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return 'Friend request accepted';
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> rejectFriendRequest(String token, int friendshipId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return 'Friend request rejected';
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeFriend(String token, int friendId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _friends.remove(friendId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
