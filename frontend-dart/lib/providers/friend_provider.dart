// lib/providers/friend_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FriendProvider with ChangeNotifier {
  final String _apiBaseUrl = dotenv.env['API_BASE_URL'] ?? '';
  
  List<int> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<int> get friends => [..._friends];
  List<Map<String, dynamic>> get pendingRequests => [..._pendingRequests];
  List<Map<String, dynamic>> get users => [..._users];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<T?> _apiCall<T>(Future<T> Function() call) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await call();
      return result;
    } catch (e) {
      _errorMessage = 'Connection error';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, String> _getHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Token $token',
  };

  Future<void> fetchFriends(String token) async {
    await _apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/users/get_friends/'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _friends = List<int>.from(responseData['friends']);
        return _friends;
      } else throw Exception('Failed to load friends');
    });
  }

  Future<String?> sendFriendRequest(String token, int userId) async {
    return await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/send_friend_request/$userId/'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['message'];
      } else throw Exception('Failed to send request');
    });
  }

  Future<String?> acceptFriendRequest(String token, int friendshipId) async {
    return await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/accept_friend_request/$friendshipId/'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        await fetchFriends(token);
        return responseData['message'];
      } else throw Exception('Failed to accept request');
    });
  }

  Future<String?> rejectFriendRequest(String token, int friendshipId) async {
    return await _apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/reject_friend_request/$friendshipId/'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['message'];
      } else throw Exception('Failed to reject request');
    });
  }

  Future<void> fetchPendingRequests(String token) async {
    await _apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/users/pending_requests/'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _pendingRequests = List<Map<String, dynamic>>.from(responseData['requests']);
        return _pendingRequests;
      } else {
        _pendingRequests = [];
        return [];
      }
    });
  }

  Future<String?> removeFriend(String token, int friendId) async {
    return await _apiCall(() async {
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/users/remove_friend/$friendId/'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        await fetchFriends(token);
        return responseData['message'];
      } else throw Exception('Failed to remove friend');
    });
  }
}
