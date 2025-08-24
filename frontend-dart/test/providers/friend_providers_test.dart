import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:music_room/providers/friend_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';

@GenerateMocks([ApiService, AuthProvider])
import 'friend_providers_test.mocks.dart';

void main() {
  group('FriendProvider Tests', () {
    late FriendProvider friendProvider;
    late MockApiService mockApiService;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      GetIt.instance.reset();
      mockApiService = MockApiService();
      mockAuthProvider = MockAuthProvider();
      
      getIt.registerSingleton<ApiService>(mockApiService);
      getIt.registerSingleton<AuthProvider>(mockAuthProvider);
      
      when(mockAuthProvider.token).thenReturn('test_token');
      when(mockAuthProvider.authHeaders).thenReturn({
        'Content-Type': 'application/json',
        'Authorization': 'Token test_token'
      });
      
      friendProvider = FriendProvider();
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test('should initialize with empty friends list', () {
      expect(friendProvider.friends, isEmpty);
      expect(friendProvider.friendRequests, isEmpty);
      expect(friendProvider.sentRequests, isEmpty);
    });

    test('should load friends successfully', () async {
      final testFriends = [
        Friend(id: '1', username: 'friend1', email: 'friend1@test.com'),
        Friend(id: '2', username: 'friend2', email: 'friend2@test.com'),
      ];
      
      when(mockApiService.getFriends(any)).thenAnswer((_) async => FriendsResponse(friends: testFriends));
      
      await friendProvider.loadFriends();
      
      expect(friendProvider.friends, hasLength(2));
      expect(friendProvider.friends.first.username, 'friend1');
      verify(mockApiService.getFriends('test_token')).called(1);
    });

    test('should handle load friends error', () async {
      when(mockApiService.getFriends(any)).thenThrow(Exception('API Error'));
      
      await friendProvider.loadFriends();
      
      expect(friendProvider.friends, isEmpty);
      expect(friendProvider.hasError, isTrue);
      verify(mockApiService.getFriends('test_token')).called(1);
    });

    test('should load friend requests successfully', () async {
      final testRequests = [
        FriendRequest(id: '1', fromUser: User(id: '1', username: 'requester1', email: 'req1@test.com'), status: 'pending'),
        FriendRequest(id: '2', fromUser: User(id: '2', username: 'requester2', email: 'req2@test.com'), status: 'pending'),
      ];
      
      when(mockApiService.getFriendRequests(any)).thenAnswer((_) async => FriendRequestsResponse(requests: testRequests));
      
      await friendProvider.loadFriendRequests();
      
      expect(friendProvider.friendRequests, hasLength(2));
      expect(friendProvider.friendRequests.first.fromUser.username, 'requester1');
      verify(mockApiService.getFriendRequests('test_token')).called(1);
    });

    test('should handle load friend requests error', () async {
      when(mockApiService.getFriendRequests(any)).thenThrow(Exception('API Error'));
      
      await friendProvider.loadFriendRequests();
      
      expect(friendProvider.friendRequests, isEmpty);
      expect(friendProvider.hasError, isTrue);
      verify(mockApiService.getFriendRequests('test_token')).called(1);
    });

    test('should send friend request successfully', () async {
      when(mockApiService.sendFriendRequest(any, any)).thenAnswer((_) async => FriendRequestResponse(success: true, message: 'Request sent'));
      
      final result = await friendProvider.sendFriendRequest('friend_username');
      
      expect(result, isTrue);
      verify(mockApiService.sendFriendRequest('test_token', 'friend_username')).called(1);
    });

    test('should handle send friend request error', () async {
      when(mockApiService.sendFriendRequest(any, any)).thenThrow(Exception('API Error'));
      
      final result = await friendProvider.sendFriendRequest('friend_username');
      
      expect(result, isFalse);
      verify(mockApiService.sendFriendRequest('test_token', 'friend_username')).called(1);
    });

    test('should accept friend request successfully', () async {
      when(mockApiService.acceptFriendRequest(any, any)).thenAnswer((_) async => FriendRequestResponse(success: true, message: 'Request accepted'));
      
      final result = await friendProvider.acceptFriendRequest('request_id');
      
      expect(result, isTrue);
      verify(mockApiService.acceptFriendRequest('test_token', 'request_id')).called(1);
    });

    test('should handle accept friend request error', () async {
      when(mockApiService.acceptFriendRequest(any, any)).thenThrow(Exception('API Error'));
      
      final result = await friendProvider.acceptFriendRequest('request_id');
      
      expect(result, isFalse);
      verify(mockApiService.acceptFriendRequest('test_token', 'request_id')).called(1);
    });

    test('should decline friend request successfully', () async {
      when(mockApiService.declineFriendRequest(any, any)).thenAnswer((_) async => FriendRequestResponse(success: true, message: 'Request declined'));
      
      final result = await friendProvider.declineFriendRequest('request_id');
      
      expect(result, isTrue);
      verify(mockApiService.declineFriendRequest('test_token', 'request_id')).called(1);
    });

    test('should handle decline friend request error', () async {
      when(mockApiService.declineFriendRequest(any, any)).thenThrow(Exception('API Error'));
      
      final result = await friendProvider.declineFriendRequest('request_id');
      
      expect(result, isFalse);
      verify(mockApiService.declineFriendRequest('test_token', 'request_id')).called(1);
    });

    test('should remove friend successfully', () async {
      when(mockApiService.removeFriend(any, any)).thenAnswer((_) async => FriendRequestResponse(success: true, message: 'Friend removed'));
      
      final result = await friendProvider.removeFriend('friend_id');
      
      expect(result, isTrue);
      verify(mockApiService.removeFriend('test_token', 'friend_id')).called(1);
    });

    test('should handle remove friend error', () async {
      when(mockApiService.removeFriend(any, any)).thenThrow(Exception('API Error'));
      
      final result = await friendProvider.removeFriend('friend_id');
      
      expect(result, isFalse);
      verify(mockApiService.removeFriend('test_token', 'friend_id')).called(1);
    });

    test('should search friends successfully', () async {
      final searchResults = [
        User(id: '1', username: 'searchuser1', email: 'search1@test.com'),
        User(id: '2', username: 'searchuser2', email: 'search2@test.com'),
      ];
      
      when(mockApiService.searchUsers(any, any)).thenAnswer((_) async => UserSearchResponse(users: searchResults));
      
      await friendProvider.searchUsers('search_query');
      
      expect(friendProvider.searchResults, hasLength(2));
      expect(friendProvider.searchResults.first.username, 'searchuser1');
      verify(mockApiService.searchUsers('test_token', 'search_query')).called(1);
    });

    test('should handle search friends error', () async {
      when(mockApiService.searchUsers(any, any)).thenThrow(Exception('API Error'));
      
      await friendProvider.searchUsers('search_query');
      
      expect(friendProvider.searchResults, isEmpty);
      expect(friendProvider.hasError, isTrue);
      verify(mockApiService.searchUsers('test_token', 'search_query')).called(1);
    });

    test('should clear search results', () {
      friendProvider.searchResults.add(User(id: '1', username: 'test', email: 'test@test.com'));
      expect(friendProvider.searchResults, isNotEmpty);
      
      friendProvider.clearSearchResults();
      
      expect(friendProvider.searchResults, isEmpty);
    });

    test('should refresh all data', () async {
      when(mockApiService.getFriends(any)).thenAnswer((_) async => FriendsResponse(friends: []));
      when(mockApiService.getFriendRequests(any)).thenAnswer((_) async => FriendRequestsResponse(requests: []));
      
      await friendProvider.refreshAll();
      
      verify(mockApiService.getFriends('test_token')).called(1);
      verify(mockApiService.getFriendRequests('test_token')).called(1);
    });

    test('should handle refresh all error', () async {
      when(mockApiService.getFriends(any)).thenThrow(Exception('Friends API Error'));
      when(mockApiService.getFriendRequests(any)).thenThrow(Exception('Requests API Error'));
      
      await friendProvider.refreshAll();
      
      expect(friendProvider.hasError, isTrue);
    });

    test('should get friend by id', () {
      final friend = Friend(id: '1', username: 'friend1', email: 'friend1@test.com');
      friendProvider.friends.add(friend);
      
      final foundFriend = friendProvider.getFriendById('1');
      expect(foundFriend, equals(friend));
      
      final notFoundFriend = friendProvider.getFriendById('999');
      expect(notFoundFriend, isNull);
    });

    test('should check if user is friend', () {
      final friend = Friend(id: '1', username: 'friend1', email: 'friend1@test.com');
      friendProvider.friends.add(friend);
      
      expect(friendProvider.isFriend('1'), isTrue);
      expect(friendProvider.isFriend('999'), isFalse);
    });

    test('should get pending request count', () {
      final request1 = FriendRequest(id: '1', fromUser: User(id: '1', username: 'user1', email: 'user1@test.com'), status: 'pending');
      final request2 = FriendRequest(id: '2', fromUser: User(id: '2', username: 'user2', email: 'user2@test.com'), status: 'accepted');
      
      friendProvider.friendRequests.addAll([request1, request2]);
      
      expect(friendProvider.pendingRequestCount, equals(1));
    });

    test('should handle token not available', () async {
      when(mockAuthProvider.token).thenReturn(null);
      
      await friendProvider.loadFriends();
      
      expect(friendProvider.hasError, isTrue);
      verifyNever(mockApiService.getFriends(any));
    });

    test('should notify listeners on state changes', () {
      var notified = false;
      friendProvider.addListener(() => notified = true);
      
      friendProvider.friends.add(Friend(id: '1', username: 'test', email: 'test@test.com'));
      friendProvider.notifyListeners();
      
      expect(notified, isTrue);
    });
  });
}

class Friend {
  final String id;
  final String username;
  final String email;
  
  Friend({required this.id, required this.username, required this.email});
}

class FriendsResponse {
  final List<Friend> friends;
  FriendsResponse({required this.friends});
}

class FriendRequest {
  final String id;
  final User fromUser;
  final String status;
  
  FriendRequest({required this.id, required this.fromUser, required this.status});
}

class FriendRequestsResponse {
  final List<FriendRequest> requests;
  FriendRequestsResponse({required this.requests});
}

class FriendRequestResponse {
  final bool success;
  final String message;
  
  FriendRequestResponse({required this.success, required this.message});
}

class UserSearchResponse {
  final List<User> users;
  UserSearchResponse({required this.users});
}
