import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/navigation_core.dart';
import '../core/locator_core.dart';
import 'auth_services.dart';

enum LogLevel { info, warning, error, debug }

enum UserActionType {
  navigation,
  buttonClick,
  formSubmit,
  search,
  playMusic,
  pauseMusic,
  addToPlaylist,
  removeFromPlaylist,
  login,
  logout,
  signup,
  profileUpdate,
  friendRequest,
  vote,
  share,
  other
}

class FrontendLogEvent {
  final String id;
  final DateTime timestamp;
  final UserActionType actionType;
  final String description;
  final LogLevel level;
  final Map<String, dynamic>? metadata;
  final String? userId;
  final String? screenName;
  final String? route;

  FrontendLogEvent({
    required this.id,
    required this.timestamp,
    required this.actionType,
    required this.description,
    this.level = LogLevel.info,
    this.metadata,
    this.userId,
    this.screenName,
    this.route,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action_type': actionType.name,
      'description': description,
      'level': level.name,
      'metadata': metadata,
      'user_id': userId,
      'screen_name': screenName,
      'route': route,
      'platform': 'flutter',
      'app_version': '1.0.0',
    };
  }
}

class FrontendLoggingService {
  static final FrontendLoggingService _instance = FrontendLoggingService._internal();
  factory FrontendLoggingService() => _instance;
  FrontendLoggingService._internal();

  final Dio _dio = Dio();
  final List<FrontendLogEvent> _pendingLogs = [];
  final int _maxPendingLogs = 10;
  final Duration _batchInterval = const Duration(seconds: 2);
  Timer? _batchTimer;
  String? _currentUserId;
  String? _currentRoute;
  bool _isInitialized = false;

  static const List<String> _sensitiveKeys = [
    'password',
    'token',
    'secret',
    'key',
    'auth',
    'credential',
    'authorization',
    'bearer',
    'api_key',
    'access_token',
    'refresh_token',
    'session_id',
    'cookie',
    'jwt',
    'private_key',
    'client_secret',
  ];

  @visibleForTesting
  Map<String, dynamic> sanitizeMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return {};
    
    final sanitized = <String, dynamic>{};
    
    for (final entry in metadata.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      
      if (_sensitiveKeys.any((sensitiveKey) => key.contains(sensitiveKey))) {
        sanitized[entry.key] = value == null ? null : _maskValue(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[entry.key] = sanitizeMetadata(value);
      } else if (value is List) {
        sanitized[entry.key] = _sanitizeList(value);
      } else if (value is String && _containsSensitivePattern(value)) {
        sanitized[entry.key] = _maskValue(value);
      } else if (value == null || value == '') {
        sanitized[entry.key] = value;
      } else {
        sanitized[entry.key] = value;
      }
    }
    
    return sanitized;
  }

  List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return sanitizeMetadata(item);
      } else if (item is List) {
        return _sanitizeList(item);
      } else if (item is String && _containsSensitivePattern(item)) {
        return _maskValue(item);
      }
      return item;
    }).toList();
  }

  bool _containsSensitivePattern(String value) {
    final patterns = [
      RegExp(r'^[A-Za-z0-9+/=]{20,}$'),
      RegExp(r'^Bearer\s+', caseSensitive: false),
      RegExp(r'^Token\s+', caseSensitive: false),
      RegExp(r'password\s*[:=]\s*\S+', caseSensitive: false),
      RegExp(r'token\s*[:=]\s*\S+', caseSensitive: false),
      RegExp(r'secret\s*[:=]\s*\S+', caseSensitive: false),
      RegExp(r'key\s*[:=]\s*\S+', caseSensitive: false),
    ];
    
    return patterns.any((pattern) => pattern.hasMatch(value));
  }

  String _maskValue(dynamic value) {
    if (value == null) return '[MASKED:NULL]';
    final stringValue = value.toString();
    if (stringValue.isEmpty) return '[MASKED:EMPTY]';
    if (stringValue.length <= 3) return '[MASKED]';
    return '${stringValue.substring(0, 2)}${'*' * (stringValue.length - 4)}${stringValue.substring(stringValue.length - 2)}';
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final storageService = getIt<StorageService>();
      final userData = storageService.getMap('current_user');
      _currentUserId = userData?['id']?.toString();
      
      _dio.options.baseUrl = 'http://localhost:8000';
      _dio.options.connectTimeout = const Duration(seconds: 10);
      _dio.options.receiveTimeout = const Duration(seconds: 10);
      
      _startBatchTimer();
      _isInitialized = true;
      
      AppLogger.info('Frontend logging service initialized', 'FrontendLoggingService');
    } catch (e) {
      AppLogger.error('Failed to initialize frontend logging service', e, null, 'FrontendLoggingService');
    }
  }

  void updateUserId(String? userId) {
    _currentUserId = userId;
  }

  void updateCurrentRoute(String? route) {
    _currentRoute = route;
  }

  void logUserAction({
    required UserActionType actionType,
    required String description,
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? metadata,
    String? screenName,
    String? customRoute,
  }) {
    if (!_isInitialized) {
      AppLogger.warning('Logging service not initialized, skipping log', 'FrontendLoggingService');
      return;
    }

    final sanitizedMetadata = sanitizeMetadata(metadata);

    final event = FrontendLogEvent(
      id: '',
      timestamp: DateTime.now(),
      actionType: actionType,
      description: description,
      level: level,
      metadata: sanitizedMetadata,
      userId: _currentUserId,
      screenName: screenName,
      route: customRoute ?? _currentRoute,
    );

    _pendingLogs.add(event);
    
    if (kDebugMode) {
      AppLogger.debug('Logged user action: ${actionType.name} - $description', 'FrontendLoggingService');
    }

    if (_pendingLogs.length >= _maxPendingLogs) {
      _sendPendingLogs();
    }
  }

  void logNavigation(String from, String to, {Map<String, dynamic>? metadata}) {
    logUserAction(
      actionType: UserActionType.navigation,
      description: 'Navigation from $from to $to',
      metadata: {
        'from': from,
        'to': to,
        ...?metadata,
      },
      screenName: to,
    );
  }

  void logButtonClick(String buttonName, String screenName, {Map<String, dynamic>? metadata}) {
    logUserAction(
      actionType: UserActionType.buttonClick,
      description: 'Button clicked: $buttonName',
      metadata: {
        'button_name': buttonName,
        ...?metadata,
      },
      screenName: screenName,
    );
  }

  void logFormSubmit(String formName, String screenName, {bool success = true, Map<String, dynamic>? metadata}) {
    logUserAction(
      actionType: UserActionType.formSubmit,
      description: 'Form ${success ? 'submitted' : 'failed'}: $formName',
      level: success ? LogLevel.info : LogLevel.warning,
      metadata: {
        'form_name': formName,
        'success': success,
        ...?metadata,
      },
      screenName: screenName,
    );
  }

  void logSearch(String query, String screenName, {int? resultCount, Map<String, dynamic>? metadata}) {
    logUserAction(
      actionType: UserActionType.search,
      description: 'Search performed: $query',
      metadata: {
        'query': query,
        'result_count': resultCount,
        ...?metadata,
      },
      screenName: screenName,
    );
  }

  void logMusicAction(String action, String trackId, {String? playlistId, Map<String, dynamic>? metadata}) {
    final actionType = action == 'play' ? UserActionType.playMusic : 
                     action == 'pause' ? UserActionType.pauseMusic :
                     action == 'add' ? UserActionType.addToPlaylist :
                     action == 'remove' ? UserActionType.removeFromPlaylist :
                     UserActionType.other;
    
    logUserAction(
      actionType: actionType,
      description: 'Music action: $action for track $trackId',
      metadata: {
        'action': action,
        'track_id': trackId,
        'playlist_id': playlistId,
        ...?metadata,
      },
    );
  }

  void logAuthAction(String action, {bool success = true, Map<String, dynamic>? metadata}) {
    final actionType = action == 'login' ? UserActionType.login :
                      action == 'logout' ? UserActionType.logout :
                      action == 'signup' ? UserActionType.signup :
                      UserActionType.other;
    
    logUserAction(
      actionType: actionType,
      description: 'Auth action: $action ${success ? 'successful' : 'failed'}',
      level: success ? LogLevel.info : LogLevel.warning,
      metadata: {
        'action': action,
        'success': success,
        ...?metadata,
      },
    );
  }

  void logError(String error, String screenName, {StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    logUserAction(
      actionType: UserActionType.other,
      description: 'Error occurred: $error',
      level: LogLevel.error,
      metadata: {
        'error': error,
        'stack_trace': stackTrace?.toString(),
        ...?metadata,
      },
      screenName: screenName,
    );
  }

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (timer) {
      if (_pendingLogs.isNotEmpty) {
        _sendPendingLogs();
      }
    });
  }

  Future<void> _sendPendingLogs() async {
    if (_pendingLogs.isEmpty) return;

    
    if (_currentUserId == null) {
      _pendingLogs.clear();
      return;
    }

    
    String? authToken;
    try {
      final storageService = getIt<StorageService>();
      authToken = storageService.get<String>('auth_token');
    } catch (e) {
      authToken = null;
    }

    if (authToken == null) {
      _pendingLogs.clear();
      return;
    }

    final logsToSend = List<FrontendLogEvent>.from(_pendingLogs);
    _pendingLogs.clear();

    try {
      final convertedLogs = logsToSend.map((log) => {
        'action': '${log.actionType.name}: ${log.description}',
        'screen': log.screenName ?? 'unknown',
        'timestamp': log.timestamp.toIso8601String(),
        'platform': 'flutter',
        'user_id': log.userId,
        'metadata': {
          'action_type': log.actionType.name,
          'level': log.level.name,
          'route': log.route,
          'app_version': '1.0.0',
          ...sanitizeMetadata(log.metadata),
        },
      }).toList();

      await _dio.post(
        '/users/log_activity/',
        data: {
          'logs': convertedLogs,
          'batch_size': convertedLogs.length,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $authToken',
          },
        ),
      );

      if (kDebugMode) {
        AppLogger.debug('Sent ${logsToSend.length} frontend logs to backend', 'FrontendLoggingService');
      }
    } catch (e) {
      AppLogger.warning('Failed to send frontend logs to backend: $e', 'FrontendLoggingService');
      
      _pendingLogs.addAll(logsToSend);
      
      if (_pendingLogs.length > _maxPendingLogs * 2) {
        _pendingLogs.removeRange(0, _pendingLogs.length - _maxPendingLogs);
        AppLogger.warning('Dropped old pending logs due to buffer overflow', 'FrontendLoggingService');
      }
    }
  }

  Future<void> flush() async {
    if (_pendingLogs.isNotEmpty) {
      await _sendPendingLogs();
    }
  }

  void dispose() {
    _batchTimer?.cancel();
    _batchTimer = null;
    flush();
    _isInitialized = false;
  }
}
