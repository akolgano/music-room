// lib/core/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/music_service.dart';
import '../services/friend_service.dart';
import '../services/storage_service.dart';
import '../services/music_player_service.dart';
import '../services/voting_service.dart';
import '../services/websocket_service.dart'; 
import '../providers/dynamic_theme_provider.dart';
import '../models/models.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final storageService = await StorageService.init();
  getIt.registerSingleton<StorageService>(storageService);

  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio();
    String baseUrl;
    final envBaseUrl = dotenv.env['API_BASE_URL'];
    if (envBaseUrl != null && envBaseUrl.isNotEmpty) baseUrl = envBaseUrl;
    else baseUrl = 'http://localhost:8000';

    if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);

    dio.options.baseUrl = baseUrl;
    dio.options.headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.sendTimeout = const Duration(seconds: 10);

    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 120,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = getIt.isRegistered<AuthService>() ? getIt<AuthService>().currentToken : null;
        if (token != null) options.headers['Authorization'] = 'Token $token';
        print('API Request: ${options.method} ${options.uri}');
        if (options.data != null) print('Request Data: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('API Response: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('API Error: ${error.response?.statusCode} ${error.requestOptions.uri}');
        print('Error details: ${error.message}');
        if (error.response?.statusCode == 401) {
          print('Unauthorized - triggering logout');
          if (getIt.isRegistered<AuthService>()) getIt<AuthService>().logout();
        }
        handler.next(error);
      },
    ));

    return dio;
  });

  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt<Dio>()));

  getIt.registerLazySingleton<AuthService>(() => 
      AuthService(getIt<ApiService>(), getIt<StorageService>()));

  getIt.registerLazySingleton<MusicService>(() => 
      MusicService(getIt<ApiService>()));

  getIt.registerLazySingleton<FriendService>(() => 
      FriendService(getIt<ApiService>()));

  getIt.registerLazySingleton<VotingService>(() => 
      VotingService(getIt<ApiService>()));

  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());

  getIt.registerLazySingleton<DynamicThemeProvider>(() => 
      DynamicThemeProvider());

  getIt.registerLazySingleton<MusicPlayerService>(() => 
      MusicPlayerService(themeProvider: getIt<DynamicThemeProvider>()));

  print('Service Locator setup complete with WebSocket support and consistent API logging');
}

class WebSocketConnectionInfo {
  final String playlistId;
  final String authToken;
  final bool isConnected;
  final bool isConnecting;
  final DateTime? lastConnected;
  final String? lastError;

  const WebSocketConnectionInfo({
    required this.playlistId,
    required this.authToken,
    required this.isConnected,
    required this.isConnecting,
    this.lastConnected,
    this.lastError,
  });

  WebSocketConnectionInfo copyWith({
    String? playlistId,
    String? authToken,
    bool? isConnected,
    bool? isConnecting,
    DateTime? lastConnected,
    String? lastError,
  }) {
    return WebSocketConnectionInfo(
      playlistId: playlistId ?? this.playlistId,
      authToken: authToken ?? this.authToken,
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      lastConnected: lastConnected ?? this.lastConnected,
      lastError: lastError ?? this.lastError,
    );
  }
}

class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const WebSocketMessage({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WebSocketMessage.auth(String token) {
    return WebSocketMessage(
      type: 'auth',
      data: {'token': token},
      timestamp: DateTime.now(),
    );
  }

  factory WebSocketMessage.heartbeat() {
    return WebSocketMessage(
      type: 'heartbeat',
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory WebSocketMessage.heartbeatResponse() {
    return WebSocketMessage(
      type: 'heartbeat_response',
      data: {},
      timestamp: DateTime.now(),
    );
  }
}

enum WebSocketEventType {
  auth,
  authSuccess,
  authError,
  playlistUpdate,
  trackAdded,
  trackRemoved,
  trackReordered,
  voteUpdated,
  heartbeat,
  heartbeatResponse,
  error,
  unknown;

  static WebSocketEventType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'auth':
        return WebSocketEventType.auth;
      case 'auth_success':
        return WebSocketEventType.authSuccess;
      case 'auth_error':
        return WebSocketEventType.authError;
      case 'playlist_update':
        return WebSocketEventType.playlistUpdate;
      case 'track_added':
        return WebSocketEventType.trackAdded;
      case 'track_removed':
        return WebSocketEventType.trackRemoved;
      case 'track_reordered':
        return WebSocketEventType.trackReordered;
      case 'vote_updated':
        return WebSocketEventType.voteUpdated;
      case 'heartbeat':
        return WebSocketEventType.heartbeat;
      case 'heartbeat_response':
        return WebSocketEventType.heartbeatResponse;
      case 'error':
        return WebSocketEventType.error;
      default:
        return WebSocketEventType.unknown;
    }
  }

  String get value {
    switch (this) {
      case WebSocketEventType.auth:
        return 'auth';
      case WebSocketEventType.authSuccess:
        return 'auth_success';
      case WebSocketEventType.authError:
        return 'auth_error';
      case WebSocketEventType.playlistUpdate:
        return 'playlist_update';
      case WebSocketEventType.trackAdded:
        return 'track_added';
      case WebSocketEventType.trackRemoved:
        return 'track_removed';
      case WebSocketEventType.trackReordered:
        return 'track_reordered';
      case WebSocketEventType.voteUpdated:
        return 'vote_updated';
      case WebSocketEventType.heartbeat:
        return 'heartbeat';
      case WebSocketEventType.heartbeatResponse:
        return 'heartbeat_response';
      case WebSocketEventType.error:
        return 'error';
      case WebSocketEventType.unknown:
        return 'unknown';
    }
  }
}

class WebSocketStats {
  final int totalMessagesReceived;
  final int totalMessagesSent;
  final int reconnectionAttempts;
  final Duration totalConnectedTime;
  final DateTime? firstConnectionTime;
  final DateTime? lastDisconnectionTime;
  final List<String> recentErrors;

  const WebSocketStats({
    required this.totalMessagesReceived,
    required this.totalMessagesSent,
    required this.reconnectionAttempts,
    required this.totalConnectedTime,
    this.firstConnectionTime,
    this.lastDisconnectionTime,
    this.recentErrors = const [],
  });

  WebSocketStats copyWith({
    int? totalMessagesReceived,
    int? totalMessagesSent,
    int? reconnectionAttempts,
    Duration? totalConnectedTime,
    DateTime? firstConnectionTime,
    DateTime? lastDisconnectionTime,
    List<String>? recentErrors,
  }) {
    return WebSocketStats(
      totalMessagesReceived: totalMessagesReceived ?? this.totalMessagesReceived,
      totalMessagesSent: totalMessagesSent ?? this.totalMessagesSent,
      reconnectionAttempts: reconnectionAttempts ?? this.reconnectionAttempts,
      totalConnectedTime: totalConnectedTime ?? this.totalConnectedTime,
      firstConnectionTime: firstConnectionTime ?? this.firstConnectionTime,
      lastDisconnectionTime: lastDisconnectionTime ?? this.lastDisconnectionTime,
      recentErrors: recentErrors ?? this.recentErrors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMessagesReceived': totalMessagesReceived,
      'totalMessagesSent': totalMessagesSent,
      'reconnectionAttempts': reconnectionAttempts,
      'totalConnectedTime': totalConnectedTime.inMilliseconds,
      'firstConnectionTime': firstConnectionTime?.toIso8601String(),
      'lastDisconnectionTime': lastDisconnectionTime?.toIso8601String(),
      'recentErrors': recentErrors,
    };
  }
}

extension PlaylistTrackWebSocket on PlaylistTrack {
  static PlaylistTrack fromWebSocketUpdate(PlaylistTrackUpdate update) {
    return PlaylistTrack(
      trackId: update.id.toString(),
      name: update.track.name,
      position: update.position,
      points: update.points,
      track: update.track,
    );
  }

  PlaylistTrackUpdate toWebSocketUpdate() {
    return PlaylistTrackUpdate(
      id: int.tryParse(trackId) ?? 0,
      track: track ?? Track(id: trackId, name: name, artist: '', album: '', url: ''),
      position: position,
      points: points,
    );
  }
}

class WebSocketConfig {
  static const Duration defaultReconnectDelay = Duration(seconds: 5);
  static const Duration defaultHeartbeatInterval = Duration(seconds: 30);
  static const int defaultMaxReconnectAttempts = 5;
  static const Duration defaultConnectionTimeout = Duration(seconds: 10);

  final Duration reconnectDelay;
  final Duration heartbeatInterval;
  final int maxReconnectAttempts;
  final Duration connectionTimeout;
  final bool enableHeartbeat;
  final bool enableAutoReconnect;

  const WebSocketConfig({
    this.reconnectDelay = defaultReconnectDelay,
    this.heartbeatInterval = defaultHeartbeatInterval,
    this.maxReconnectAttempts = defaultMaxReconnectAttempts,
    this.connectionTimeout = defaultConnectionTimeout,
    this.enableHeartbeat = true,
    this.enableAutoReconnect = true,
  });

  factory WebSocketConfig.production() {
    return const WebSocketConfig(
      reconnectDelay: Duration(seconds: 3),
      heartbeatInterval: Duration(seconds: 20),
      maxReconnectAttempts: 10,
      enableHeartbeat: true,
      enableAutoReconnect: true,
    );
  }

  factory WebSocketConfig.development() {
    return const WebSocketConfig(
      reconnectDelay: Duration(seconds: 1),
      heartbeatInterval: Duration(seconds: 15),
      maxReconnectAttempts: 3,
      enableHeartbeat: true,
      enableAutoReconnect: true,
    );
  }
}
