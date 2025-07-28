import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/app_logger.dart';
import '../services/storage_service.dart';
import '../core/service_locator.dart';

class UserActivityService {
  static final UserActivityService _instance = UserActivityService._internal();
  factory UserActivityService() => _instance;
  UserActivityService._internal();

  final Dio _dio = Dio();
  final List<Map<String, dynamic>> _pendingLogs = [];
  Timer? _batchTimer;
  bool _isInitialized = false;

  static const String _logEndpoint = '/users/log_activity/';
  static const int _batchSize = 10;
  static const Duration _batchInterval = Duration(seconds: 30);

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final storageService = getIt<StorageService>();
    final baseUrl = await _getBaseUrl();
    
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    );

    _startBatchTimer();
    _isInitialized = true;
    AppLogger.info('UserActivityService initialized', 'ActivityService');
  }

  Future<String> _getBaseUrl() async {
    return 'http://localhost:8000';
  }

  void logUserAction({
    required String action,
    required String screen,
    Map<String, dynamic>? metadata,
    String? userId,
  }) {
    if (!_isInitialized) {
      AppLogger.warning('UserActivityService not initialized, skipping log', 'ActivityService');
      return;
    }

    final logEntry = {
      'action': action,
      'screen': screen,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': userId,
      'metadata': metadata ?? {},
      'platform': 'flutter',
    };

    _pendingLogs.add(logEntry);
    AppLogger.debug('Added log entry: $action on $screen', 'ActivityService');

    if (_pendingLogs.length >= _batchSize) {
      _flushLogs();
    }
  }

  void logScreenView(String screenName, {Map<String, dynamic>? metadata}) {
    logUserAction(
      action: 'screen_view',
      screen: screenName,
      metadata: metadata,
    );
  }

  void logButtonTap(String buttonName, String screen, {Map<String, dynamic>? metadata}) {
    logUserAction(
      action: 'button_tap',
      screen: screen,
      metadata: {
        'button_name': buttonName,
        ...?metadata,
      },
    );
  }

  void logApiCall(String endpoint, String method, {int? statusCode, Map<String, dynamic>? metadata}) {
    logUserAction(
      action: 'api_call',
      screen: 'api',
      metadata: {
        'endpoint': endpoint,
        'method': method,
        'status_code': statusCode,
        ...?metadata,
      },
    );
  }

  void logError(String error, String screen, {Map<String, dynamic>? metadata}) {
    logUserAction(
      action: 'error',
      screen: screen,
      metadata: {
        'error_message': error,
        ...?metadata,
      },
    );
  }

  void logPlaylistAction(String action, String playlistId, {Map<String, dynamic>? metadata}) {
    logUserAction(
      action: 'playlist_$action',
      screen: 'playlist',
      metadata: {
        'playlist_id': playlistId,
        ...?metadata,
      },
    );
  }

  void logTrackAction(String action, String trackId, {Map<String, dynamic>? metadata}) {
    logUserAction(
      action: 'track_$action',
      screen: 'music',
      metadata: {
        'track_id': trackId,
        ...?metadata,
      },
    );
  }

  void logVoteAction(String playlistId, String trackId, String voteType) {
    logUserAction(
      action: 'vote',
      screen: 'playlist',
      metadata: {
        'playlist_id': playlistId,
        'track_id': trackId,
        'vote_type': voteType,
      },
    );
  }

  void logAuthAction(String action, {Map<String, dynamic>? metadata}) {
    logUserAction(
      action: 'auth_$action',
      screen: 'auth',
      metadata: metadata,
    );
  }

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (timer) {
      if (_pendingLogs.isNotEmpty) {
        _flushLogs();
      }
    });
  }

  Future<void> _flushLogs() async {
    if (_pendingLogs.isEmpty) return;

    final logsToSend = List<Map<String, dynamic>>.from(_pendingLogs);
    _pendingLogs.clear();

    try {
      final storageService = getIt<StorageService>();
      final token = storageService.get<String>('auth_token');

      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }

      await _dio.post(
        _logEndpoint,
        data: {
          'logs': logsToSend,
          'batch_size': logsToSend.length,
        },
        options: Options(headers: headers),
      );

      AppLogger.debug('Successfully sent ${logsToSend.length} log entries', 'ActivityService');
    } catch (e) {
      AppLogger.error('Failed to send logs to backend', e, null, 'ActivityService');
      _pendingLogs.addAll(logsToSend);
    }
  }

  Future<void> flushPendingLogs() async {
    await _flushLogs();
  }

  void dispose() {
    _batchTimer?.cancel();
    _flushLogs();
    AppLogger.info('UserActivityService disposed', 'ActivityService');
  }
}