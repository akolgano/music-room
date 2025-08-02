import 'package:flutter/material.dart';
import '../services/frontend_logging_service.dart';
import 'app_logger.dart';

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