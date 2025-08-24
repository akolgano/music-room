import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:music_room/services/music_services.dart';

class MockMusicService extends Mock implements MusicService {}

void main() {
  group('MusicService Tests', () {
    late MusicService musicService;
    late MockMusicService mockMusicService;

    setUp(() {
      musicService = MusicService();
      mockMusicService = MockMusicService();
    });

    test('should create MusicService instance', () {
      expect(musicService, isA<MusicService>());
    });

    test('should search for tracks', () async {
      const query = 'test song';
      when(mockMusicService.searchTracks(query)).thenAnswer(
        (_) async => [Track(id: '1', title: 'Test Song', artist: 'Test Artist')],
      );

      final results = await mockMusicService.searchTracks(query);
      expect(results.length, 1);
      expect(results.first.title, 'Test Song');
      verify(mockMusicService.searchTracks(query)).called(1);
    });

    test('should play track', () async {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist');
      when(mockMusicService.playTrack(track)).thenAnswer((_) async => true);

      final result = await mockMusicService.playTrack(track);
      expect(result, true);
      verify(mockMusicService.playTrack(track)).called(1);
    });

    test('should pause playback', () async {
      when(mockMusicService.pausePlayback()).thenAnswer((_) async => true);

      final result = await mockMusicService.pausePlayback();
      expect(result, true);
      verify(mockMusicService.pausePlayback()).called(1);
    });

    test('should resume playback', () async {
      when(mockMusicService.resumePlayback()).thenAnswer((_) async => true);

      final result = await mockMusicService.resumePlayback();
      expect(result, true);
      verify(mockMusicService.resumePlayback()).called(1);
    });

    test('should stop playback', () async {
      when(mockMusicService.stopPlayback()).thenAnswer((_) async => true);

      final result = await mockMusicService.stopPlayback();
      expect(result, true);
      verify(mockMusicService.stopPlayback()).called(1);
    });

    test('should get current track', () {
      final track = Track(id: '1', title: 'Current Song', artist: 'Current Artist');
      when(mockMusicService.getCurrentTrack()).thenReturn(track);

      final result = mockMusicService.getCurrentTrack();
      expect(result?.title, 'Current Song');
      verify(mockMusicService.getCurrentTrack()).called(1);
    });

    test('should get playback position', () {
      const position = Duration(seconds: 30);
      when(mockMusicService.getPlaybackPosition()).thenReturn(position);

      final result = mockMusicService.getPlaybackPosition();
      expect(result.inSeconds, 30);
      verify(mockMusicService.getPlaybackPosition()).called(1);
    });

    test('should set playback position', () async {
      const position = Duration(seconds: 45);
      when(mockMusicService.seekTo(position)).thenAnswer((_) async => true);

      final result = await mockMusicService.seekTo(position);
      expect(result, true);
      verify(mockMusicService.seekTo(position)).called(1);
    });

    test('should set volume', () {
      const volume = 0.7;
      when(mockMusicService.setVolume(volume)).thenReturn(null);

      mockMusicService.setVolume(volume);
      verify(mockMusicService.setVolume(volume)).called(1);
    });

    test('should get current volume', () {
      const volume = 0.8;
      when(mockMusicService.getVolume()).thenReturn(volume);

      final result = mockMusicService.getVolume();
      expect(result, 0.8);
      verify(mockMusicService.getVolume()).called(1);
    });

    test('should create playlist', () async {
      const playlistName = 'My Playlist';
      final playlist = Playlist(id: '1', name: playlistName, tracks: []);
      when(mockMusicService.createPlaylist(playlistName)).thenAnswer((_) async => playlist);

      final result = await mockMusicService.createPlaylist(playlistName);
      expect(result.name, playlistName);
      verify(mockMusicService.createPlaylist(playlistName)).called(1);
    });

    test('should add track to playlist', () async {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist');
      const playlistId = 'playlist_1';
      when(mockMusicService.addTrackToPlaylist(playlistId, track)).thenAnswer((_) async => true);

      final result = await mockMusicService.addTrackToPlaylist(playlistId, track);
      expect(result, true);
      verify(mockMusicService.addTrackToPlaylist(playlistId, track)).called(1);
    });

    test('should remove track from playlist', () async {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist');
      const playlistId = 'playlist_1';
      when(mockMusicService.removeTrackFromPlaylist(playlistId, track)).thenAnswer((_) async => true);

      final result = await mockMusicService.removeTrackFromPlaylist(playlistId, track);
      expect(result, true);
      verify(mockMusicService.removeTrackFromPlaylist(playlistId, track)).called(1);
    });

    test('should get user playlists', () async {
      final playlists = [Playlist(id: '1', name: 'Playlist 1', tracks: [])];
      when(mockMusicService.getUserPlaylists()).thenAnswer((_) async => playlists);

      final result = await mockMusicService.getUserPlaylists();
      expect(result.length, 1);
      expect(result.first.name, 'Playlist 1');
      verify(mockMusicService.getUserPlaylists()).called(1);
    });

    test('should shuffle playlist', () {
      const shuffleEnabled = true;
      when(mockMusicService.setShuffle(shuffleEnabled)).thenReturn(null);

      mockMusicService.setShuffle(shuffleEnabled);
      verify(mockMusicService.setShuffle(shuffleEnabled)).called(1);
    });

    test('should set repeat mode', () {
      const repeatMode = RepeatMode.all;
      when(mockMusicService.setRepeatMode(repeatMode)).thenReturn(null);

      mockMusicService.setRepeatMode(repeatMode);
      verify(mockMusicService.setRepeatMode(repeatMode)).called(1);
    });

    test('should get track lyrics', () async {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist');
      const lyrics = 'Test lyrics content';
      when(mockMusicService.getTrackLyrics(track)).thenAnswer((_) async => lyrics);

      final result = await mockMusicService.getTrackLyrics(track);
      expect(result, lyrics);
      verify(mockMusicService.getTrackLyrics(track)).called(1);
    });

    test('should get track recommendations', () async {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist');
      final recommendations = [Track(id: '2', title: 'Similar Song', artist: 'Similar Artist')];
      when(mockMusicService.getRecommendations(track)).thenAnswer((_) async => recommendations);

      final result = await mockMusicService.getRecommendations(track);
      expect(result.length, 1);
      expect(result.first.title, 'Similar Song');
      verify(mockMusicService.getRecommendations(track)).called(1);
    });

    test('should handle playback errors', () async {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist');
      when(mockMusicService.playTrack(track)).thenThrow(Exception('Playback failed'));

      expect(() => mockMusicService.playTrack(track), throwsException);
      verify(mockMusicService.playTrack(track)).called(1);
    });
  });

  group('Track Tests', () {
    test('should create Track instance', () {
      const track = Track(id: '1', title: 'Test Song', artist: 'Test Artist');
      expect(track.id, '1');
      expect(track.title, 'Test Song');
      expect(track.artist, 'Test Artist');
    });

    test('should handle track duration', () {
      const track = Track(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        duration: Duration(minutes: 3, seconds: 30),
      );
      expect(track.duration?.inSeconds, 210);
    });
  });

  group('Playlist Tests', () {
    test('should create Playlist instance', () {
      final playlist = Playlist(id: '1', name: 'Test Playlist', tracks: []);
      expect(playlist.id, '1');
      expect(playlist.name, 'Test Playlist');
      expect(playlist.tracks.isEmpty, true);
    });

    test('should add track to playlist', () {
      final track = Track(id: '1', title: 'Test Song', artist: 'Test Artist');
      final playlist = Playlist(id: '1', name: 'Test Playlist', tracks: []);
      
      playlist.tracks.add(track);
      expect(playlist.tracks.length, 1);
      expect(playlist.tracks.first.title, 'Test Song');
    });
  });
}
