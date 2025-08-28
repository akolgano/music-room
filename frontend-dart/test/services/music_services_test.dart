import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/music_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('MusicService Tests', () {
    setUp(() {
    });

    test('should handle track data models', () {
      final track = Track(
        id: '1',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://music.example.com/track/1',
      );
      
      expect(track.id, '1');
      expect(track.name, 'Test Song');
      expect(track.artist, 'Test Artist');
      expect(track.album, 'Test Album');
      expect(track.url, 'https://music.example.com/track/1');
    });

    test('should handle playlist data models', () {
      final playlist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'A test playlist',
        isPublic: true,
        creator: 'user123',
      );
      
      expect(playlist.id, '1');
      expect(playlist.name, 'Test Playlist');
      expect(playlist.description, 'A test playlist');
      expect(playlist.creator, 'user123');
      expect(playlist.isPublic, isTrue);
    });
  });
}