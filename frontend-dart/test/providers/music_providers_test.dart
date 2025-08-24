import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:music_room/providers/music_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/services/player_services.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';

@GenerateMocks([ApiService, MusicPlayerService, AuthProvider])
import 'music_providers_test.mocks.dart';

void main() {
  group('MusicProvider Tests', () {
    late MusicProvider musicProvider;
    late MockApiService mockApiService;
    late MockMusicPlayerService mockPlayerService;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      GetIt.instance.reset();
      mockApiService = MockApiService();
      mockPlayerService = MockMusicPlayerService();
      mockAuthProvider = MockAuthProvider();
      
      getIt.registerSingleton<ApiService>(mockApiService);
      getIt.registerSingleton<MusicPlayerService>(mockPlayerService);
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
      expect(musicProvider.currentTrack, isNull);
      expect(musicProvider.isPlaying, isFalse);
      expect(musicProvider.currentPosition, Duration.zero);
      expect(musicProvider.totalDuration, Duration.zero);
      expect(musicProvider.playlist, isEmpty);
      expect(musicProvider.currentIndex, -1);
      expect(musicProvider.isShuffled, isFalse);
      expect(musicProvider.repeatMode, RepeatMode.none);
    });

    test('should search tracks successfully', () async {
      final testTracks = [
        Track(id: '1', title: 'Test Song 1', artist: 'Artist 1', duration: 180),
        Track(id: '2', title: 'Test Song 2', artist: 'Artist 2', duration: 220),
      ];
      
      when(mockApiService.searchTracks(any, any)).thenAnswer((_) async => TrackSearchResponse(tracks: testTracks));
      
      await musicProvider.searchTracks('test query');
      
      expect(musicProvider.searchResults, hasLength(2));
      expect(musicProvider.searchResults.first.title, 'Test Song 1');
      verify(mockApiService.searchTracks('test_token', 'test query')).called(1);
    });

    test('should handle search tracks error', () async {
      when(mockApiService.searchTracks(any, any)).thenThrow(Exception('API Error'));
      
      await musicProvider.searchTracks('test query');
      
      expect(musicProvider.searchResults, isEmpty);
      expect(musicProvider.hasError, isTrue);
      verify(mockApiService.searchTracks('test_token', 'test query')).called(1);
    });

    test('should play track successfully', () async {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist', duration: 180);
      when(mockPlayerService.play(any)).thenAnswer((_) async {});
      when(mockPlayerService.isPlaying).thenReturn(true);
      
      await musicProvider.playTrack(track);
      
      expect(musicProvider.currentTrack, equals(track));
      expect(musicProvider.isPlaying, isTrue);
      verify(mockPlayerService.play(track.url)).called(1);
    });

    test('should handle play track error', () async {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist', duration: 180);
      when(mockPlayerService.play(any)).thenThrow(Exception('Player Error'));
      
      await musicProvider.playTrack(track);
      
      expect(musicProvider.hasError, isTrue);
      verify(mockPlayerService.play(track.url)).called(1);
    });

    test('should pause playback successfully', () async {
      when(mockPlayerService.pause()).thenAnswer((_) async {});
      when(mockPlayerService.isPlaying).thenReturn(false);
      
      await musicProvider.pausePlayback();
      
      expect(musicProvider.isPlaying, isFalse);
      verify(mockPlayerService.pause()).called(1);
    });

    test('should resume playback successfully', () async {
      when(mockPlayerService.resume()).thenAnswer((_) async {});
      when(mockPlayerService.isPlaying).thenReturn(true);
      
      await musicProvider.resumePlayback();
      
      expect(musicProvider.isPlaying, isTrue);
      verify(mockPlayerService.resume()).called(1);
    });

    test('should stop playback successfully', () async {
      when(mockPlayerService.stop()).thenAnswer((_) async {});
      when(mockPlayerService.isPlaying).thenReturn(false);
      
      await musicProvider.stopPlayback();
      
      expect(musicProvider.isPlaying, isFalse);
      expect(musicProvider.currentTrack, isNull);
      expect(musicProvider.currentPosition, Duration.zero);
      verify(mockPlayerService.stop()).called(1);
    });

    test('should seek to position successfully', () async {
      const seekPosition = Duration(seconds: 30);
      when(mockPlayerService.seek(any)).thenAnswer((_) async {});
      when(mockPlayerService.position).thenReturn(seekPosition);
      
      await musicProvider.seekTo(seekPosition);
      
      expect(musicProvider.currentPosition, equals(seekPosition));
      verify(mockPlayerService.seek(seekPosition)).called(1);
    });

    test('should set volume successfully', () async {
      const volume = 0.8;
      when(mockPlayerService.setVolume(any)).thenAnswer((_) async {});
      
      await musicProvider.setVolume(volume);
      
      verify(mockPlayerService.setVolume(volume)).called(1);
    });

    test('should load playlist successfully', () async {
      final testPlaylist = [
        Track(id: '1', title: 'Song 1', artist: 'Artist 1', duration: 180),
        Track(id: '2', title: 'Song 2', artist: 'Artist 2', duration: 220),
        Track(id: '3', title: 'Song 3', artist: 'Artist 3', duration: 200),
      ];
      
      musicProvider.loadPlaylist(testPlaylist);
      
      expect(musicProvider.playlist, hasLength(3));
      expect(musicProvider.playlist.first.title, 'Song 1');
      expect(musicProvider.currentIndex, -1);
    });

    test('should play next track in playlist', () async {
      final testPlaylist = [
        Track(id: '1', title: 'Song 1', artist: 'Artist 1', duration: 180),
        Track(id: '2', title: 'Song 2', artist: 'Artist 2', duration: 220),
      ];
      
      musicProvider.loadPlaylist(testPlaylist);
      musicProvider.currentIndex = 0;
      
      when(mockPlayerService.play(any)).thenAnswer((_) async {});
      when(mockPlayerService.isPlaying).thenReturn(true);
      
      await musicProvider.playNext();
      
      expect(musicProvider.currentIndex, 1);
      expect(musicProvider.currentTrack?.title, 'Song 2');
      verify(mockPlayerService.play(any)).called(1);
    });

    test('should play previous track in playlist', () async {
      final testPlaylist = [
        Track(id: '1', title: 'Song 1', artist: 'Artist 1', duration: 180),
        Track(id: '2', title: 'Song 2', artist: 'Artist 2', duration: 220),
      ];
      
      musicProvider.loadPlaylist(testPlaylist);
      musicProvider.currentIndex = 1;
      
      when(mockPlayerService.play(any)).thenAnswer((_) async {});
      when(mockPlayerService.isPlaying).thenReturn(true);
      
      await musicProvider.playPrevious();
      
      expect(musicProvider.currentIndex, 0);
      expect(musicProvider.currentTrack?.title, 'Song 1');
      verify(mockPlayerService.play(any)).called(1);
    });

    test('should toggle shuffle mode', () {
      expect(musicProvider.isShuffled, isFalse);
      
      musicProvider.toggleShuffle();
      expect(musicProvider.isShuffled, isTrue);
      
      musicProvider.toggleShuffle();
      expect(musicProvider.isShuffled, isFalse);
    });

    test('should cycle repeat modes', () {
      expect(musicProvider.repeatMode, RepeatMode.none);
      
      musicProvider.toggleRepeat();
      expect(musicProvider.repeatMode, RepeatMode.playlist);
      
      musicProvider.toggleRepeat();
      expect(musicProvider.repeatMode, RepeatMode.track);
      
      musicProvider.toggleRepeat();
      expect(musicProvider.repeatMode, RepeatMode.none);
    });

    test('should add track to favorites successfully', () async {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist', duration: 180);
      when(mockApiService.addToFavorites(any, any)).thenAnswer((_) async => FavoriteResponse(success: true));
      
      final result = await musicProvider.addToFavorites(track);
      
      expect(result, isTrue);
      verify(mockApiService.addToFavorites('test_token', '1')).called(1);
    });

    test('should handle add to favorites error', () async {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist', duration: 180);
      when(mockApiService.addToFavorites(any, any)).thenThrow(Exception('API Error'));
      
      final result = await musicProvider.addToFavorites(track);
      
      expect(result, isFalse);
      expect(musicProvider.hasError, isTrue);
      verify(mockApiService.addToFavorites('test_token', '1')).called(1);
    });

    test('should remove track from favorites successfully', () async {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist', duration: 180);
      when(mockApiService.removeFromFavorites(any, any)).thenAnswer((_) async => FavoriteResponse(success: true));
      
      final result = await musicProvider.removeFromFavorites(track);
      
      expect(result, isTrue);
      verify(mockApiService.removeFromFavorites('test_token', '1')).called(1);
    });

    test('should clear search results', () {
      musicProvider.searchResults.add(Track(id: '1', title: 'Test', artist: 'Artist', duration: 180));
      expect(musicProvider.searchResults, isNotEmpty);
      
      musicProvider.clearSearchResults();
      
      expect(musicProvider.searchResults, isEmpty);
    });

    test('should get track by id', () {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist', duration: 180);
      musicProvider.playlist.add(track);
      
      final foundTrack = musicProvider.getTrackById('1');
      expect(foundTrack, equals(track));
      
      final notFoundTrack = musicProvider.getTrackById('999');
      expect(notFoundTrack, isNull);
    });

    test('should handle playback position updates', () {
      const newPosition = Duration(seconds: 45);
      
      musicProvider.updatePosition(newPosition);
      
      expect(musicProvider.currentPosition, equals(newPosition));
    });

    test('should handle playback duration updates', () {
      const newDuration = Duration(seconds: 240);
      
      musicProvider.updateDuration(newDuration);
      
      expect(musicProvider.totalDuration, equals(newDuration));
    });

    test('should handle playback state changes', () {
      musicProvider.updatePlayingState(true);
      expect(musicProvider.isPlaying, isTrue);
      
      musicProvider.updatePlayingState(false);
      expect(musicProvider.isPlaying, isFalse);
    });

    test('should calculate progress percentage correctly', () {
      musicProvider.updateDuration(const Duration(seconds: 100));
      musicProvider.updatePosition(const Duration(seconds: 25));
      
      expect(musicProvider.progressPercentage, 0.25);
    });

    test('should handle zero duration for progress', () {
      musicProvider.updateDuration(Duration.zero);
      musicProvider.updatePosition(const Duration(seconds: 25));
      
      expect(musicProvider.progressPercentage, 0.0);
    });

    test('should notify listeners on state changes', () {
      var notified = false;
      musicProvider.addListener(() => notified = true);
      
      musicProvider.updatePlayingState(true);
      
      expect(notified, isTrue);
    });
  });
}

class Track {
  final String id;
  final String title;
  final String artist;
  final int duration;
  final String? url;
  
  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    this.url,
  });
}

class TrackSearchResponse {
  final List<Track> tracks;
  TrackSearchResponse({required this.tracks});
}

class FavoriteResponse {
  final bool success;
  FavoriteResponse({required this.success});
}

enum RepeatMode { none, playlist, track }
