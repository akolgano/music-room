// lib/core/service_locator.dart
import 'dart:developer' as developer;
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/music_service.dart';
import '../services/friend_service.dart';
import '../services/storage_service.dart';
import '../services/music_player_service.dart';
import '../services/voting_service.dart';
import '../providers/dynamic_theme_provider.dart';

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
          developer.log('API Request: ${options.method} ${options.uri}', name: 'ServiceLocator');
        }
        if (options.data != null && kDebugMode) {
          developer.log('Request Data: ${options.data}', name: 'ServiceLocator');
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          developer.log('API Response: ${response.statusCode} ${response.requestOptions.uri}', name: 'ServiceLocator');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          developer.log('API Error: ${error.response?.statusCode} ${error.requestOptions.uri}', name: 'ServiceLocator');
        }
        if (kDebugMode) {
          developer.log('Error details: ${error.message}', name: 'ServiceLocator');
        }
        
        if (error.response?.statusCode == 401) {
          if (kDebugMode) {
            developer.log('Unauthorized - triggering logout', name: 'ServiceLocator');
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

  getIt.registerLazySingleton<MusicPlayerService>(() => 
      MusicPlayerService(themeProvider: getIt<DynamicThemeProvider>()));

  if (kDebugMode) {
    developer.log('Service Locator setup complete with consistent API logging', name: 'ServiceLocator');
  }
}
