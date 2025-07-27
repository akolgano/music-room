import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:music_room/services/music_player_service.dart';
import 'package:music_room/providers/dynamic_theme_provider.dart';
import 'package:music_room/services/api_service.dart';
import 'package:music_room/services/music_service.dart';
void main() {
  group('Music Player Service Tests', () {
    late MusicPlayerService musicPlayerService;
    late DynamicThemeProvider themeProvider;
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      GetIt.instance.reset();
      
      final dio = Dio();
      dio.options.baseUrl = 'http://localhost:8000';
      final apiService = ApiService(dio);
      final musicService = MusicService(apiService);
      
      GetIt.instance.registerSingleton<ApiService>(apiService);
      GetIt.instance.registerSingleton<MusicService>(musicService);
      
      themeProvider = DynamicThemeProvider();
      musicPlayerService = MusicPlayerService(themeProvider: themeProvider);
    });
    tearDown(() {
      musicPlayerService.dispose();
    });
    test('MusicPlayerService should be instantiable', () {
      expect(musicPlayerService, isA<MusicPlayerService>());
    });
    test('MusicPlayerService should have initial state', () {
      expect(musicPlayerService.currentTrack, null);
      expect(musicPlayerService.isPlaying, false);
      expect(musicPlayerService.position, Duration.zero);
      expect(musicPlayerService.duration, Duration.zero);
      expect(musicPlayerService.currentIndex, -1);
      expect(musicPlayerService.playlist, isEmpty);
    });
    test('MusicPlayerService should handle shuffle and repeat modes', () {
      expect(musicPlayerService.isShuffleMode, false);
      expect(musicPlayerService.isRepeatMode, false);
      
      musicPlayerService.toggleShuffle();
      expect(musicPlayerService.isShuffleMode, true);
      
      musicPlayerService.toggleRepeat();
      expect(musicPlayerService.isRepeatMode, true);
    });
    test('MusicPlayerService should handle playlist state', () {
      expect(musicPlayerService.hasPlaylist, false);
      expect(musicPlayerService.hasPreviousTrack, false);
      expect(musicPlayerService.hasNextTrack, false);
      expect(musicPlayerService.playlistId, null);
    });
    test('MusicPlayerService should provide track info', () {
      expect(musicPlayerService.currentTrackInfo, '');
    });
    test('MusicPlayerService should handle Deezer integration', () {
      expect(musicPlayerService.isUsingFullAudio, false);
      expect(musicPlayerService.canPlayFullAudio, isA<bool>());
    });
    test('MusicPlayerService should clear playlist', () {
      musicPlayerService.clearPlaylist();
      
      expect(musicPlayerService.playlist, isEmpty);
      expect(musicPlayerService.currentIndex, -1);
      expect(musicPlayerService.playlistId, null);
    });
    test('MusicPlayerService should handle track replacement callback', () {
      String? originalTrack;
      String? replacementTrack;
      
      musicPlayerService.setTrackReplacedCallback((original, replacement) {
        originalTrack = original;
        replacementTrack = replacement;
      });
      
      expect(originalTrack, null);
      expect(replacementTrack, null);
    });
    test('MusicPlayerService should dispose properly', () {
      final testService = MusicPlayerService(themeProvider: DynamicThemeProvider());
      expect(() => testService.dispose(), returnsNormally);
    });
  });
}