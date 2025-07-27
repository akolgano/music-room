import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:music_room/services/friend_service.dart';
import 'package:music_room/services/api_service.dart';
void main() {
  group('Friend Service Tests', () {
    late FriendService friendService;
    late ApiService apiService;
    setUp(() {
      final dio = Dio();
      dio.options.baseUrl = 'http://localhost:8000';
      apiService = ApiService(dio);
      friendService = FriendService(apiService);
    });
    test('FriendService should be instantiable', () {
      expect(friendService, isA<FriendService>());
    });
    test('FriendService should handle dependency injection', () {
      expect(friendService, isNotNull);
      expect(friendService, isA<FriendService>());
    });
    test('FriendService should have proper constructor', () {
      final service = FriendService(apiService);
      
      expect(service, isA<FriendService>());
      expect(service, isNotNull);
    });
    test('FriendService should expose friend management methods', () {
      expect(friendService.getFriends, isA<Function>());
      expect(friendService.sendFriendRequest, isA<Function>());
      expect(friendService.acceptFriendRequest, isA<Function>());
      expect(friendService.rejectFriendRequest, isA<Function>());
      expect(friendService.removeFriend, isA<Function>());
    });
    test('FriendService should expose invitation methods', () {
      expect(friendService.getReceivedInvitations, isA<Function>());
      expect(friendService.getSentInvitations, isA<Function>());
    });
    test('FriendService should work with ApiService dependency', () {
      final dio = Dio();
      dio.options.baseUrl = 'http://localhost:8000';
      final testApiService = ApiService(dio);
      final testFriendService = FriendService(testApiService);
      
      expect(testFriendService, isNotNull);
      expect(testFriendService, isA<FriendService>());
    });
  });
}