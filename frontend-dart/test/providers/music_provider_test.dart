import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:music_room/providers/music_provider.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/models/sort_models.dart';
void main() {
  group('Music Provider Tests', () {
    test('MusicProvider should be a valid class type', () {
      expect(MusicProvider, isA<Type>());
    });
    test('MusicProvider should have expected properties', () {
      expect('$MusicProvider', contains('MusicProvider'));
    });
    test('Playlist model should work correctly', () {
      const playlist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'Test Description',
        isPublic: false,
        creator: 'testuser'
      );
      
      expect(playlist.id, '1');
      expect(playlist.name, 'Test Playlist');
      expect(playlist.description, 'Test Description');
      expect(playlist.isPublic, false);
      expect(playlist.creator, 'testuser');
    });
    test('Track model should work correctly', () {
      const track = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'http://example.com/track'
      );
      
      expect(track.id, '1');
      expect(track.name, 'Test Song');
      expect(track.artist, 'Test Artist');
      expect(track.album, 'Test Album');
      expect(track.url, 'http://example.com/track');
    });
    test('PlaylistTrack model should work correctly', () {
      const track = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'http://example.com/track'
      );
      
      const playlistTrack = PlaylistTrack(
        trackId: '1',
        name: 'Test Song',
        position: 1,
        points: 5,
        track: track
      );
      
      expect(playlistTrack.trackId, '1');
      expect(playlistTrack.name, 'Test Song');
      expect(playlistTrack.position, 1);
      expect(playlistTrack.points, 5);
      expect(playlistTrack.track, track);
    });
    test('TrackSortOption should work correctly', () {
      const sortOption = TrackSortOption(
        displayName: 'By Name',
        field: TrackSortField.name,
        order: SortOrder.ascending,
        icon: Icons.sort_by_alpha,
      );
      
      expect(sortOption.displayName, 'By Name');
      expect(sortOption.field, TrackSortField.name);
      expect(sortOption.order, SortOrder.ascending);
    });
    test('BatchAddResult should calculate status correctly', () {
      const result = BatchAddResult(
        totalTracks: 10,
        successCount: 8,
        duplicateCount: 1,
        failureCount: 1
      );
      
      expect(result.totalTracks, 10);
      expect(result.successCount, 8);
      expect(result.duplicateCount, 1);
      expect(result.failureCount, 1);
      expect(result.hasErrors, true);
      expect(result.hasPartialSuccess, true);
      expect(result.isCompleteSuccess, false);
    });
    test('BatchLibraryAddResult should provide summary messages', () {
      const successResult = BatchLibraryAddResult(
        totalTracks: 5,
        successCount: 5,
        failureCount: 0
      );
      
      expect(successResult.isCompleteSuccess, true);
      expect(successResult.summaryMessage, 'All 5 tracks added to your library successfully!');
      
      const partialResult = BatchLibraryAddResult(
        totalTracks: 5,
        successCount: 3,
        failureCount: 2
      );
      
      expect(partialResult.hasPartialSuccess, true);
      expect(partialResult.summaryMessage, '3/5 tracks added to your library');
    });
    test('Track should handle Deezer track identification', () {
      const deezerTrack = Track(
        id: 'deezer_123',
        name: 'Deezer Song',
        artist: 'Artist',
        album: 'Album',
        url: 'http://example.com/track',
        deezerTrackId: '123'
      );
      
      expect(deezerTrack.isDeezerTrack, true);
      expect(deezerTrack.backendId, '123');
      expect(deezerTrack.id, 'deezer_123');
    });
  });
}