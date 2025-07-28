import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:music_room/services/music_service.dart';
import 'package:music_room/services/api_service.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/models/result_models.dart';
import 'package:music_room/models/api_models.dart';
void main() {
  group('Music Service Tests', () {
    test('MusicService should be instantiable', () {
      final dio = Dio();
      dio.options.baseUrl = 'http://localhost:8000';
      final apiService = ApiService(dio);
      final musicService = MusicService(apiService);
      expect(musicService, isA<MusicService>());
    });
    test('CreatePlaylistRequest should serialize correctly', () {
      const request = CreatePlaylistRequest(
        name: 'Test Playlist',
        description: 'A test playlist',
        public: true
      );
      final json = request.toJson();
      
      expect(json['name'], 'Test Playlist');
      expect(json['description'], 'A test playlist');
      expect(json['public'], true);
    });
    test('AddTrackRequest should serialize correctly', () {
      const request = AddTrackRequest(trackId: 'track123');
      final json = request.toJson();
      
      expect(json['track_id'], 'track123');
    });
    test('MoveTrackRequest should serialize correctly', () {
      const request = MoveTrackRequest(
        rangeStart: 0,
        insertBefore: 2,
        rangeLength: 1
      );
      final json = request.toJson();
      
      expect(json['range_start'], 0);
      expect(json['insert_before'], 2);
      expect(json['range_length'], 1);
    });
    test('InviteUserRequest should serialize correctly', () {
      const request = InviteUserRequest(userId: '123');
      final json = request.toJson();
      
      expect(json['user_id'], '123');
    });
    test('Playlist model should work correctly', () {
      const playlist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'Test Description',
        isPublic: true,
        creator: 'testuser'
      );
      
      expect(playlist.id, '1');
      expect(playlist.name, 'Test Playlist');
      expect(playlist.description, 'Test Description');
      expect(playlist.isPublic, true);
      expect(playlist.creator, 'testuser');
    });
    test('Track model should handle JSON serialization', () {
      const track = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'http://example.com/track'
      );
      
      final json = track.toJson();
      expect(json['id'], '1');
      expect(json['name'], 'Test Song');
      expect(json['artist'], 'Test Artist');
      expect(json['album'], 'Test Album');
      expect(json['url'], 'http://example.com/track');
    });
    test('BatchAddResult should calculate success states', () {
      const completeSuccess = BatchAddResult(
        totalTracks: 5,
        successCount: 5,
        duplicateCount: 0,
        failureCount: 0
      );
      
      expect(completeSuccess.isCompleteSuccess, true);
      expect(completeSuccess.hasErrors, false);
      
      const partialSuccess = BatchAddResult(
        totalTracks: 5,
        successCount: 3,
        duplicateCount: 1,
        failureCount: 1
      );
      
      expect(partialSuccess.isCompleteSuccess, false);
      expect(partialSuccess.hasErrors, true);
      expect(partialSuccess.hasPartialSuccess, true);
    });
  });
}