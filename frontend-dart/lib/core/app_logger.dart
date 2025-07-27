import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static late final Logger _logger;
  
  static void initialize() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: kDebugMode ? Level.debug : Level.info,
    );
  }
  
  static void debug(String message, [String? tag]) {
    final logMessage = tag != null ? '[$tag] $message' : message;
    _logger.d(logMessage);
  }
  
  static void info(String message, [String? tag]) {
    final logMessage = tag != null ? '[$tag] $message' : message;
    _logger.i(logMessage);
  }
  
  static void warning(String message, [String? tag]) {
    final logMessage = tag != null ? '[$tag] $message' : message;
    _logger.w(logMessage);
  }
  
  static void error(String message, [dynamic error, StackTrace? stackTrace, String? tag]) {
    final logMessage = tag != null ? '[$tag] $message' : message;
    _logger.e(logMessage, error: error, stackTrace: stackTrace);
  }
  
  static void trace(String message, [String? tag]) {
    final logMessage = tag != null ? '[$tag] $message' : message;
    _logger.t(logMessage);
  }
}