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
import '../providers/dynamic_theme_provider.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  print('Service Locator: Starting setup...');
  
  final storageService = await StorageService.init();
  getIt.registerSingleton<StorageService>(storageService);
  print('Service Locator: StorageService registered');

  getIt.registerLazySingleton<Dio>(() {
    print('Service Locator: Creating Dio instance...');
    final dio = Dio();
    
    String baseUrl;
    final envBaseUrl = dotenv.env['API_BASE_URL'];
    if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
      baseUrl = envBaseUrl;
      print('Service Locator: Using base URL from environment: $baseUrl');
    } else {
      if (kIsWeb) {
        baseUrl = 'http://localhost:8000';
        print('Service Locator: Web platform detected, using default: $baseUrl');
      } else {
        baseUrl = 'http://10.0.2.2:8000'; 
        print('Service Locator: Mobile platform detected, using default: $baseUrl');
      }
    }
    
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    print('Service Locator: Final base URL: $baseUrl');
    dio.options.baseUrl = baseUrl;
    print('Service Locator: Dio base URL after setting: "${dio.options.baseUrl}"');
    
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
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
        final fullUrl = options.uri.toString();
        print('API Request: ${options.method} $fullUrl');
        print('Base URL: "${dio.options.baseUrl}"');
        print('Request Path: "${options.path}"');
        
        if (!fullUrl.startsWith('http')) {
          print('ERROR: Request URL does not start with http!');
          print('   This indicates a base URL configuration issue.');
          print('   Base URL: "${dio.options.baseUrl}"');
          print('   Request path: "${options.path}"');
        }
        
        final token = getIt.isRegistered<AuthService>() ? getIt<AuthService>().currentToken : null;
        if (token != null) options.headers['Authorization'] = 'Token $token';
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('API Response: ${response.statusCode} for ${response.requestOptions.uri}');
        if (response.data is String && response.data.toString().contains('<!DOCTYPE html>')) {
          print('WARNING: Received HTML instead of JSON!');
          print('   This usually means the request is not reaching the Django backend.');
          print('   Request was sent to: ${response.requestOptions.uri}');
          print('   Check if your backend server is running on the correct port.');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        print('API Error: ${error.response?.statusCode} ${error.message}');
        print('   Request URL: ${error.requestOptions.uri}');
        if (error.response?.statusCode == 401) {
          print('Unauthorized - clearing auth token');
          if (getIt.isRegistered<AuthService>()) getIt<AuthService>().logout();
        }
        handler.next(error);
      },
    ));
    
    print('Service Locator: Dio configured successfully');
    return dio;
  });

  getIt.registerLazySingleton<ApiService>(() {
    print('Service Locator: Creating ApiService with configured Dio...');
    final dio = getIt<Dio>();
    print('Service Locator: Retrieved Dio with base URL: "${dio.options.baseUrl}"');
    return ApiService(dio);
  });

  getIt.registerLazySingleton<AuthService>(() => AuthService(getIt<ApiService>(), getIt<StorageService>()));
  getIt.registerLazySingleton<MusicService>(() => MusicService(getIt<ApiService>()));
  getIt.registerLazySingleton<FriendService>(() => FriendService(getIt<ApiService>()));
  getIt.registerLazySingleton<VotingService>(() => VotingService(getIt<ApiService>()));
  getIt.registerLazySingleton<DynamicThemeProvider>(() => DynamicThemeProvider());
  getIt.registerLazySingleton<MusicPlayerService>(() => MusicPlayerService(themeProvider: getIt<DynamicThemeProvider>()));

  print('Service Locator: All services registered');
  
  final testDio = getIt<Dio>();
  print('Final verification - Dio base URL: "${testDio.options.baseUrl}"');
  if (testDio.options.baseUrl.isEmpty) {
    print('CRITICAL ERROR: Base URL is empty after setup!');
    throw Exception('Failed to configure API base URL');
  }
  
  print('Service Locator setup completed successfully');
}

void resetServiceLocator() {
  getIt.reset();
}
