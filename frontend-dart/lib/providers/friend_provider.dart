// lib/providers/friend_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/friendship.dart';
import '../models/user.dart';
import 'base_provider.dart';

class FriendProvider with ChangeNotifier, BaseProviderMixin {
  List<int> _friends = [];
  List<Friendship> _pendingRequests = [];
  List<User> _users = [];
  String? _apiBaseUrl;
  
  List<int> get friends => [..._friends];
  List<Friendship> get pendingRequests => [..._pendingRequests];
  List<User> get users => [..._users];
  
  FriendProvider() {
    _apiBaseUrl = dotenv.env['API_BASE_URL'];
  }
  
  Future<void> fetchFriends(String token) async {
    await apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/users/get_friends/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _friends = List<int>.from(responseData['friends']);
        notifyListeners();
        return _friends;
      } else {
        throw Exception('Failed to load friends');
      }
    });
  }
  
  Future<String> sendFriendRequest(String token, int userId) async {
    final result = await apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/send_friend_request/$userId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['message'];
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to send friend request');
      }
    });
    
    return result ?? '';
  }
  
  Future<String> acceptFriendRequest(String token, int friendshipId) async {
    final result = await apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/accept_friend_request/$friendshipId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        await fetchFriends(token);
        notifyListeners();
        return responseData['message'];
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to accept friend request');
      }
    });
    
    return result ?? '';
  }
  
  Future<String> rejectFriendRequest(String token, int friendshipId) async {
    final result = await apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/reject_friend_request/$friendshipId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        notifyListeners();
        return responseData['message'];
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to reject friend request');
      }
    });
    
    return result ?? '';
  }
  
  Future<String> removeFriend(String token, int userId) async {
    final result = await apiCall(() async {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/users/remove_friend/$userId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _friends.remove(userId);
        notifyListeners();
        return responseData['message'];
      } else {
        final responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to remove friend');
      }
    });
    
    return result ?? '';
  }
  
  Future<void> fetchPendingRequests(String token) async {
    await apiCall(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/users/pending_requests/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> requestsData = responseData['requests'];
        
        _pendingRequests = requestsData.map((req) => Friendship.fromJson(req)).toList();
        notifyListeners();
        return _pendingRequests;
      } else {
        _pendingRequests = [];
        return [];
      }
    });
  }

  Future<List<User>> searchUsers(String token, String query) async {
    final result = await apiCall<List<User>>(() async {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/users/search/?query=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> usersData = responseData['users'];
        
        final typedUsers = usersData.map((user) => User.fromJson(user)).toList();
        _users = typedUsers;
        notifyListeners();
        return typedUsers;
      } else {
        return <User>[];
      }
    });

    return result ?? <User>[];
  }
}
