import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:music_room/providers/voting_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/models/api_models.dart';
void main() {
  group('Voting Service Tests', () {
    test('VotingService should be instantiable', () {
      final dio = Dio();
      dio.options.baseUrl = 'http://localhost:8000';
      final apiService = ApiService(dio);
      final votingService = VotingService(apiService);
      expect(votingService, isA<VotingService>());
    });
    test('VoteRequest should serialize correctly', () {
      const request = VoteRequest(rangeStart: 0);
      final json = request.toJson();
      
      expect(json['range_start'], 0);
    });
    test('VoteResponse should deserialize correctly', () {
      final json = {
        'message': 'Vote recorded successfully',
        'playlist': []
      };
      
      final response = VoteResponse.fromJson(json);
      
      expect(response.message, 'Vote recorded successfully');
      expect(response.playlist, isEmpty);
    });
    test('VoteResponse should handle missing message', () {
      final json = {
        'playlist': []
      };
      
      final response = VoteResponse.fromJson(json);
      
      expect(response.message, 'Vote recorded');
      expect(response.playlist, isEmpty);
    });
    test('VoteRequest should handle different range starts', () {
      const request1 = VoteRequest(rangeStart: 5);
      const request2 = VoteRequest(rangeStart: 0);
      
      expect(request1.toJson()['range_start'], 5);
      expect(request2.toJson()['range_start'], 0);
    });
    test('VotingService should work with ApiService dependency', () {
      final dio = Dio();
      dio.options.baseUrl = 'http://localhost:8000';
      final apiService = ApiService(dio);
      final votingService = VotingService(apiService);
      
      expect(votingService, isNotNull);
      expect(votingService, isA<VotingService>());
    });
  });
}