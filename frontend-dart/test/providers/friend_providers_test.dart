import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/providers/friend_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/core/locator_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late FriendProvider provider;
  late _MockFriendService mockFriendService;
  late _MockApiService mockApiService;

  setUp(() {
    getIt.reset();
    mockFriendService = _MockFriendService();
    mockApiService = _MockApiService();
    getIt.registerSingleton<FriendService>(mockFriendService);
    getIt.registerSingleton<ApiService>(mockApiService);
    provider = FriendProvider();
  });

  tearDown(() {
    provider.dispose();
    getIt.reset();
  });

  group('FriendProvider Tests', () {
    test('should handle friend data models', () {
      final friend = Friend(
        id: '1',
        username: 'friend123',
        email: 'friend@example.com',
      );
      
      expect(friend.id, '1');
      expect(friend.username, 'friend123');
      expect(friend.email, 'friend@example.com');
    });

    test('initial state should be empty', () {
      expect(provider.friends, isEmpty);
      expect(provider.receivedInvitations, isEmpty);
      expect(provider.sentInvitations, isEmpty);
    });

    test('clearFriends should clear all data and notify listeners', () {
      int listenerCallCount = 0;
      provider.addListener(() {
        listenerCallCount++;
      });
      
      provider.clearFriends();
      
      expect(provider.friends, isEmpty);
      expect(provider.receivedInvitations, isEmpty);
      expect(provider.sentInvitations, isEmpty);
      expect(listenerCallCount, equals(1));
    });

    test('getFriendshipId should extract friendship ID from invitation', () {
      final invitation1 = {'friendship_id': '123'};
      expect(provider.getFriendshipId(invitation1), equals('123'));
      
      final invitation2 = {'id': '456'};
      expect(provider.getFriendshipId(invitation2), equals('456'));
      
      final invitation3 = <String, dynamic>{};
      expect(provider.getFriendshipId(invitation3), isNull);
    });

    test('getFromUserId should extract from user ID from invitation', () {
      final invitation1 = {'friend_id': 'user123'};
      expect(provider.getFromUserId(invitation1), equals('user123'));
      
      final invitation2 = {'from_user': 'user456'};
      expect(provider.getFromUserId(invitation2), equals('user456'));
      
      final invitation3 = <String, dynamic>{};
      expect(provider.getFromUserId(invitation3), isNull);
    });

    test('getToUserId should extract to user ID from invitation', () {
      final invitation1 = {'friend_id': 'user789'};
      expect(provider.getToUserId(invitation1), equals('user789'));
      
      final invitation2 = {'to_user': 'user012'};
      expect(provider.getToUserId(invitation2), equals('user012'));
      
      final invitation3 = <String, dynamic>{};
      expect(provider.getToUserId(invitation3), isNull);
    });

    test('getInvitationStatus should extract status from invitation', () {
      final invitation1 = {'status': 'pending'};
      expect(provider.getInvitationStatus(invitation1), equals('pending'));
      
      final invitation2 = {'status': 'accepted'};
      expect(provider.getInvitationStatus(invitation2), equals('accepted'));
      
      final invitation3 = <String, dynamic>{};
      expect(provider.getInvitationStatus(invitation3), isNull);
    });

    test('getFromUsername should extract from username from invitation', () {
      final invitation1 = {'friend_username': 'alice'};
      expect(provider.getFromUsername(invitation1), equals('alice'));
      
      final invitation2 = {'from_username': 'bob'};
      expect(provider.getFromUsername(invitation2), equals('bob'));
      
      final invitation3 = <String, dynamic>{};
      expect(provider.getFromUsername(invitation3), isNull);
    });

    test('getToUsername should extract to username from invitation', () {
      final invitation1 = {'friend_username': 'charlie'};
      expect(provider.getToUsername(invitation1), equals('charlie'));
      
      final invitation2 = {'to_username': 'david'};
      expect(provider.getToUsername(invitation2), equals('david'));
      
      final invitation3 = <String, dynamic>{};
      expect(provider.getToUsername(invitation3), isNull);
    });

    test('friends should return unmodifiable list', () {
      expect(() => provider.friends.add(Friend(id: '1', username: 'test', email: 'test@test.com')), 
             throwsUnsupportedError);
    });

    test('receivedInvitations should return unmodifiable list', () {
      expect(() => provider.receivedInvitations.add({'id': '1'}), 
             throwsUnsupportedError);
    });

    test('sentInvitations should return unmodifiable list', () {
      expect(() => provider.sentInvitations.add({'id': '1'}), 
             throwsUnsupportedError);
    });
  });

  group('FriendService Tests', () {
    late FriendService service;
    late _MockApiService mockApi;

    setUp(() {
      mockApi = _MockApiService();
      service = FriendService(mockApi);
    });

    test('getFriends should call API and return friends', () async {
      final friends = await service.getFriends('token123');
      expect(friends, isA<List<Friend>>());
    });

    test('acceptFriendRequest should call API and return message', () async {
      final message = await service.acceptFriendRequest('friendship123', 'token123');
      expect(message, equals('Friend request accepted'));
    });

    test('rejectFriendRequest should call API and return message', () async {
      final message = await service.rejectFriendRequest('friendship123', 'token123');
      expect(message, equals('Friend request rejected'));
    });

    test('getReceivedInvitations should call API and return invitations', () async {
      final invitations = await service.getReceivedInvitations('token123');
      expect(invitations, isA<List<Map<String, dynamic>>>());
    });

    test('getSentInvitations should call API and return invitations', () async {
      final invitations = await service.getSentInvitations('token123');
      expect(invitations, isA<List<Map<String, dynamic>>>());
    });
  });
}

class _MockFriendService extends FriendService {
  _MockFriendService() : super(_MockApiService());
  
  @override
  Future<List<Friend>> getFriends(String token) async {
    return [];
  }
  
  @override
  Future<String> acceptFriendRequest(String friendshipId, String token) async {
    return 'Friend request accepted';
  }
  
  @override
  Future<String> rejectFriendRequest(String friendshipId, String token) async {
    return 'Friend request rejected';
  }
  
  @override
  Future<List<Map<String, dynamic>>> getReceivedInvitations(String token) async {
    return [];
  }
  
  @override
  Future<List<Map<String, dynamic>>> getSentInvitations(String token) async {
    return [];
  }
}

class _MockApiService extends ApiService {
  @override
  Future<FriendsResponse> getFriends(String token) async {
    return FriendsResponse(friends: []);
  }
  
  @override
  Future<MessageResponse> acceptFriendRequest(String friendshipId, String token) async {
    return MessageResponse(message: 'Friend request accepted');
  }
  
  @override
  Future<MessageResponse> rejectFriendRequest(String friendshipId, String token) async {
    return MessageResponse(message: 'Friend request rejected');
  }
  
  @override
  Future<FriendInvitationsResponse> getReceivedInvitations(String token) async {
    return FriendInvitationsResponse(invitations: []);
  }
  
  @override
  Future<FriendInvitationsResponse> getSentInvitations(String token) async {
    return FriendInvitationsResponse(invitations: []);
  }
}