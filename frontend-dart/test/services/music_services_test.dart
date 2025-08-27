import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:music_room/services/music_services.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/models/api_models.dart';

import 'music_services_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  group('MusicService Tests', () {
    late MusicService musicService;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      musicService = MusicService(mockApiService);
    });

    test('should create MusicService instance', () {
      expect(musicService, isA<MusicService>());
    });

    test('should search for tracks', () async {
      const query = 'test song';
      const token = 'test-token';
      final mockResponse = SearchTracksResponse(
        data: [Track(id: '1', name: 'Test Song', artist: 'Test Artist', album: 'Test Album', url: 'https://test.com')],
      );
      
      when(mockApiService.searchTracks(query, token))
          .thenAnswer((_) async => mockResponse);

      final results = await musicService.searchTracks(query, token);
      expect(results.length, 1);
      expect(results.first.name, 'Test Song');
      verify(mockApiService.searchTracks(query, token)).called(1);
    });

    test('should create playlist', () async {
      const playlistName = 'My Playlist';
      const description = 'Test description';
      const token = 'test-token';
      final mockResponse = CreatePlaylistResponse(playlistId: '1');
      
      when(mockApiService.createPlaylist(
          token,
          argThat(isA<CreatePlaylistRequest>()
              .having((r) => r.name, 'name', playlistName)
              .having((r) => r.description, 'description', description))))
          .thenAnswer((_) async => mockResponse);

      final result = await musicService.createPlaylist(playlistName, description, true, token, 'open', false);
      expect(result, '1');
    });

    test('should add track to playlist', () async {
      const trackId = '1';
      const playlistId = 'playlist_1';
      const token = 'test-token';
      
      when(mockApiService.addTrackToPlaylist(
          playlistId,
          token,
          argThat(isA<AddTrackRequest>()
              .having((r) => r.trackId, 'trackId', trackId))))
          .thenAnswer((_) async {});

      await musicService.addTrackToPlaylist(playlistId, trackId, token);
      verify(mockApiService.addTrackToPlaylist(playlistId, token, any)).called(1);
    });

    test('should remove track from playlist', () async {
      const trackId = '1';
      const playlistId = 'playlist_1';
      const token = 'test-token';
      
      when(mockApiService.removeTrackFromPlaylist(playlistId, trackId, token))
          .thenAnswer((_) async {});

      await musicService.removeTrackFromPlaylist(playlistId, trackId, token);
      verify(mockApiService.removeTrackFromPlaylist(playlistId, trackId, token)).called(1);
    });

    test('should get user playlists', () async {
      const token = 'test-token';
      final playlists = [Playlist(id: '1', name: 'Playlist 1', description: 'Test', isPublic: true, creator: 'user1', tracks: [])];
      final mockResponse = GetPlaylistsResponse(playlists: playlists);
      
      when(mockApiService.getSavedPlaylists(token))
          .thenAnswer((_) async => mockResponse);

      final result = await musicService.getUserPlaylists(token);
      expect(result.length, 1);
      expect(result.first.name, 'Playlist 1');
      verify(mockApiService.getSavedPlaylists(token)).called(1);
    });

    test('should search Deezer tracks', () async {
      const query = 'test song';
      final mockResponse = SearchTracksResponse(
        data: [Track(id: 'deezer_1', name: 'Test Song', artist: 'Test Artist', album: 'Test Album', url: 'https://test.com', deezerTrackId: '1')],
      );
      
      when(mockApiService.searchDeezerTracks(query))
          .thenAnswer((_) async => mockResponse);

      final results = await musicService.searchDeezerTracks(query);
      expect(results.length, 1);
      expect(results.first.name, 'Test Song');
      expect(results.first.isDeezerTrack, true);
      verify(mockApiService.searchDeezerTracks(query)).called(1);
    });

    test('should get playlist details', () async {
      const playlistId = '1';
      const token = 'test-token';
      final playlist = Playlist(id: '1', name: 'Test Playlist', description: 'Test', isPublic: true, creator: 'user1', tracks: []);
      final mockResponse = GetPlaylistResponse(playlist: playlist);
      
      when(mockApiService.getPlaylist(playlistId, token))
          .thenAnswer((_) async => mockResponse);

      final result = await musicService.getPlaylistDetails(playlistId, token);
      expect(result.id, '1');
      expect(result.name, 'Test Playlist');
      verify(mockApiService.getPlaylist(playlistId, token)).called(1);
    });

    test('should move track in playlist', () async {
      const playlistId = 'playlist_1';
      const token = 'test-token';
      
      when(mockApiService.moveTrackInPlaylist(
          playlistId,
          token,
          argThat(isA<MoveTrackRequest>()
              .having((r) => r.rangeStart, 'rangeStart', 0)
              .having((r) => r.insertBefore, 'insertBefore', 2))))
          .thenAnswer((_) async {});

      await musicService.moveTrackInPlaylist(
        playlistId: playlistId,
        rangeStart: 0,
        insertBefore: 2,
        token: token,
      );
      
      verify(mockApiService.moveTrackInPlaylist(playlistId, token, any)).called(1);
    });
  });

  group('Track Tests', () {
    test('should create Track instance', () {
      const track = Track(
        id: '1', 
        name: 'Test Song', 
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://test.com'
      );
      expect(track.id, '1');
      expect(track.name, 'Test Song');
      expect(track.artist, 'Test Artist');
    });

    test('should handle Deezer track', () {
      const track = Track(
        id: 'deezer_123',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'https://test.com',
        deezerTrackId: '123'
      );
      expect(track.isDeezerTrack, true);
      expect(track.backendId, '123');
    });
  });

  group('Playlist Tests', () {
    test('should create Playlist instance', () {
      const playlist = Playlist(
        id: '1', 
        name: 'Test Playlist', 
        description: 'Test description',
        isPublic: true,
        creator: 'user1',
        tracks: []
      );
      expect(playlist.id, '1');
      expect(playlist.name, 'Test Playlist');
      expect(playlist.tracks.isEmpty, true);
    });

    test('should handle playlist with track', () {
      const track = Track(id: '1', name: 'Test Song', artist: 'Test Artist', album: 'Test Album', url: 'https://test.com');
      const playlist = Playlist(
        id: '1', 
        name: 'Test Playlist', 
        description: 'Test description',
        isPublic: true,
        creator: 'user1',
        tracks: [track]
      );
      
      expect(playlist.tracks.length, 1);
      expect(playlist.tracks.first.name, 'Test Song');
    });
  });

  group('TrackSortingService Tests', () {
    test('should sort tracks by name ascending', () {
      final tracks = [
        PlaylistTrack(trackId: '1', name: 'C Song', position: 0, points: 0, 
            track: const Track(id: '1', name: 'C Song', artist: 'Artist', album: 'Album', url: '')),
        PlaylistTrack(trackId: '2', name: 'A Song', position: 1, points: 0,
            track: const Track(id: '2', name: 'A Song', artist: 'Artist', album: 'Album', url: '')),
        PlaylistTrack(trackId: '3', name: 'B Song', position: 2, points: 0,
            track: const Track(id: '3', name: 'B Song', artist: 'Artist', album: 'Album', url: '')),
      ];

      final sortOption = TrackSortOption(field: TrackSortField.name, order: SortOrder.ascending);
      final sorted = TrackSortingService.sortTracks(tracks, sortOption);

      expect(sorted[0].name, 'A Song');
      expect(sorted[1].name, 'B Song');
      expect(sorted[2].name, 'C Song');
    });

    test('should filter tracks by search term', () {
      final tracks = [
        PlaylistTrack(trackId: '1', name: 'Rock Song', position: 0, points: 0,
            track: const Track(id: '1', name: 'Rock Song', artist: 'Rock Band', album: 'Rock Album', url: '')),
        PlaylistTrack(trackId: '2', name: 'Pop Song', position: 1, points: 0,
            track: const Track(id: '2', name: 'Pop Song', artist: 'Pop Star', album: 'Pop Album', url: '')),
        PlaylistTrack(trackId: '3', name: 'Jazz Tune', position: 2, points: 0,
            track: const Track(id: '3', name: 'Jazz Tune', artist: 'Jazz Ensemble', album: 'Jazz Collection', url: '')),
      ];

      final filtered = TrackSortingService.filterTracks(tracks, 'rock');

      expect(filtered.length, 1);
      expect(filtered.first.name, 'Rock Song');
    });
  });
}