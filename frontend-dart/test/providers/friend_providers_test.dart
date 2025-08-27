import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:music_room/providers/friend_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';

import 'friend_providers_test.mocks.dart';

@GenerateMocks([ApiService, FriendService])
void main() {
  group('FriendProvider Tests', () {
    late FriendProvider friendProvider;
    late MockApiService mockApiService;
    late MockFriendService mockFriendService;

    setUp(() {
      GetIt.instance.reset();
      mockApiService = MockApiService();
      mockFriendService = MockFriendService();
      
      getIt.registerSingleton<ApiService>(mockApiService);
      getIt.registerSingleton<FriendService>(mockFriendService);
      
      friendProvider = FriendProvider();
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test('should initialize with empty friends list', () {
      expect(friendProvider.friends, isEmpty);
      expect(friendProvider.receivedInvitations, isEmpty);
      expect(friendProvider.sentInvitations, isEmpty);
    });

    test('should fetch friends successfully', () async {
      final testFriends = [
        const Friend(id: '1', username: 'friend1', email: 'friend1@test.com'),
        const Friend(id: '2', username: 'friend2', email: 'friend2@test.com'),
      ];
      
      when(mockFriendService.getFriends(any)).thenAnswer((_) async => testFriends);
      
      await friendProvider.fetchFriends('test_token');
      
      expect(friendProvider.friends, hasLength(2));
      expect(friendProvider.friends.first.username, 'friend1');
      verify(mockFriendService.getFriends('test_token')).called(1);
    });

    test('should fetch received invitations successfully', () async {
      final testInvitations = [
        {'friendship_id': '1', 'from_username': 'user1', 'status': 'pending'},
        {'friendship_id': '2', 'from_username': 'user2', 'status': 'pending'},
      ];
      
      when(mockFriendService.getReceivedInvitations(any)).thenAnswer((_) async => testInvitations);
      
      await friendProvider.fetchReceivedInvitations('test_token');
      
      expect(friendProvider.receivedInvitations, hasLength(2));
      verify(mockFriendService.getReceivedInvitations('test_token')).called(1);
    });

    test('should fetch sent invitations successfully', () async {
      final testInvitations = [
        {'friendship_id': '1', 'to_username': 'user1', 'status': 'pending'},
        {'friendship_id': '2', 'to_username': 'user2', 'status': 'pending'},
      ];
      
      when(mockFriendService.getSentInvitations(any)).thenAnswer((_) async => testInvitations);
      
      await friendProvider.fetchSentInvitations('test_token');
      
      expect(friendProvider.sentInvitations, hasLength(2));
      verify(mockFriendService.getSentInvitations('test_token')).called(1);
    });

    test('should send friend request successfully', () async {
      final testInvitations = [
        {'friendship_id': '1', 'to_username': 'user1', 'status': 'pending'},
      ];
      
      when(mockApiService.sendFriendRequest(any, any)).thenAnswer((_) async => MessageResponse(message: 'Request sent'));
      when(mockFriendService.getSentInvitations(any)).thenAnswer((_) async => testInvitations);
      
      final result = await friendProvider.sendFriendRequest('test_token', 'user1');
      
      expect(result, isTrue);
      verify(mockApiService.sendFriendRequest('user1', 'test_token')).called(1);
      verify(mockFriendService.getSentInvitations('test_token')).called(1);
    });

    test('should accept friend request successfully', () async {
      when(mockFriendService.acceptFriendRequest(any, any)).thenAnswer((_) async => 'Request accepted');
      when(mockFriendService.getFriends(any)).thenAnswer((_) async => []);
      when(mockFriendService.getReceivedInvitations(any)).thenAnswer((_) async => []);
      when(mockFriendService.getSentInvitations(any)).thenAnswer((_) async => []);
      
      final result = await friendProvider.acceptFriendRequest('test_token', 'friendship_id');
      
      expect(result, isTrue);
      verify(mockFriendService.acceptFriendRequest('friendship_id', 'test_token')).called(1);
    });

    test('should reject friend request successfully', () async {
      when(mockFriendService.rejectFriendRequest(any, any)).thenAnswer((_) async => 'Request rejected');
      when(mockFriendService.getReceivedInvitations(any)).thenAnswer((_) async => []);
      
      final result = await friendProvider.rejectFriendRequest('test_token', 'friendship_id');
      
      expect(result, isTrue);
      verify(mockFriendService.rejectFriendRequest('friendship_id', 'test_token')).called(1);
      verify(mockFriendService.getReceivedInvitations('test_token')).called(1);
    });

    test('should remove friend successfully', () async {
      final initialFriends = [
        const Friend(id: 'friend_id', username: 'friend1', email: 'friend1@test.com'),
      ];
      
      when(mockFriendService.getFriends(any)).thenAnswer((_) async => initialFriends);
      await friendProvider.fetchFriends('test_token');
      
      when(mockFriendService.removeFriend(any, any)).thenAnswer((_) async {});
      
      final result = await friendProvider.removeFriend('test_token', 'friend_id');
      
      expect(result, isTrue);
      verify(mockFriendService.removeFriend('friend_id', 'test_token')).called(1);
    });

    test('should clear friends data', () async {
      // Add some initial data
      final testFriends = [const Friend(id: '1', username: 'friend1', email: 'friend1@test.com')];
      final testInvitations = [{'friendship_id': '1', 'from_username': 'user1'}];
      
      when(mockFriendService.getFriends(any)).thenAnswer((_) async => testFriends);
      when(mockFriendService.getReceivedInvitations(any)).thenAnswer((_) async => testInvitations);
      
      await friendProvider.fetchFriends('test_token');
      await friendProvider.fetchReceivedInvitations('test_token');
      
      expect(friendProvider.friends, isNotEmpty);
      expect(friendProvider.receivedInvitations, isNotEmpty);
      
      friendProvider.clearFriends();
      
      expect(friendProvider.friends, isEmpty);
      expect(friendProvider.receivedInvitations, isEmpty);
      expect(friendProvider.sentInvitations, isEmpty);
    });

    test('should get friendship id from invitation', () {
      final invitation = {'friendship_id': 'test_id'};
      
      final friendshipId = friendProvider.getFriendshipId(invitation);
      
      expect(friendshipId, equals('test_id'));
    });

    test('should get from user id from invitation', () {
      final invitation = {'friend_id': 'user_123'};
      
      final fromUserId = friendProvider.getFromUserId(invitation);
      
      expect(fromUserId, equals('user_123'));
    });

    test('should get to user id from invitation', () {
      final invitation = {'friend_id': 'user_456'};
      
      final toUserId = friendProvider.getToUserId(invitation);
      
      expect(toUserId, equals('user_456'));
    });

    test('should get invitation status', () {
      final invitation = {'status': 'pending'};
      
      final status = friendProvider.getInvitationStatus(invitation);
      
      expect(status, equals('pending'));
    });

    test('should get from username from invitation', () {
      final invitation = {'friend_username': 'test_user'};
      
      final username = friendProvider.getFromUsername(invitation);
      
      expect(username, equals('test_user'));
    });

    test('should get to username from invitation', () {
      final invitation = {'friend_username': 'test_user'};
      
      final username = friendProvider.getToUsername(invitation);
      
      expect(username, equals('test_user'));
    });
  });
}