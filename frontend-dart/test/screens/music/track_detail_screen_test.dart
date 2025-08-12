import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/screens/music/detail_music.dart';
import 'package:music_room/models/music_models.dart';
void main() {
  group('Track Detail Screen Tests', () {
    test('TrackDetailScreen should be instantiable', () {
      const screen = TrackDetailScreen();
      expect(screen, isA<TrackDetailScreen>());
    });
    test('TrackDetailScreen should be a StatefulWidget', () {
      const screen = TrackDetailScreen();
      expect(screen, isA<StatefulWidget>());
    });
    test('TrackDetailScreen should handle track data correctly', () {
      const track = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'http://localhost:8000/api/track',
      );
      
      expect(track.name, 'Test Song');
      expect(track.artist, 'Test Artist');
      expect(track.album, 'Test Album');
      expect(track.url, 'http://localhost:8000/api/track');
    });
    test('TrackDetailScreen should handle Deezer track identification', () {
      const deezerTrack = Track(
        id: 'deezer_123',
        name: 'Deezer Song',
        artist: 'Artist',
        album: 'Album',
        url: 'http://localhost:8000/api/track',
        deezerTrackId: '123',
      );
      
      expect(deezerTrack.isDeezerTrack, true);
      expect(deezerTrack.backendId, '123');
    });
    test('TrackDetailScreen should create state correctly', () {
      const screen = TrackDetailScreen();
      final state = screen.createState();
      expect(state, isA<State<TrackDetailScreen>>());
    });
    test('TrackDetailScreen should handle key parameter', () {
      const key = Key('track_detail_key');
      const screen = TrackDetailScreen(key: key);
      expect(screen.key, key);
    });
    test('Track model should handle empty fields gracefully', () {
      const track = Track(
        id: '1',
        name: '',
        artist: '',
        album: '',
        url: ''
      );
      
      expect(track.id, '1');
      expect(track.name, '');
      expect(track.artist, '');
      expect(track.album, '');
      expect(track.url, '');
    });
    test('Track model should serialize to JSON correctly', () {
      const track = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'http://localhost:8000/api/track',
      );
      
      final json = track.toJson();
      expect(json['id'], '1');
      expect(json['name'], 'Test Song');
      expect(json['artist'], 'Test Artist');
      expect(json['album'], 'Test Album');
      expect(json['url'], 'http://localhost:8000/api/track');
    });
  });
}