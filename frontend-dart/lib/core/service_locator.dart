import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/music_service.dart';
import '../services/friend_service.dart';
import '../services/storage_service.dart';
import '../services/music_player_service.dart';
import '../services/voting_service.dart';
import '../services/track_cache_service.dart';
import '../services/websocket_service.dart';
import '../services/frontend_logging_service.dart';
import '../services/notification_service.dart';
import '../providers/dynamic_theme_provider.dart';
import '../providers/music_provider.dart';
import '../providers/voting_provider.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final storageService = await StorageService.init();
  getIt.registerSingleton<StorageService>(storageService);

  getIt.registerLazySingleton<Dio>(() {
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
        final token = getIt.isRegistered<AuthService>() 
            ? getIt<AuthService>().currentToken 
            : null;
        if (token != null) {
          options.headers['Authorization'] = 'Token $token';
        }
        
        if (kDebugMode) {
          debugPrint('[ServiceLocator] API Request: ${options.method} ${options.uri}');
        }
        if (options.data != null && kDebugMode) {
          debugPrint('[ServiceLocator] Request Data: ${options.data}');
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('[ServiceLocator] API Response: ${response.statusCode} ${response.requestOptions.uri}');
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

  getIt.registerLazySingleton<DynamicThemeProvider>(() => 
      DynamicThemeProvider());

  getIt.registerLazySingleton<MusicProvider>(() => 
      MusicProvider());

  getIt.registerLazySingleton<VotingProvider>(() => 
      VotingProvider());

  getIt.registerLazySingleton<MusicPlayerService>(() => 
      MusicPlayerService(themeProvider: getIt<DynamicThemeProvider>()));

  getIt.registerLazySingleton<TrackCacheService>(() => 
      TrackCacheService());

  getIt.registerLazySingleton<WebSocketService>(() => 
      WebSocketService());

  getIt.registerLazySingleton<FrontendLoggingService>(() => 
      FrontendLoggingService());

  getIt.registerSingleton<NotificationService>(NotificationService());

  await getIt<FrontendLoggingService>().initialize();

  if (kDebugMode) {
    debugPrint('[ServiceLocator] Service Locator setup complete with consistent API logging');
  }
}
