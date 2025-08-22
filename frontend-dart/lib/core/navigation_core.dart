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

class NavigationHelper {

  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    AppLogger.debug('Navigating to: $routeName', 'NavigationHelper');
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }
  
  static Future<T?> navigateReplace<T, TO>(BuildContext context, String routeName, {Object? arguments}) {
    AppLogger.debug('Navigate and replace: $routeName', 'NavigationHelper');
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      arguments: arguments,
    );
  }
  
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    AppLogger.debug('Navigate and remove until: $routeName', 'NavigationHelper');
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      predicate,
      arguments: arguments,
    );
  }
  
  static void pop<T>(BuildContext context, [T? result]) {
    AppLogger.debug('Popping current route', 'NavigationHelper');
    Navigator.pop<T>(context, result);
  }
  
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
  
  static void popUntil(BuildContext context, String routeName) {
    AppLogger.debug('Pop until: $routeName', 'NavigationHelper');
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }
  
  static Future<T?> showAppDialog<T>({
    required BuildContext context,
    required Widget dialog,
    bool barrierDismissible = true,
  }) {
    AppLogger.debug('Showing dialog', 'NavigationHelper');
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => dialog,
    );
  }
  
  static Future<T?> showAppBottomSheet<T>({
    required BuildContext context,
    required Widget sheet,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
  }) {
    AppLogger.debug('Showing bottom sheet', 'NavigationHelper');
    return showModalBottomSheet<T>(
      context: context,
      builder: (_) => sheet,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
    );
  }
}

class RouteTransitions {

  static Route<T> slideFromRight<T>(RouteSettings settings, Widget page) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
  
  static Route<T> slideFromBottom<T>(RouteSettings settings, Widget page) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
  
  static Route<T> fade<T>(RouteSettings settings, Widget page) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
  
  static Route<T> scale<T>(RouteSettings settings, Widget page) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut;
        var tween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        
        return ScaleTransition(
          scale: animation.drive(tween),
          child: child,
        );
      },
    );
  }
  
  static Route<T> rotation<T>(RouteSettings settings, Widget page) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut;
        var tween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        
        return RotationTransition(
          turns: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

class NavigationGuard {
  final bool Function(BuildContext context) canActivate;
  final String? redirectTo;
  final void Function(BuildContext context)? onDenied;
  
  const NavigationGuard({
    required this.canActivate,
    this.redirectTo,
    this.onDenied,
  });
  
  bool checkAccess(BuildContext context) {
    final hasAccess = canActivate(context);
    
    if (!hasAccess) {
      AppLogger.warning('Access denied to route', 'NavigationGuard');
      
      if (onDenied != null) {
        onDenied!(context);
      }
      
      if (redirectTo != null) {
        NavigationHelper.navigateReplace(context, redirectTo!);
      }
    }
    
    return hasAccess;
  }
}

class RouteArguments {
  final Map<String, dynamic> data;
  
  const RouteArguments({required this.data});
  
  T? get<T>(String key) => data[key] as T?;
  
  T getRequired<T>(String key) {
    final value = data[key];
    if (value == null) {
      throw ArgumentError('Required argument "$key" not found');
    }
    return value as T;
  }
  
  bool has(String key) => data.containsKey(key);
  
  RouteArguments copyWith(Map<String, dynamic> updates) {
    return RouteArguments(data: {...data, ...updates});
  }
}