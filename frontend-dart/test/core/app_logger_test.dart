import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/app_logger.dart';

void main() {
  group('AppLogger Tests', () {
    setUpAll(() {
      AppLogger.initialize();
    });
    test('should log debug messages', () {
      expect(() => AppLogger.debug('Debug message', 'TestClass'), returnsNormally);
    });

    test('should log info messages', () {
      expect(() => AppLogger.info('Info message', 'TestClass'), returnsNormally);
    });

    test('should log warning messages', () {
      expect(() => AppLogger.warning('Warning message', 'TestClass'), returnsNormally);
    });

    test('should log error messages', () {
      expect(() => AppLogger.error('Error message', null, null, 'TestClass'), returnsNormally);
    });

    test('should handle null context gracefully', () {
      expect(() => AppLogger.debug('Debug message', null), returnsNormally);
      expect(() => AppLogger.info('Info message', null), returnsNormally);
      expect(() => AppLogger.warning('Warning message', null), returnsNormally);
      expect(() => AppLogger.error('Error message', null, null, null), returnsNormally);
    });

    test('should handle error with exception and stack trace', () {
      final exception = Exception('Test exception');
      final stackTrace = StackTrace.current;
      
      expect(() => AppLogger.error('Error with exception', exception, stackTrace, 'TestClass'), returnsNormally);
    });

    test('should format log messages consistently', () {
      expect(() => AppLogger.debug('Message with special chars: !@#\$%^&*()', 'TestClass'), returnsNormally);
      expect(() => AppLogger.info('Multi\nLine\nMessage', 'TestClass'), returnsNormally);
      expect(() => AppLogger.warning('Empty context', ''), returnsNormally);
    });
  });
}
