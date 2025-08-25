import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../services/api_services.dart';
import '../services/auth_services.dart';
import '../services/music_services.dart';
import '../services/player_services.dart';
import '../services/cache_services.dart';
import '../services/websocket_services.dart';
import '../services/logging_services.dart';
import '../services/notification_services.dart';
import '../services/beacon_services.dart';
import '../providers/theme_providers.dart';
import '../providers/music_providers.dart';
import '../providers/voting_providers.dart';
import '../providers/friend_providers.dart';
import '../providers/connectivity_providers.dart';

final getIt = GetIt.instance;

Dio _createConfiguredDio() {
  final dio = Dio();
  
  String baseUrl;
  final envBaseUrl = dotenv.env['API_BASE_URL'];
  if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
    baseUrl = envBaseUrl;
  } else {
    baseUrl = 'http://localhost:8000';
  }
  
  if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
  
  dio.options.baseUrl = baseUrl;
  dio.options.headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 10);
  dio.options.sendTimeout = const Duration(seconds: 10);

  if (kDebugMode) {
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: false,
      requestBody: false,
      responseBody: false,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 120,
    ));
  }

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = getIt.isRegistered<AuthService>() 
          ? getIt<AuthService>().currentToken 
          : null;
      if (token != null) {
        options.headers['Authorization'] = 'Token $token';
      }
      
      if (kDebugMode) {
        final uri = options.uri.toString();
        final sanitizedUri = uri.contains('login') || uri.contains('signup') || uri.contains('password')
            ? '${options.uri.scheme}://${options.uri.host}${options.uri.path} [SENSITIVE]'
            : uri;
        debugPrint('[ServiceLocator] API Request: ${options.method} $sanitizedUri');
      }
      
      handler.next(options);
    },
    onResponse: (response, handler) {
      if (kDebugMode) {
        final uri = response.requestOptions.uri.toString();
        final sanitizedUri = uri.contains('login') || uri.contains('signup') || uri.contains('password')
            ? '${response.requestOptions.uri.path} [SENSITIVE]'
            : uri;
        debugPrint('[ServiceLocator] API Response: ${response.statusCode} $sanitizedUri');
      }
      handler.next(response);
    },
    onError: (error, handler) {
      if (kDebugMode) {
        debugPrint('[ServiceLocator] API Error: ${error.response?.statusCode} ${error.requestOptions.uri}');
      }
      if (kDebugMode) {
        debugPrint('[ServiceLocator] Error details: ${error.message}');
      }
      
      if (error.response?.statusCode == 401) {
        if (kDebugMode) {
          debugPrint('[ServiceLocator] Unauthorized - triggering logout');
        }
        if (getIt.isRegistered<AuthService>()) {
          getIt<AuthService>().logout();
        }
      }
      handler.next(error);
    },
  ));

  return dio;
}

Future<void> setupServiceLocator() async {
  final storageService = await StorageService.init();
  getIt.registerSingleton<StorageService>(storageService);

  getIt.registerLazySingleton<Dio>(() => _createConfiguredDio());

  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt<Dio>()));

  getIt.registerLazySingleton<AuthService>(() => 
      AuthService(getIt<ApiService>(), getIt<StorageService>()));

  getIt.registerLazySingleton<MusicService>(() => 
      MusicService(getIt<ApiService>()));

  getIt.registerLazySingleton<FriendService>(() => 
      FriendService(getIt<ApiService>()));

  getIt.registerLazySingleton<VotingService>(() => 
      VotingService(getIt<ApiService>()));

  getIt.registerLazySingleton<DynamicThemeProvider>(() => 
      DynamicThemeProvider());

  getIt.registerLazySingleton<MusicProvider>(() => 
      MusicProvider());

  getIt.registerLazySingleton<VotingProvider>(() => 
      VotingProvider());
  
  getIt.registerLazySingleton<FriendProvider>(() => 
      FriendProvider());

  getIt.registerLazySingleton<ConnectivityProvider>(() => 
      ConnectivityProvider());

  getIt.registerLazySingleton<MusicPlayerService>(() => 
      MusicPlayerService(themeProvider: getIt<DynamicThemeProvider>()));

  getIt.registerLazySingleton<TrackCacheService>(() => 
      TrackCacheService());

  getIt.registerLazySingleton<WebSocketService>(() => 
      WebSocketService());

  getIt.registerLazySingleton<FrontendLoggingService>(() => 
      FrontendLoggingService());

  getIt.registerSingleton<NotificationService>(NotificationService());

  getIt.registerLazySingleton<BeaconService>(() => BeaconService());

  getIt.registerLazySingleton<ActivityService>(() => ActivityService());

  await getIt<FrontendLoggingService>().initialize();

  if (kDebugMode) {
    debugPrint('[ServiceLocator] Service Locator setup complete with consistent API logging');
  }
}
