import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/services/websocket_service.dart';

void main() {
  group('WebSocketService Tests', () {
    late WebSocketService webSocketService;

    setUp(() {
      webSocketService = WebSocketService();
    });

    tearDown(() {
      webSocketService.dispose();
    });

    test('WebSocketService should be instantiable', () {
      expect(webSocketService, isA<WebSocketService>());
    });

    test('should start disconnected', () {
      expect(webSocketService.isConnected, false);
    });

    test('should have empty stream when not connected', () {
      expect(webSocketService.rawMessageStream, isA<Stream<Map<String, dynamic>>>());
    });

    test('disconnect should not throw when not connected', () async {
      expect(() async => await webSocketService.disconnect(), returnsNormally);
    });

    test('dispose should not throw', () {
      expect(() => webSocketService.dispose(), returnsNormally);
    });

    test('sendMessage should not throw when not connected', () {
      expect(() => webSocketService.sendMessage({'test': 'message'}), returnsNormally);
    });
  });
}