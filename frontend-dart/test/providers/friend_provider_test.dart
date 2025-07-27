import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:music_room/providers/friend_provider.dart';
import 'package:music_room/core/base_provider.dart';
import 'package:music_room/services/api_service.dart';
import 'package:music_room/services/friend_service.dart';
void main() {
  group('Friend Provider Tests', () {
    late FriendProvider friendProvider;
    setUp(() {
      GetIt.instance.reset();
      final dio = Dio();
      dio.options.baseUrl = 'http://localhost:8000';
      final apiService = ApiService(dio);
      final friendService = FriendService(apiService);
      GetIt.instance.registerSingleton<ApiService>(apiService);
      GetIt.instance.registerSingleton<FriendService>(friendService);
      friendProvider = FriendProvider();
    });
    test('FriendProvider should extend BaseProvider', () {
      expect(friendProvider, isA<BaseProvider>());
    });
    test('FriendProvider should have initial empty state', () {
      expect(friendProvider.friends, isEmpty);
      expect(friendProvider.receivedInvitations, isEmpty);
      expect(friendProvider.sentInvitations, isEmpty);
    });
    test('FriendProvider should provide unmodifiable lists', () {
      final friends = friendProvider.friends;
      final received = friendProvider.receivedInvitations;
      final sent = friendProvider.sentInvitations;
      
      expect(() => friends.add(1), throwsUnsupportedError);
      expect(() => received.add({}), throwsUnsupportedError);
      expect(() => sent.add({}), throwsUnsupportedError);
    });
    test('FriendProvider should clear friends properly', () {
      friendProvider.clearFriends();
      
      expect(friendProvider.friends, isEmpty);
      expect(friendProvider.receivedInvitations, isEmpty);
      expect(friendProvider.sentInvitations, isEmpty);
    });
    test('FriendProvider should extract friendship ID from invitation', () {
      final invitation = {'id': 123, 'status': 'pending'};
      final friendshipId = friendProvider.getFriendshipId(invitation);
      
      expect(friendshipId, 123);
    });
    test('FriendProvider should extract from user ID from invitation', () {
      final invitation = {'from_user': 456, 'status': 'pending'};
      final fromUserId = friendProvider.getFromUserId(invitation);
      
      expect(fromUserId, 456);
    });
    test('FriendProvider should extract to user ID from invitation', () {
      final invitation = {'to_user': 789, 'status': 'pending'};
      final toUserId = friendProvider.getToUserId(invitation);
      
      expect(toUserId, 789);
    });
    test('FriendProvider should extract invitation status', () {
      final invitation = {'id': 1, 'status': 'accepted'};
      final status = friendProvider.getInvitationStatus(invitation);
      
      expect(status, 'accepted');
    });
    test('FriendProvider should extract from username', () {
      final invitation = {'from_username': 'alice', 'status': 'pending'};
      final fromUsername = friendProvider.getFromUsername(invitation);
      
      expect(fromUsername, 'alice');
    });
    test('FriendProvider should extract to username', () {
      final invitation = {'to_username': 'bob', 'status': 'pending'};
      final toUsername = friendProvider.getToUsername(invitation);
      
      expect(toUsername, 'bob');
    });
    test('FriendProvider should handle null values in invitation data', () {
      final invitation = <String, dynamic>{};
      
      expect(friendProvider.getFriendshipId(invitation), null);
      expect(friendProvider.getFromUserId(invitation), null);
      expect(friendProvider.getToUserId(invitation), null);
      expect(friendProvider.getInvitationStatus(invitation), null);
      expect(friendProvider.getFromUsername(invitation), null);
      expect(friendProvider.getToUsername(invitation), null);
    });
  });
}