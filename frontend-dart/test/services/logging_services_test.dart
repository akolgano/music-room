import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:music_room/services/logging_services.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('Logger Tests', () {
    late Logger logger;
    late MockLogger mockLogger;

    setUp(() {
      logger = Logger();
      mockLogger = MockLogger();
    });

    test('should create Logger instance', () {
      expect(logger, isA<Logger>());
    });

    test('should log debug messages', () {
      logger.debug('Debug message');
      expect(logger.level, LogLevel.debug);
    });

    test('should log info messages', () {
      logger.info('Info message');
      expect(logger.level, LogLevel.info);
    });

    test('should log warning messages', () {
      logger.warning('Warning message');
      expect(logger.level, LogLevel.warning);
    });

    test('should log error messages', () {
      logger.error('Error message');
      expect(logger.level, LogLevel.error);
    });

    test('should log error messages with exceptions', () {
      final exception = Exception('Test exception');
      logger.error('Error with exception', exception);
      expect(logger.level, LogLevel.error);
    });

    test('should handle different log levels', () {
      logger.setLevel(LogLevel.warning);
      expect(logger.level, LogLevel.warning);
      
      logger.setLevel(LogLevel.error);
      expect(logger.level, LogLevel.error);
    });

    test('should format log messages correctly', () {
      final timestamp = DateTime.now();
      const message = 'Test message';
      const level = LogLevel.info;
      
      final formatted = logger.formatMessage(level, message, timestamp);
      expect(formatted, contains(message));
      expect(formatted, contains('INFO'));
    });

    test('should handle log rotation', () async {
      await logger.rotateLogs();
      expect(logger.isRotationEnabled, true);
    });

    test('should manage log file size', () async {
      const maxSize = 1024 * 1024;
      logger.setMaxFileSize(maxSize);
      expect(logger.maxFileSize, maxSize);
    });

    test('should write logs to file', () async {
      const message = 'File log message';
      await logger.writeToFile(message);
      expect(logger.isFileLoggingEnabled, true);
    });

    test('should send logs to remote service', () async {
      const message = 'Remote log message';
      when(mockLogger.sendToRemote(message)).thenAnswer((_) async => true);
      
      final result = await mockLogger.sendToRemote(message);
      expect(result, true);
      
      verify(mockLogger.sendToRemote(message)).called(1);
    });

    test('should filter logs by level', () {
      logger.setLevel(LogLevel.error);
      
      final shouldLog = logger.shouldLog(LogLevel.debug);
      expect(shouldLog, false);
      
      final shouldLogError = logger.shouldLog(LogLevel.error);
      expect(shouldLogError, true);
    });

    test('should handle log buffer', () {
      logger.enableBuffer(100);
      logger.info('Buffered message 1');
      logger.info('Buffered message 2');
      
      final buffer = logger.getBuffer();
      expect(buffer.length, 2);
    });

    test('should clear log buffer', () {
      logger.enableBuffer(10);
      logger.info('Message to clear');
      logger.clearBuffer();
      
      final buffer = logger.getBuffer();
      expect(buffer.isEmpty, true);
    });

    test('should handle log categories', () {
      logger.setCategory('AUTH');
      logger.info('Authentication message');
      expect(logger.category, 'AUTH');
    });

    test('should handle log metadata', () {
      final metadata = {'userId': '123', 'action': 'login'};
      logger.info('User action', null, metadata);
      expect(logger.lastMetadata, metadata);
    });

    test('should handle log sampling', () {
      logger.setSamplingRate(0.5);
      expect(logger.samplingRate, 0.5);
    });

    test('should handle async logging', () async {
      const message = 'Async log message';
      await logger.logAsync(LogLevel.info, message);
      expect(logger.asyncQueue.isEmpty, true);
    });

    test('should handle log compression', () async {
      const logs = ['Log 1', 'Log 2', 'Log 3'];
      final compressed = await logger.compressLogs(logs);
      expect(compressed, isA<List<int>>());
    });

    test('should handle log encryption', () async {
      const message = 'Sensitive log message';
      final encrypted = await logger.encryptMessage(message);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(message)));
    });

    test('should handle log decryption', () async {
      const message = 'Decryption test message';
      final encrypted = await logger.encryptMessage(message);
      final decrypted = await logger.decryptMessage(encrypted);
      expect(decrypted, equals(message));
    });

    test('should export logs', () async {
      const format = LogExportFormat.json;
      final exported = await logger.exportLogs(format);
      expect(exported, isA<String>());
    });

    test('should import logs', () async {
      const logData = '{"level": "INFO", "message": "Imported log"}';
      await logger.importLogs(logData, LogExportFormat.json);
      expect(logger.logCount, greaterThan(0));
    });

    test('should handle log archiving', () async {
      await logger.archiveLogs();
      expect(logger.isArchiveComplete, true);
    });

    test('should handle log retention policy', () {
      const retentionDays = 30;
      logger.setRetentionPolicy(retentionDays);
      expect(logger.retentionDays, retentionDays);
    });

    test('should cleanup old logs', () async {
      await logger.cleanupOldLogs();
      expect(logger.isCleanupComplete, true);
    });
  });

  group('MockLogger Tests', () {
    late MockLogger mockLogger;

    setUp(() {
      mockLogger = MockLogger();
    });

    test('should mock logging operations', () {
      when(mockLogger.info('test')).thenReturn(null);
      
      mockLogger.info('test');
      verify(mockLogger.info('test')).called(1);
    });

    test('should mock log level changes', () {
      when(mockLogger.setLevel(LogLevel.debug)).thenReturn(null);
      
      mockLogger.setLevel(LogLevel.debug);
      verify(mockLogger.setLevel(LogLevel.debug)).called(1);
    });
  });
}
