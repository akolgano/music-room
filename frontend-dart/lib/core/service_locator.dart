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
import '../services/device_service.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../services/music_player_service.dart';
import '../providers/dynamic_theme_provider.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final storageService = await StorageService.init();
  getIt.registerSingleton<StorageService>(storageService);

  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio();
    
    String baseUrl;
    if (kIsWeb) {
      baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      
      if (baseUrl == 'http://localhost:8000') {
        final currentHost = Uri.base.host;
        if (currentHost != 'localhost' && currentHost != '127.0.0.1') {
          baseUrl = 'http://$currentHost:8000';
        }
      }
    } else {
      baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000'; 
    }
    
    print('Service Locator: Setting API base URL to: $baseUrl');
    dio.options.baseUrl = baseUrl;
    
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
        print('API Request: ${options.method} ${options.uri}');
        
        final token = getIt.isRegistered<AuthService>() ? getIt<AuthService>().currentToken : null;
        if (token != null) {
          options.headers['Authorization'] = 'Token $token';
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('API Response: ${response.statusCode} for ${response.requestOptions.uri}');
        
        if (response.data is String && response.data.toString().contains('<!DOCTYPE html>')) {
          print('WARNING: Received HTML instead of JSON from ${response.requestOptions.uri}');
          print('This usually means the request is not reaching the Django backend.');
        }
        
        handler.next(response);
      },
      onError: (error, handler) {
        print('API Error: ${error.response?.statusCode} ${error.message}');
        print('Request URL: ${error.requestOptions.uri}');
        
        if (error.response?.statusCode == 401) {
          print('Unauthorized - clearing auth token');
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

  getIt.registerLazySingleton<AuthService>(() => AuthService(getIt<ApiService>(), getIt<StorageService>()));
  getIt.registerLazySingleton<MusicService>(() => MusicService(getIt<ApiService>()));
  getIt.registerLazySingleton<FriendService>(() => FriendService(getIt<ApiService>()));
  getIt.registerLazySingleton<DeviceService>(() => DeviceService(getIt<ApiService>()));
  getIt.registerLazySingleton<ProfileService>(() => ProfileService(getIt<ApiService>()));

  getIt.registerLazySingleton<DynamicThemeProvider>(() => DynamicThemeProvider());
  getIt.registerLazySingleton<MusicPlayerService>(() => MusicPlayerService(
    themeProvider: getIt<DynamicThemeProvider>(),
  ));
  
  print('Service Locator setup completed');
}

void resetServiceLocator() {
  getIt.reset();
}
