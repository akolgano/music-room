import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/music_models.dart';
void main() {
  group('Music Models Tests', () {
    group('User', () {
      test('should create User from JSON', () {
        final json = {
          'id': '123',
          'username': 'testuser',
          'email': 'test@example.com'
        };
        
        final user = User.fromJson(json);
        
        expect(user.id, '123');
        expect(user.username, 'testuser');
        expect(user.email, 'test@example.com');
      });
      test('should convert User to JSON', () {
        const user = User(
          id: '123', 
          username: 'testuser', 
          email: 'test@example.com'
        );
        
        final json = user.toJson();
        
        expect(json['id'], '123');
        expect(json['username'], 'testuser');
        expect(json['email'], 'test@example.com');
      });
    });
    group('Track', () {
      test('should create Track from JSON', () {
        final json = {
          'id': 'track123',
          'name': 'Test Song',
          'artist': 'Test Artist',
          'album': 'Test Album',
          'url': 'http://example.com/track123'
        };
        
        final track = Track.fromJson(json);
        
        expect(track.id, 'track123');
        expect(track.name, 'Test Song');
        expect(track.artist, 'Test Artist');
        expect(track.album, 'Test Album');
        expect(track.url, 'http://example.com/track123');
      });
      test('should identify Deezer track correctly', () {
        const track = Track(
          id: 'deezer_123',
          name: 'Test Song',
          artist: 'Test Artist',
          album: 'Test Album',
          url: 'http://example.com/track',
          deezerTrackId: '123'
        );
        
        expect(track.isDeezerTrack, true);
        expect(track.backendId, '123');
        expect(track.frontendId, 'deezer_123');
      });
      test('should convert frontend ID correctly', () {
        expect(Track.toFrontendId('123', isDeezer: true), 'deezer_123');
        expect(Track.toFrontendId('regular_track'), 'regular_track');
      });
    });
    group('Playlist', () {
      test('should create Playlist from JSON', () {
        final json = {
          'id': 'playlist123',
          'name': 'Test Playlist',
          'description': 'A test playlist',
          'public': true,
          'creator': 'testuser',
          'tracks': []
        };
        
        final playlist = Playlist.fromJson(json);
        
        expect(playlist.id, 'playlist123');
        expect(playlist.name, 'Test Playlist');
        expect(playlist.description, 'A test playlist');
        expect(playlist.isPublic, true);
        expect(playlist.creator, 'testuser');
        expect(playlist.tracks, isEmpty);
      });
      test('should convert Playlist to JSON', () {
        const playlist = Playlist(
          id: 'playlist123',
          name: 'Test Playlist',
          description: 'A test playlist',
          isPublic: true,
          creator: 'testuser'
        );
        
        final json = playlist.toJson();
        
        expect(json['id'], 'playlist123');
        expect(json['name'], 'Test Playlist');
        expect(json['description'], 'A test playlist');
        expect(json['public'], true);
        expect(json['creator'], 'testuser');
      });
    });
    group('PlaylistTrack', () {
      test('should create PlaylistTrack from JSON', () {
        final json = {
          'track_id': 'track123',
          'name': 'Test Song',
          'position': 1,
          'points': 5
        };
        
        final playlistTrack = PlaylistTrack.fromJson(json);
        
        expect(playlistTrack.trackId, 'track123');
        expect(playlistTrack.name, 'Test Song');
        expect(playlistTrack.position, 1);
        expect(playlistTrack.points, 5);
      });
      test('should identify when track details are needed', () {
        const track = Track(
          id: 'deezer_123',
          name: 'Test Song',
          artist: '',
          album: 'Test Album',
          url: 'http://example.com/track',
          deezerTrackId: '123'
        );
        
        const playlistTrack = PlaylistTrack(
          trackId: 'track123',
          name: 'Test Song',
          position: 1,
          track: track
        );
        
        expect(playlistTrack.needsTrackDetails, true);
      });
      test('should provide display properties', () {
        const track = Track(
          id: 'track123',
          name: 'Test Song',
          artist: 'Test Artist',
          album: 'Test Album',
          url: 'http://example.com/track'
        );
        
        const playlistTrack = PlaylistTrack(
          trackId: 'track123',
          name: 'Fallback Name',
          position: 1,
          track: track
        );
        
        expect(playlistTrack.displayName, 'Test Song');
        expect(playlistTrack.displayArtist, 'Test Artist');
        expect(playlistTrack.displayAlbum, 'Test Album');
      });
      test('should copy with new track', () {
        const originalTrack = Track(
          id: 'track123',
          name: 'Original Song',
          artist: 'Original Artist',
          album: 'Original Album',
          url: 'http://example.com/track'
        );
        
        const newTrack = Track(
          id: 'track456',
          name: 'New Song',
          artist: 'New Artist',
          album: 'New Album',
          url: 'http://example.com/track'
        );
        
        const playlistTrack = PlaylistTrack(
          trackId: 'track123',
          name: 'Test Name',
          position: 1,
          points: 5,
          track: originalTrack
        );
        
        final updatedTrack = playlistTrack.copyWithTrack(newTrack);
        
        expect(updatedTrack.track, newTrack);
        expect(updatedTrack.trackId, 'track123');
        expect(updatedTrack.position, 1);
        expect(updatedTrack.points, 5);
      });
    });
    group('PlaylistInfoWithVotes', () {
      test('should create PlaylistInfoWithVotes from JSON', () {
        final json = {
          'id': 123,
          'playlist_name': 'Voting Playlist',
          'description': 'A playlist with voting',
          'public': true,
          'creator': 'testuser',
          'tracks': []
        };
        
        final playlistInfo = PlaylistInfoWithVotes.fromJson(json);
        
        expect(playlistInfo.id, 123);
        expect(playlistInfo.playlistName, 'Voting Playlist');
        expect(playlistInfo.description, 'A playlist with voting');
        expect(playlistInfo.public, true);
        expect(playlistInfo.creator, 'testuser');
        expect(playlistInfo.tracks, isEmpty);
      });
      test('should convert PlaylistInfoWithVotes to JSON', () {
        const playlistInfo = PlaylistInfoWithVotes(
          id: 123,
          playlistName: 'Voting Playlist',
          description: 'A playlist with voting',
          public: true,
          creator: 'testuser',
          tracks: []
        );
        
        final json = playlistInfo.toJson();
        
        expect(json['id'], 123);
        expect(json['playlist_name'], 'Voting Playlist');
        expect(json['description'], 'A playlist with voting');
        expect(json['public'], true);
        expect(json['creator'], 'testuser');
        expect(json['tracks'], isEmpty);
      });
    });
  });
}