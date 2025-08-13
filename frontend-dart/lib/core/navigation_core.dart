import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import '../services/logging_services.dart';

class AppLogger {
  static Logger? _logger;
  
  static void initialize() {
    if (_logger != null) return;
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
    if (_logger == null) return;
    final logMessage = tag != null ? '[$tag] $message' : message;
    _logger!.d(logMessage);
  }
  
  static void info(String message, [String? tag]) {
    if (_logger == null) return;
    final logMessage = tag != null ? '[$tag] $message' : message;
    _logger!.i(logMessage);
  }
  
  static void warning(String message, [String? tag]) {
    if (_logger == null) return;
    final logMessage = tag != null ? '[$tag] $message' : message;
    _logger!.w(logMessage);
  }
  
  static void error(String message, [dynamic error, StackTrace? stackTrace, String? tag]) {
    if (_logger == null) return;
    final logMessage = tag != null ? '[$tag] $message' : message;
    _logger!.e(logMessage, error: error, stackTrace: stackTrace);
  }
}

class LoggingNavigationObserver extends NavigatorObserver {
  final FrontendLoggingService _loggingService = FrontendLoggingService();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logNavigation(previousRoute?.settings.name, route.settings.name, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logNavigation(route.settings.name, previousRoute?.settings.name, 'pop');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logNavigation(oldRoute?.settings.name, newRoute?.settings.name, 'replace');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _logNavigation(route.settings.name, previousRoute?.settings.name, 'remove');
  }

  void _logNavigation(String? from, String? to, String action) {
    final fromRoute = from ?? 'unknown';
    final toRoute = to ?? 'unknown';
    
    _loggingService.updateCurrentRoute(toRoute);
    
    if (fromRoute != toRoute) {
      _loggingService.logNavigation(
        fromRoute,
        toRoute,
        metadata: {
          'navigation_action': action,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      AppLogger.debug('Navigation logged: $fromRoute -> $toRoute ($action)', 'LoggingNavigationObserver');
    }
    
  }
}