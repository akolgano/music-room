// lib/core/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    dio.options.baseUrl = baseUrl;
    
    dio.options.headers = {'Content-Type': 'application/json'};
    
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
    ));
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = getIt.isRegistered<AuthService>() 
          ? getIt<AuthService>().currentToken 
          : null;
        if (token != null) options.headers['Authorization'] = 'Token $token';
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          if (getIt.isRegistered<AuthService>()) getIt<AuthService>().logout();
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
}

void resetServiceLocator() {
  getIt.reset();
}
