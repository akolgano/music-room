import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:music_room/providers/music_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/services/music_services.dart';
import 'package:music_room/services/cache_services.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';

import 'music_providers_test.mocks.dart';

@GenerateMocks([ApiService, MusicService, TrackCacheService, AuthProvider])
void main() {
  group('MusicProvider Tests', () {
    late MusicProvider musicProvider;
    late MockApiService mockApiService;
    late MockMusicService mockMusicService;
    late MockTrackCacheService mockTrackCacheService;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      GetIt.instance.reset();
      mockApiService = MockApiService();
      mockMusicService = MockMusicService();
      mockTrackCacheService = MockTrackCacheService();
      mockAuthProvider = MockAuthProvider();
      
      getIt.registerSingleton<ApiService>(mockApiService);
      getIt.registerSingleton<MusicService>(mockMusicService);
      getIt.registerSingleton<TrackCacheService>(mockTrackCacheService);
      getIt.registerSingleton<AuthProvider>(mockAuthProvider);
      
      when(mockAuthProvider.token).thenReturn('test_token');
      when(mockAuthProvider.authHeaders).thenReturn({
        'Content-Type': 'application/json',
        'Authorization': 'Token test_token'
      });
      
      musicProvider = MusicProvider();
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test('should initialize with default values', () {
      expect(musicProvider.playlists, isEmpty);
      expect(musicProvider.userPlaylists, isEmpty);
      expect(musicProvider.publicPlaylists, isEmpty);
      expect(musicProvider.searchResults, isEmpty);
      expect(musicProvider.playlistTracks, isEmpty);
      expect(musicProvider.hasConnectionError, isFalse);
    });

    test('should search tracks successfully', () async {
      final testTracks = [
        Track(
          id: '1', 
          name: 'Test Song 1', 
          artist: 'Artist 1', 
          album: 'Album 1',
          url: 'https://example.com/track1'
        ),
        Track(
          id: '2', 
          name: 'Test Song 2', 
          artist: 'Artist 2', 
          album: 'Album 2',
          url: 'https://example.com/track2'
        ),
      ];
      
      when(mockMusicService.searchTracks(any, any))
          .thenAnswer((_) async => testTracks);
      
      await musicProvider.searchTracks('test query', 'test_token');
      
      expect(musicProvider.searchResults, hasLength(2));
      expect(musicProvider.searchResults.first.name, 'Test Song 1');
      verify(mockMusicService.searchTracks('test_token', 'test query')).called(1);
    });

    test('should handle search tracks error', () async {
      when(mockMusicService.searchTracks(any, any))
          .thenThrow(Exception('API Error'));
      
      await musicProvider.searchTracks('test query', 'test_token');
      
      expect(musicProvider.searchResults, isEmpty);
      expect(musicProvider.hasError, isTrue);
      verify(mockMusicService.searchTracks('test_token', 'test query')).called(1);
    });

    test('should fetch user playlists successfully', () async {
      final testPlaylists = [
        Playlist(
          id: '1',
          name: 'My Playlist 1',
          createdAt: DateTime.now(),
          isPublic: false,
          owner: User(id: 'user1', username: 'testuser')
        ),
        Playlist(
          id: '2',
          name: 'My Playlist 2',
          createdAt: DateTime.now(),
          isPublic: false,
          owner: User(id: 'user1', username: 'testuser')
        ),
      ];
      
      when(mockMusicService.getUserPlaylists(any))
          .thenAnswer((_) async => testPlaylists);
      
      await musicProvider.fetchUserPlaylists('test_token');
      
      expect(musicProvider.userPlaylists, hasLength(2));
      expect(musicProvider.userPlaylists.first.name, 'My Playlist 1');
      verify(mockMusicService.getUserPlaylists('test_token')).called(1);
    });

    test('should handle fetch user playlists error', () async {
      when(mockMusicService.getUserPlaylists(any))
          .thenThrow(Exception('API Error'));
      
      await musicProvider.fetchUserPlaylists('test_token');
      
      expect(musicProvider.userPlaylists, isEmpty);
      expect(musicProvider.hasError, isTrue);
      verify(mockMusicService.getUserPlaylists('test_token')).called(1);
    });

    test('should fetch public playlists successfully', () async {
      final testPlaylists = [
        Playlist(
          id: '1',
          name: 'Public Playlist 1',
          createdAt: DateTime.now(),
          isPublic: true,
          owner: User(id: 'user1', username: 'publicuser')
        ),
      ];
      
      when(mockMusicService.getPublicPlaylists(any))
          .thenAnswer((_) async => testPlaylists);
      
      await musicProvider.fetchPublicPlaylists('test_token');
      
      expect(musicProvider.publicPlaylists, hasLength(1));
      expect(musicProvider.publicPlaylists.first.name, 'Public Playlist 1');
      verify(mockMusicService.getPublicPlaylists('test_token')).called(1);
    });

    test('should clear search results', () async {
      final testTracks = [
        Track(
          id: '1', 
          name: 'Test Song', 
          artist: 'Artist', 
          album: 'Album',
          url: 'https://example.com/track'
        ),
      ];
      
      when(mockMusicService.searchTracks(any, any))
          .thenAnswer((_) async => testTracks);
      
      await musicProvider.searchTracks('test', 'test_token');
      expect(musicProvider.searchResults, isNotEmpty);
      
      musicProvider.clearSearchResults();
      
      expect(musicProvider.searchResults, isEmpty);
    });

    test('should create playlist successfully', () async {
      final newPlaylist = Playlist(
        id: '1',
        name: 'New Playlist',
        createdAt: DateTime.now(),
        isPublic: false,
        owner: User(id: 'user1', username: 'testuser')
      );
      
      when(mockMusicService.createPlaylist(any, any, any))
          .thenAnswer((_) async => newPlaylist);
      
      final result = await musicProvider.createPlaylist(
        'New Playlist', 
        'test_token',
        isPublic: false
      );
      
      expect(result, isNotNull);
      expect(result?.name, 'New Playlist');
      verify(mockMusicService.createPlaylist('test_token', 'New Playlist', false))
          .called(1);
    });

    test('should delete playlist successfully', () async {
      when(mockApiService.deletePlaylist(any, any))
          .thenAnswer((_) async => true);
      
      final result = await musicProvider.deletePlaylist('playlist1', 'test_token');
      
      expect(result, isTrue);
      verify(mockApiService.deletePlaylist('test_token', 'playlist1')).called(1);
    });

    test('should add track to playlist successfully', () async {
      final track = Track(
        id: '1', 
        name: 'Test Song', 
        artist: 'Artist',
        album: 'Album',
        url: 'https://example.com/track'
      );
      
      when(mockMusicService.addTrackToPlaylist(any, any, any))
          .thenAnswer((_) async => true);
      
      final result = await musicProvider.addTrackToPlaylist(
        'playlist1', 
        track, 
        'test_token'
      );
      
      expect(result, isTrue);
      verify(mockMusicService.addTrackToPlaylist('test_token', 'playlist1', track))
          .called(1);
    });

    test('should remove track from playlist successfully', () async {
      when(mockMusicService.removeTrackFromPlaylist(any, any, any))
          .thenAnswer((_) async => true);
      
      final result = await musicProvider.removeTrackFromPlaylist(
        'playlist1', 
        'track1', 
        'test_token'
      );
      
      expect(result, isTrue);
      verify(mockMusicService.removeTrackFromPlaylist(
        'test_token', 
        'playlist1', 
        'track1'
      )).called(1);
    });

    test('should fetch playlist tracks successfully', () async {
      final testTracks = [
        PlaylistTrack(
          id: '1',
          name: 'Track 1',
          artist: 'Artist 1',
          album: 'Album 1',
          url: 'https://example.com/track1',
          order: 0,
          playlistTrackId: 'pt1'
        ),
        PlaylistTrack(
          id: '2',
          name: 'Track 2',
          artist: 'Artist 2',
          album: 'Album 2',
          url: 'https://example.com/track2',
          order: 1,
          playlistTrackId: 'pt2'
        ),
      ];
      
      when(mockMusicService.getPlaylistTracks(any, any))
          .thenAnswer((_) async => testTracks);
      
      await musicProvider.fetchPlaylistTracks('playlist1', 'test_token');
      
      expect(musicProvider.playlistTracks, hasLength(2));
      expect(musicProvider.playlistTracks.first.name, 'Track 1');
      verify(mockMusicService.getPlaylistTracks('test_token', 'playlist1'))
          .called(1);
    });

    test('should update playlist order successfully', () async {
      final trackIds = ['track1', 'track2', 'track3'];
      
      when(mockMusicService.updatePlaylistOrder(any, any, any))
          .thenAnswer((_) async => true);
      
      final result = await musicProvider.updatePlaylistOrder(
        'playlist1', 
        trackIds, 
        'test_token'
      );
      
      expect(result, isTrue);
      verify(mockMusicService.updatePlaylistOrder(
        'test_token', 
        'playlist1', 
        trackIds
      )).called(1);
    });

    test('should handle connection errors gracefully', () async {
      when(mockMusicService.getUserPlaylists(any))
          .thenThrow(Exception('Connection failed'));
      
      await musicProvider.fetchUserPlaylists('test_token');
      
      expect(musicProvider.hasError, isTrue);
      expect(musicProvider.userPlaylists, isEmpty);
    });

    test('should notify listeners on state changes', () {
      var notified = false;
      musicProvider.addListener(() => notified = true);
      
      musicProvider.clearSearchResults();
      
      expect(notified, isTrue);
    });
  });
}