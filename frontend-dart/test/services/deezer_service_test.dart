import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/services/deezer_service.dart';

void main() {
  group('Deezer Service Tests', () {
    late DeezerService deezerService;

    setUp(() {
      deezerService = DeezerService.instance;
      deezerService.dispose();
    });

    test('DeezerService should be a singleton', () {
      final instance1 = DeezerService.instance;
      final instance2 = DeezerService.instance;
      
      expect(instance1, same(instance2));
    });

    test('DeezerService should initialize without ARL token', () async {
      final result = await deezerService.initialize();
      
      expect(result, false);
      expect(deezerService.isInitialized, false);
      expect(deezerService.canPlayFullAudio, false);
    });

    test('DeezerService should handle invalid ARL token', () async {
      final result = await deezerService.initialize(arl: 'invalid_short_token');
      
      expect(result, false);
      expect(deezerService.isInitialized, false);
    });

    test('DeezerService should initialize with valid ARL token', () async {
      final validArl = 'a' * 60;
      final result = await deezerService.initialize(arl: validArl);
      
      expect(result, true);
      expect(deezerService.isInitialized, true);
      expect(deezerService.canPlayFullAudio, true);
    });

    test('DeezerService should throw when getting stream URL without initialization', () async {
      expect(
        () => deezerService.getTrackStreamUrl('123'),
        throwsA(isA<Exception>()),
      );
    });

    test('DeezerService should handle track availability check', () async {
      expect(await deezerService.isTrackAvailable('123'), false);
      
      await deezerService.initialize(arl: 'a' * 60);
      expect(await deezerService.isTrackAvailable('123'), true);
    });

    test('DeezerService should handle track info request', () async {
      expect(await deezerService.getTrackInfo('123'), null);
      
      await deezerService.initialize(arl: 'a' * 60);
      expect(await deezerService.getTrackInfo('123'), null);
    });

    test('DeezerService should dispose properly', () {
      deezerService.dispose();
      
      expect(deezerService.isInitialized, false);
      expect(deezerService.canPlayFullAudio, false);
    });
  });
}